import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/utils/plugins.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// The HTML Editor widget itself, for mobile (uses InAppWebView)
class HtmlEditorWidget extends StatefulWidget {
  HtmlEditorWidget({
    Key? key,
    required this.controller,
    this.value,
    this.hint,
    this.callbacks,
    required this.toolbar,
    required this.plugins,
    required this.options,
  }) : super(key: key);

  final HtmlEditorController controller;
  final String? value;
  final String? hint;
  final Callbacks? callbacks;
  final List<Toolbar> toolbar;
  final List<Plugins> plugins;
  final HtmlEditorOptions options;

  _HtmlEditorWidgetMobileState createState() => _HtmlEditorWidgetMobileState();
}

/// State for the mobile Html editor widget
///
/// A stateful widget is necessary here to allow the height to dynamically adjust.
class _HtmlEditorWidgetMobileState extends State<HtmlEditorWidget> {
  /// Tracks whether the callbacks were initialized or not to prevent re-initializing them
  bool callbacksInitialized = false;

  /// The actual height of the editor, used to automatically set the height
  late double actualHeight;

  /// A variable used to correct for the height of the bottom toolbar, if visible.
  double toolbarHeightCorrection = 0;

  /// The height of the document loaded in the editor
  double? docHeight;

  /// The file path to the html code
  late String filePath;

  /// String to use when creating the key for the widget
  late String key;

  /// Stream to transfer the [VisibilityInfo.visibleFraction] to the [onWindowFocus]
  /// function of the webview
  StreamController<double> visibleStream = StreamController<double>.broadcast();

  @override
  void initState() {
    if (widget.options.showBottomToolbar) toolbarHeightCorrection = 40;
    actualHeight = widget.options.height + 85 + toolbarHeightCorrection;
    key = getRandString(10);
    if (widget.options.filePath != null) {
      filePath = widget.options.filePath!;
    } else if (widget.plugins.isEmpty) {
      filePath =
          'packages/html_editor_enhanced/assets/summernote-no-plugins.html';
    } else {
      filePath = 'packages/html_editor_enhanced/assets/summernote.html';
    }
    super.initState();
  }

  @override
  void dispose() {
    visibleStream.close();
    super.dispose();
  }

