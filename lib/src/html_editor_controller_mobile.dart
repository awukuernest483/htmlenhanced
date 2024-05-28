import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/html_editor_controller_unsupported.dart'
    as unsupported;

/// Controller for mobile
class HtmlEditorController extends unsupported.HtmlEditorController {
  HtmlEditorController({
    this.processInputHtml = true,
    this.processNewLineAsBr = false,
    this.processOutputHtml = true,
  });

  /// Determines whether text processing should happen on input HTML, e.g.
  /// whether a new line should be converted to a <br>.
  ///
  /// The default value is false.
  final bool processInputHtml;

  /// Determines whether newlines (\n) should be written as <br>. This is not
  /// recommended for HTML documents.
  ///
  /// The default value is false.
  final bool processNewLineAsBr;

  /// Determines whether text processing should happen on output HTML, e.g.
  /// whether <p><br></p> is returned as "". For reference, Summernote uses
  /// that HTML as the default HTML (when no text is in the editor).
  ///
  /// The default value is true.
  final bool processOutputHtml;

  /// Allows the [InAppWebViewController] for the Html editor to be accessed
  /// outside of the package itself for endless control and customization.
  InAppWebViewController? get editorController => controllerMap[this];

  /// Gets the text from the editor and returns it as a [String].
  Future<String> getText() async {
    String? text = await _evaluateJavascript(
        source: "\$('#summernote-2').summernote('code');") as String?;
    if (processOutputHtml &&
        (text == null ||
            text.isEmpty ||
            text == "<p></p>" ||
            text == "<p><br></p>" ||
            text == "<p><br/></p>")) text = "";
    return text ?? "";
  }

  /// Sets the text of the editor. Some pre-processing is applied to convert
  /// [String] elements like "\n" to HTML elements.
  void setText(String text) {
    text = _processHtml(html: text);
    _evaluateJavascript(
        source: "\$('#summernote-2').summernote('code', '$text');");
  }

  /// Sets the editor to full-screen mode.
  void setFullScreen() {
    _evaluateJavascript(
        source: '\$("#summernote-2").summernote("fullscreen.toggle");');
  }

  /// Sets the focus to the editor.
  void setFocus() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('focus');");
  }

  /// Clears the editor of any text.
  void clear() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('reset');");
  }

  /// Sets the hint for the editor.
  void setHint(String text) {
    text = _processHtml(html: text);
    String hint = '\$(".note-placeholder").html("$text");';
    _evaluateJavascript(source: hint);
  }

  /// toggles the codeview in the Html editor
  void toggleCodeView() {
    _evaluateJavascript(
        source: "\$('#summernote-2').summernote('codeview.toggle');");
  }

  /// disables the Html editor
  void disable() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('disable');");
  }

  /// enables the Html editor
  void enable() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('enable');");
  }

  /// Undoes the last action
  void undo() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('undo');");
  }

  /// Redoes the last action
  void redo() {
    _evaluateJavascript(source: "\$('#summernote-2').summernote('redo');");
  }

  /// Insert text at the end of the current HTML content in the editor
  /// Note: This method should only be used for plaintext strings
  void insertText(String text) {
    _evaluateJavascript(
        source: "\$('#summernote-2').summernote('insertText', '$text');");
  }

  /// Insert HTML at the position of the cursor in the editor
  /// Note: This method should not be used for plaintext strings
  void insertHtml(String html) {
    html = _processHtml(html: html);
    _evaluateJavascript(
        source: "\$('#summernote-2').summernote('pasteHTML', '$html');");
  }

  /// Insert a network image at the position of the cursor in the editor
  void insertNetworkImage(String url, {String filename = ""}) {
    _evaluateJavascript(
        source:
            "\$('#summernote-2').summernote('insertImage', '$url', '$filename');");
  }

  /// Insert a link at the position of the cursor in the editor
  void insertLink(String text, String url, bool isNewWindow) {
    _evaluateJavascript(source: """
    \$('#summernote-2').summernote('createLink', {
        text: "$text",
        url: '$url',
        isNewWindow: $isNewWindow
      });
    """);
  }

  /// Clears the focus from the webview by hiding the keyboard, calling the
  /// clearFocus method on the [InAppWebViewController], and resetting the height
  /// in case it was changed.
  void clearFocus() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// Reloads the IFrameElement, throws an exception on mobile
  void reloadWeb() {
    throw Exception(
        "Non-Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart and check kIsWeb before calling this function");
  }

  /// Resets the height of the editor back to the original if it was changed to
  /// accommodate the keyboard. This should only be used on mobile, and only
  /// when [adjustHeightForKeyboard] is enabled.
  void resetHeight() {
    _evaluateJavascript(
        source:
            "window.flutter_inappwebview.callHandler('setHeight', 'reset');");
  }

  /// Recalculates the height of the editor to remove any vertical scrolling.
  /// This method will not do anything if [autoAdjustHeight] is turned off.
  void recalculateHeight() {
    _evaluateJavascript(
        source:
            "var height = document.body.scrollHeight; window.flutter_inappwebview.callHandler('setHeight', height);");
  }

  /// Add a notification to the bottom of the editor. This is styled similar to
  /// Bootstrap alerts. You can set the HTML to be displayed in the alert,
  /// and the notificationType determines how the alert is displayed.
  void addNotification(String html, NotificationType notificationType) async {
    await _evaluateJavascript(source: """
        \$('.note-status-output').html(
          '<div class="alert alert-${describeEnum(notificationType)}">$html</div>'
        );
        """);
    recalculateHeight();
  }

  /// Remove the current notification from the bottom of the editor
  void removeNotification() async {
    await _evaluateJavascript(source: "\$('.note-status-output').empty();");
    recalculateHeight();
  }

  String _processHtml({required html}) {
    if (processInputHtml) {
      html = html
          .replaceAll("'", r"\'")
          .replaceAll('"', r'\"')
          .replaceAll("\r", "")
          .replaceAll('\r\n', "");
    }
    if (processNewLineAsBr) {
      html = html.replaceAll("\n", "<br/>").replaceAll("\n\n", "<br/>");
    } else {
      html = html.replaceAll("\n", "").replaceAll("\n\n", "");
    }
    return html;
  }

  /// Helper function to evaluate JS and check the current environment
  dynamic _evaluateJavascript({required source}) async {
    if (!kIsWeb) {
      if (controllerMap[this] == null || await editorController!.isLoading())
        throw Exception(
            "HTML editor is still loading, please wait before evaluating this JS: $source!");
      var result = await editorController!.evaluateJavascript(source: source);
      return result;
    } else {
      throw Exception(
          "Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart");
    }
  }
}