  /// resets the height of the editor to the original height
  void resetHeight() async {
    setState(() {
      if (docHeight != null) {
        actualHeight = docHeight! + toolbarHeightCorrection;
      } else {
        actualHeight = widget.options.height + 85 + toolbarHeightCorrection;
      }
    });
    await controllerMap[widget.controller].evaluateJavascript(
        source: "\$('div.note-editable').height(${widget.options.height});");
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(key),
      onVisibilityChanged: (VisibilityInfo info) async {
        if (!visibleStream.isClosed) visibleStream.add(info.visibleFraction);
      },
      child: GestureDetector(
        onTap: () {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        child: Container(
          height: actualHeight,
          decoration: widget.options.decoration,
          child: Column(
            children: <Widget>[
              Expanded(
                child: InAppWebView(
                  initialFile: filePath,
                  onWebViewCreated: (webViewController) {
                    controllerMap[widget.controller] = webViewController;
                  },
                  initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        javaScriptEnabled: true,
                        transparentBackground: true,
                      ),
                      android: AndroidInAppWebViewOptions(
                        useHybridComposition: true,
                        loadWithOverviewMode: true,
                      )),
                  gestureRecognizers: {
                    Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer())
                  },
                  onConsoleMessage: (controller, message) {
                    print(message.message);
                  },
                  onWindowFocus: (controller) async {
                    if (widget.options.shouldEnsureVisible &&
                        Scrollable.of(context) != null) {
                      Scrollable.of(context)!.position.ensureVisible(
                            context.findRenderObject()!,
                          );
                    }
                    if (widget.options.adjustHeightForKeyboard) {
                      visibleStream.stream.drain();
                      double visibleDecimal = await visibleStream.stream.first;
                      double newHeight = widget.options.height;
                      if (docHeight != null) {
                        newHeight = (docHeight! + toolbarHeightCorrection) *
                            visibleDecimal;
                      } else {
                        newHeight = (widget.options.height +
                                85 +
                                toolbarHeightCorrection) *
                            visibleDecimal;
                      }
                      await controller.evaluateJavascript(
                          source:
                              "\$('div.note-editable').height(${max(widget.options.height - (actualHeight - newHeight) - 10, 30)});");
                      setState(() {
                        if (docHeight != null) {
                          actualHeight = newHeight;
                        } else {
                          actualHeight = newHeight;
                        }
                      });
                    }
                  },
                  onLoadStop:
                      (InAppWebViewController controller, Uri? uri) async {
                    String url = uri.toString();
                    int maximumFileSize = 10485760;
                    if (url.contains(filePath)) {
                      String summernoteToolbar = "[\n";
                      String summernoteCallbacks = "callbacks: {";
                      for (Toolbar t in widget.toolbar) {
                        summernoteToolbar = summernoteToolbar +
                            "['${t.getGroupName()}', ${t.getButtons(listStyles: widget.plugins.whereType<SummernoteListStyles>().isNotEmpty)}],\n";
                      }
                      if (widget.plugins.isNotEmpty) {
                        summernoteToolbar = summernoteToolbar + "['plugins', [";
                        for (Plugins p in widget.plugins) {
                          summernoteToolbar = summernoteToolbar +
                              (p.getToolbarString().isNotEmpty
                                  ? "'${p.getToolbarString()}'"
                                  : "") +
                              (p == widget.plugins.last
                                  ? "]]\n"
                                  : p.getToolbarString().isNotEmpty
                                      ? ", "
                                      : "");
                          if (p is SummernoteAtMention) {
                            summernoteCallbacks = summernoteCallbacks +
                                """
                              \nsummernoteAtMention: {
                                getSuggestions: async function(value) {
                                  var result = await window.flutter_inappwebview.callHandler('getSuggestions', value);
                                  var resultList = result.split(',');
                                  return resultList;
                                },
                                onSelect: (value) => {
                                  window.flutter_inappwebview.callHandler('onSelectMention', value);
                                },
                              },
                            """;
                            controller.addJavaScriptHandler(
                                handlerName: 'getSuggestions',
                                callback: (value) {
                                  return p.getSuggestionsMobile!
                                      .call(value.first.toString())
                                      .toString()
                                      .replaceAll("[", "")
                                      .replaceAll("]", "");
                                });
                            if (p.onSelect != null) {
                              controller.addJavaScriptHandler(
                                  handlerName: 'onSelectMention',
                                  callback: (value) {
                                    p.onSelect!.call(value.first.toString());
                                  });
                            }
                          }
                          if (p is SummernoteFile) {
                            maximumFileSize = p.maximumFileSize;
                            if (p.onFileUpload != null) {
                              summernoteCallbacks = summernoteCallbacks +
                                  """
                                onFileUpload: function(files) {
                                  var reader = new FileReader();
                                  var base64 = "<an error occurred>";
                                  reader.onload = function (_) {
                                    base64 = reader.result;
                                    var newObject = {
                                       'lastModified': files[0].lastModified,
                                       'lastModifiedDate': files[0].lastModifiedDate,
                                       'name': files[0].name,
                                       'size': files[0].size,
                                       'type': files[0].type,
                                       'base64': base64
                                    };
                                    window.flutter_inappwebview.callHandler('onFileUpload', JSON.stringify(newObject));
                                  };
                                  reader.onerror = function (_) {
                                    var newObject = {
                                       'lastModified': files[0].lastModified,
                                       'lastModifiedDate': files[0].lastModifiedDate,
                                       'name': files[0].name,
                                       'size': files[0].size,
                                       'type': files[0].type,
                                       'base64': base64
                                    };
                                    window.flutter_inappwebview.callHandler('onFileUpload', JSON.stringify(newObject));
                                  };
                                  reader.readAsDataURL(files[0]);
                                },
                            """;
                              controller.addJavaScriptHandler(
                                  handlerName: 'onFileUpload',
                                  callback: (files) {
                                    FileUpload file =
                                        fileUploadFromJson(files.first);
                                    p.onFileUpload!.call(file);
                                  });
                            }
                            if (p.onFileLinkInsert != null) {
                              summernoteCallbacks = summernoteCallbacks +
                                  """
                                onFileLinkInsert: function(link) {
                                  window.flutter_inappwebview.callHandler('onFileLinkInsert', link);
                                },
                            """;
                              controller.addJavaScriptHandler(
                                  handlerName: 'onFileLinkInsert',
                                  callback: (link) {
                                    p.onFileLinkInsert!
                                        .call(link[0].toString());
                                  });
                            }
                            if (p.onFileUploadError != null) {
                              summernoteCallbacks = summernoteCallbacks +
                                  """
                                onFileUploadError: function(file, error) {
                                  if (typeof file === 'string') {
                                    window.flutter_inappwebview.callHandler('onFileUploadError', file, error);
                                  } else {
                                    var newObject = {
                                       'lastModified': file.lastModified,
                                       'lastModifiedDate': file.lastModifiedDate,
                                       'name': file.name,
                                       'size': file.size,
                                       'type': file.type,
                                    };
                                    window.flutter_inappwebview.callHandler('onFileUploadError', JSON.stringify(newObject), error);
                                  }
                                },
                            """;
                              controller.addJavaScriptHandler(
                                  handlerName: 'onFileUploadError',
                                  callback: (args) {
                                    if (!args.first
                                        .toString()
                                        .startsWith("{")) {
                                      p.onFileUploadError!.call(
                                          null,
                                          args.first,
                                          args.last.contains("base64")
                                              ? UploadError.jsException
                                              : args.last
                                                      .contains("unsupported")
                                                  ? UploadError.unsupportedFile
                                                  : UploadError
                                                      .exceededMaxSize);
                                    } else {
                                      FileUpload file = fileUploadFromJson(
                                          args.first.toString());
                                      p.onFileUploadError!.call(
                                          file,
                                          null,
                                          args.last.contains("base64")
                                              ? UploadError.jsException
                                              : args.last
                                                      .contains("unsupported")
                                                  ? UploadError.unsupportedFile
                                                  : UploadError
                                                      .exceededMaxSize);
                                    }
                                  });
                            }
                          }
                        }
                      }
                      if (widget.callbacks != null) {
                        if (widget.callbacks!.onImageLinkInsert != null) {
                          summernoteCallbacks = summernoteCallbacks +
                              """
                              onImageLinkInsert: function(url) {
                                window.flutter_inappwebview.callHandler('onImageLinkInsert', url);
                              },
                            """;
                        }
                        if (widget.callbacks!.onImageUpload != null) {
                          summernoteCallbacks = summernoteCallbacks +
                              """
                              onImageUpload: function(files) {
                                var reader = new FileReader();
                                var base64 = "<an error occurred>";
                                reader.onload = function (_) {
                                  base64 = reader.result;
                                  var newObject = {
                                     'lastModified': files[0].lastModified,
                                     'lastModifiedDate': files[0].lastModifiedDate,
                                     'name': files[0].name,
                                     'size': files[0].size,
                                     'type': files[0].type,
                                     'base64': base64
                                  };
                                  window.flutter_inappwebview.callHandler('onImageUpload', JSON.stringify(newObject));
                                };
                                reader.onerror = function (_) {
                                  var newObject = {
                                     'lastModified': files[0].lastModified,
                                     'lastModifiedDate': files[0].lastModifiedDate,
                                     'name': files[0].name,
                                     'size': files[0].size,
                                     'type': files[0].type,
                                     'base64': base64
                                  };
                                  window.flutter_inappwebview.callHandler('onImageUpload', JSON.stringify(newObject));
                                };
                                reader.readAsDataURL(files[0]);
                              },
                            """;
                        }
                        if (widget.callbacks!.onImageUploadError != null) {
                          summernoteCallbacks = summernoteCallbacks +
                              """
                                onImageUploadError: function(file, error) {
                                  if (typeof file === 'string') {
                                    window.flutter_inappwebview.callHandler('onImageUploadError', file, error);
                                  } else {
                                    var newObject = {
                                       'lastModified': file.lastModified,
                                       'lastModifiedDate': file.lastModifiedDate,
                                       'name': file.name,
                                       'size': file.size,
                                       'type': file.type,
                                    };
                                    window.flutter_inappwebview.callHandler('onImageUploadError', JSON.stringify(newObject), error);
                                  }
                                },
                            """;
                        }
                      }
                      summernoteToolbar = summernoteToolbar + "],";
                      summernoteCallbacks = summernoteCallbacks + "}";
                      controller.evaluateJavascript(source: """
                          \$('#summernote-2').summernote({
                              placeholder: "${widget.hint}",
                              tabsize: 2,
                              height: ${widget.options.height},
                              toolbar: $summernoteToolbar
                              disableGrammar: false,
                              spellCheck: false,
                              maximumFileSize: $maximumFileSize,
                              $summernoteCallbacks
                          });
                          
                          \$('#summernote-2').on('summernote.change', function(_, contents, \$editable) {
                            window.flutter_inappwebview.callHandler('onChange', contents);
                          });
                      """);
                      if ((Theme.of(context).brightness == Brightness.dark ||
                              widget.options.darkMode == true) &&
                          widget.options.darkMode != false) {
                        String darkCSS =
                            "<link href=\"summernote-lite-dark.css\" rel=\"stylesheet\">";
                        await controller.evaluateJavascript(
                            source: "\$('head').append('$darkCSS');");
                      }
                      //set the text once the editor is loaded
                      if (widget.value != null)
                        widget.controller.setText(widget.value!);
                      //adjusts the height of the editor when it is loaded
                      if (widget.options.autoAdjustHeight) {
                        controller.addJavaScriptHandler(
                            handlerName: 'setHeight',
                            callback: (height) {
                              if (height.first == "reset") {
                                resetHeight();
                              } else {
                                docHeight =
                                    double.tryParse(height.first.toString());
                                if (docHeight != null &&
                                    docHeight! > 0 &&
                                    mounted) {
                                  setState(() {
                                    actualHeight =
                                        docHeight! + toolbarHeightCorrection;
                                  });
                                } else {
                                  docHeight =
                                      actualHeight - toolbarHeightCorrection;
                                }
                              }
                            });
                        controller.evaluateJavascript(
                            source:
                                "var height = document.body.scrollHeight; window.flutter_inappwebview.callHandler('setHeight', height);");
                      } else {
                        docHeight = actualHeight - toolbarHeightCorrection;
                      }
                      //reset the editor's height if the keyboard disappears at any point
                      if (widget.options.adjustHeightForKeyboard) {
                        KeyboardVisibilityController
                            keyboardVisibilityController =
                            KeyboardVisibilityController();
                        keyboardVisibilityController.onChange
                            .listen((bool visible) {
                          if (!visible &&
                              docHeight != null &&
                              actualHeight !=
                                  docHeight! + toolbarHeightCorrection) {
                            controller.clearFocus();
                            resetHeight();
                          } else if (!visible &&
                              docHeight == null &&
                              actualHeight !=
                                  widget.options.height +
                                      85 +
                                      toolbarHeightCorrection) {
                            controller.clearFocus();
                            resetHeight();
                          }
                        });
                      }
                      //initialize callbacks
                      if (widget.callbacks != null && !callbacksInitialized) {
                        addJSCallbacks(widget.callbacks!);
                        addJSHandlers(widget.callbacks!);
                        callbacksInitialized = true;
                      }
                      //call onInit callback
                      if (widget.callbacks != null &&
                          widget.callbacks!.onInit != null)
                        widget.callbacks!.onInit!.call();
                      //add onChange handler
                      controller.addJavaScriptHandler(
                          handlerName: 'onChange',
                          callback: (contents) {
                            if (widget.options.shouldEnsureVisible &&
                                Scrollable.of(context) != null) {
                              Scrollable.of(context)!.position.ensureVisible(
                                    context.findRenderObject()!,
                                  );
                            }
                            if (widget.callbacks != null &&
                                widget.callbacks!.onChange != null) {
                              widget.callbacks!.onChange!
                                  .call(contents.first.toString());
                            }
                          });
                    }
                  },
                ),
              ),
              widget.options.showBottomToolbar
                  ? Divider(height: 0)
                  : Container(height: 0, width: 0),
              widget.options.showBottomToolbar
                  ? ToolbarWidget(controller: widget.controller)
                  : Container(height: 0, width: 0),
            ],
          ),
        ),
      ),
    );
  }

  /// adds the callbacks set by the user into the scripts
  void addJSCallbacks(Callbacks c) {
    if (c.onBeforeCommand != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.before.command', function(_, contents) {
            window.flutter_inappwebview.callHandler('onBeforeCommand', contents);
          });
        """);
    }
    if (c.onChangeCodeview != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.change.codeview', function(_, contents, \$editable) {
            window.flutter_inappwebview.callHandler('onChangeCodeview', contents);
          });
        """);
    }
    if (c.onDialogShown != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.dialog.shown', function() {
            window.flutter_inappwebview.callHandler('onDialogShown', 'fired');
          });
        """);
    }
    if (c.onEnter != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.enter', function() {
            window.flutter_inappwebview.callHandler('onEnter', 'fired');
          });
        """);
    }
    if (c.onFocus != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.focus', function() {
            window.flutter_inappwebview.callHandler('onFocus', 'fired');
          });
        """);
    }
    if (c.onBlur != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur', function() {
            window.flutter_inappwebview.callHandler('onBlur', 'fired');
          });
        """);
    }
    if (c.onBlurCodeview != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur.codeview', function() {
            window.flutter_inappwebview.callHandler('onBlurCodeview', 'fired');
          });
        """);
    }
    if (c.onKeyDown != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keydown', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyDown', e.keyCode);
          });
        """);
    }
    if (c.onKeyUp != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keyup', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyUp', e.keyCode);
          });
        """);
    }
    if (c.onMouseDown != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mousedown', function(_) {
            window.flutter_inappwebview.callHandler('onMouseDown', 'fired');
          });
        """);
    }
    if (c.onMouseUp != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mouseup', function(_) {
            window.flutter_inappwebview.callHandler('onMouseUp', 'fired');
          });
        """);
    }
    if (c.onPaste != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.paste', function(_) {
            window.flutter_inappwebview.callHandler('onPaste', 'fired');
          });
        """);
    }
    if (c.onScroll != null) {
      controllerMap[widget.controller].evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.scroll', function(_) {
            window.flutter_inappwebview.callHandler('onScroll', 'fired');
          });
        """);
    }
  }

  /// creates flutter_inappwebview JavaScript Handlers to handle any callbacks the
  /// user has defined
  void addJSHandlers(Callbacks c) {
    if (c.onBeforeCommand != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onBeforeCommand',
          callback: (contents) {
            c.onBeforeCommand!.call(contents.first.toString());
          });
    }
    if (c.onChangeCodeview != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onChangeCodeview',
          callback: (contents) {
            c.onChangeCodeview!.call(contents.first.toString());
          });
    }
    if (c.onDialogShown != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onDialogShown',
          callback: (_) {
            c.onDialogShown!.call();
          });
    }
    if (c.onEnter != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onEnter',
          callback: (_) {
            c.onEnter!.call();
          });
    }
    if (c.onFocus != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onFocus',
          callback: (_) {
            c.onFocus!.call();
          });
    }
    if (c.onBlur != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onBlur',
          callback: (_) {
            c.onBlur!.call();
          });
    }
    if (c.onBlurCodeview != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onBlurCodeview',
          callback: (_) {
            c.onBlurCodeview!.call();
          });
    }
    if (c.onImageLinkInsert != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onImageLinkInsert',
          callback: (url) {
            c.onImageLinkInsert!.call(url.first.toString());
          });
    }
    if (c.onImageUpload != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onImageUpload',
          callback: (files) {
            FileUpload file = fileUploadFromJson(files.first);
            c.onImageUpload!.call(file);
          });
    }
    if (c.onImageUploadError != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onImageUploadError',
          callback: (args) {
            if (!args.first.toString().startsWith("{")) {
              c.onImageUploadError!.call(
                  null,
                  args.first,
                  args.last.contains("base64")
                      ? UploadError.jsException
                      : args.last.contains("unsupported")
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            } else {
              FileUpload file = fileUploadFromJson(args.first.toString());
              c.onImageUploadError!.call(
                  file,
                  null,
                  args.last.contains("base64")
                      ? UploadError.jsException
                      : args.last.contains("unsupported")
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            }
          });
    }
    if (c.onKeyDown != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onKeyDown',
          callback: (keyCode) {
            c.onKeyDown!.call(keyCode.first);
          });
    }
    if (c.onKeyUp != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onKeyUp',
          callback: (keyCode) {
            c.onKeyUp!.call(keyCode.first);
          });
    }
    if (c.onMouseDown != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onMouseDown',
          callback: (_) {
            c.onMouseDown!.call();
          });
    }
    if (c.onMouseUp != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onMouseUp',
          callback: (_) {
            c.onMouseUp!.call();
          });
    }
    if (c.onPaste != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onPaste',
          callback: (_) {
            c.onPaste!.call();
          });
    }
    if (c.onScroll != null) {
      controllerMap[widget.controller].addJavaScriptHandler(
          handlerName: 'onScroll',
          callback: (_) {
            c.onScroll!.call();
          });
    }
  }

  /// Generates a random string to be used as the [VisibilityDetector] key.
  /// Technically this limits the number of editors to a finite number, but
  /// nobody will be embedding enough editors to reach the theoretical limit
  /// (yes, this is a challenge ;-) )
  String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }
}
