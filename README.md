# Flutter Html Editor - Enhanced
[![pub package](https://img.shields.io/pub/v/html_editor_enhanced.svg)](https://pub.dev/packages/html_editor_enhanced)

Flutter HTML Editor Enhanced is a text editor for Android, iOS, and Web to help write WYSIWYG HTML code with the Summernote JavaScript wrapper.

Note that the API shown in this README.md file shows only a part of the documentation and, also, conforms to the GitHub master branch only! So, here you could have methods, options, and events that aren't published/released yet! If you need a specific version, please change the GitHub branch of this repository to your version or use the online [API Reference](https://pub.dev/documentation/html_editor_enhanced/latest/) (recommended).

<table>
  <tr>
    <td align="center">Video Example</td>
    <td align="center">Light Mode</td>
    <td align="center">Dark Mode</td>
  </tr>
  <tr>
    <td><img alt="GIF example" src="https://raw.githubusercontent.com/tneotia/html-editor-enhanced/master/screenshots/html_editor_enhanced.gif" width="250"/></td>
    <td><img alt="Light" src="https://raw.githubusercontent.com/tneotia/html-editor-enhanced/master/screenshots/html_editor_light.png" width="250"/></td>
    <td><img alt="Dark" src="https://raw.githubusercontent.com/tneotia/html-editor-enhanced/master/screenshots/html_editor_dark.png" width="250"/></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center">Flutter Web</td>
  </tr>
  <tr>
    <td><img alt="Flutter Web" src="https://raw.githubusercontent.com/tneotia/html-editor-enhanced/master/screenshots/html_editor_web.png" width="800"/></td>
  </tr>
</table>

## Table of Contents:

- ["Enhanced"? In what ways?](#in-what-ways-is-this-package-enhanced)

- [Setup](#setup)

- [Usage](#basic-usage)

- [API Reference](#api-reference)

  - [Parameters Table](#parameters---htmleditor)

  - [Methods Table](#methods)

  - [Callbacks Table](#callbacks)
  
  - [Getters](#getters)
  
  - [Toolbar](#toolbar)
  
  - [Plugins](#plugins)
  
  - [`onImageUpload` and `onImageLinkInsert`](#onimageupload-and-onimagelinkinsert)
    
  - [`autoAdjustHeight`](#autoadjustheight)
  
  - [`adjustHeightForKeyboard`](#adjustheightforkeyboard)
  
  - [`filePath`](#filepath)
  
  - [`shouldEnsureVisible`](#shouldensurevisible)
  
  - [`processInputHtml`, `processOutputHtml`, and `processNewLineAsBr`](#processinputhtml-processoutputhtml-and-processnewlineasbr)
  
  - [Summernote File Plugin](#summernote-file-plugin)

- [Examples](#examples)

- [Notes](#notes)

- [License](#license)

- [Contribution Guide](#contribution-guide)
 
## In what ways is this package "enhanced"?

1. It has official support for Flutter Web, with nearly all mobile features supported. Keyboard shortcuts like Ctrl+B for bold work as well!

2. It uses a heavily optimized [WebView](https://github.com/pichillilorenzo/flutter_inappwebview) to deliver the best possible experience when using the editor

3. It doesn't use a local server to load the HTML code containing the editor. Instead, this package simply loads the HTML file, which improves performance and the editor's startup time.

4. It uses a `StatelessWidget`. You don't have to fiddle around with `GlobalKey`s to access methods, instead you can simply call `<controller name>.<method name>` anywhere you want.

5. It has support for many of Summernote's methods

6. It has support for all of Summernote's callbacks

7. It has support for some of Summernote's 3rd party plugins, found [here](https://github.com/summernote/awesome-summernote)

8. It exposes the `InAppWebViewController` so you can customize the WebView however you like - you can even load your own HTML code and inject your own JavaScript for your use cases.

9. It has support for dark mode

10. It has support for low-level customization, such as setting what buttons are shown on the toolbar

More is on the way! File a feature request or contribute to the project if you'd like to see other features added.

## Setup

Add `html_editor_enhanced: ^1.7.1` as dependency to your pubspec.yaml

Additional setup is required to allow the user to pick images via `<input type="file">`:

<details><summary>Instructions</summary>

Add the following to your app's AndroidManifest.xml inside the `<application>` tag:

```xml
<provider
   android:name="com.pichillilorenzo.flutter_inappwebview.InAppWebViewFileProvider"
   android:authorities="${applicationId}.flutter_inappwebview.fileprovider"
   android:exported="false"
   android:grantUriPermissions="true">
   <meta-data
       android:name="android.support.FILE_PROVIDER_PATHS"
       android:resource="@xml/provider_paths" />
</provider>
```

And add the following above the `<application>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

In Dart, you'll need to request these permissions. You can use [`permission_handler`](https://pub.dev/packages/permission_handler) like this:

```dart
//Android
await Permission.storage.request();
//iOS
await Permission.photos.request();
```

If you'd like the user to be able to insert images via the camera, you need to request for those permissions. AndroidManifest:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

Dart:

```dart
await Permission.camera.request();
```

You must request the permissions in Dart before the user accesses the file upload dialog. I recommend requesting the permissions in `initState()` or something similar.

IMPORTANT: When using `permission_handler` on iOS, you must modify the Podfile, otherwise you will not be able to upload a build to App Store Connect. Add the following at the very bottom, right underneath `flutter_additional_ios_build_settings(target)`:

```text
target.build_configurations.each do |config|
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
      '$(inherited)',
      ## use a hashtag symbol on the permissions you want to include in your app. Make sure they are defined in Info.plist as well! 
      ## dart: PermissionGroup.calendar
      'PERMISSION_EVENTS=0',

      ## dart: PermissionGroup.reminders
      'PERMISSION_REMINDERS=0',

      ## dart: PermissionGroup.contacts
      'PERMISSION_CONTACTS=0',

      ## dart: PermissionGroup.camera
      'PERMISSION_CAMERA=0',

      ## dart: PermissionGroup.microphone
      'PERMISSION_MICROPHONE=0',

      ## dart: PermissionGroup.speech
      'PERMISSION_SPEECH_RECOGNIZER=0',

      ## dart: PermissionGroup.photos
      # 'PERMISSION_PHOTOS=0',

      ## dart: [PermissionGroup.location, PermissionGroup.locationAlways, PermissionGroup.locationWhenInUse]
      'PERMISSION_LOCATION=0',

      ## dart: PermissionGroup.notification
      'PERMISSION_NOTIFICATIONS=0',

      ## dart: PermissionGroup.mediaLibrary
      'PERMISSION_MEDIA_LIBRARY=0',

      ## dart: PermissionGroup.sensors
      'PERMISSION_SENSORS=0'
    ]
 end
```

If you decide to allow images directly from the camera, you will need to comment `'PERMISSION_CAMERA=0',` as well.

</details>

## Basic Usage

```dart
import 'package:html_editor/html_editor.dart';

HtmlEditorController controller = HtmlEditorController();

@override Widget build(BuildContext context) {
    return HtmlEditor(
        controller: controller, //required
        hint: "Your text here...",
        //initalText: "text content initial, if any",
        options: HtmlEditorOptions(
          height: 400,
        ),
    );
}
```

When you want to get text from the editor:
```dart
final txt = await controller.getText();
```

## API Reference

For the full API reference, see [here](https://pub.dev/documentation/html_editor_enhanced/latest/).

For a full example, see [here](https://github.com/tneotia/html-editor-enhanced/tree/master/example).

Below, you will find brief descriptions of the parameters the`HtmlEditor` widget accepts and some code snippets to help you use this package.

### Parameters - `HtmlEditor`

Parameter | Type | Default | Description
------------ | ------------- | ------------- | -------------
**controller** | `HtmlEditorController` | empty | Required param. Create a controller instance and pass it to the widget. This ensures that any methods called work only on their `HtmlEditor` instance, allowing you to use multiple HTML widgets on one page.
**callbacks** | `Callbacks` | empty | Customize the callbacks for various events
**hint** | `String` | empty | Placeholder hint text
**initialText** | `String` | empty | Initial text content for text editor
**options** | `HtmlEditorOptions` | `HtmlEditorOptions()` | Class to set various options. See [below](#parameters---htmleditoroptions) for more details.
**plugins** | `List<Plugins>` | empty | Customize what plugins are activated. See [below](#plugins) for more details.
**toolbar** | `List<Toolbar>` | See the widget's constructor | Customize what buttons are shown on the toolbar, and in which order. See [below](#toolbar) for more details.

### Parameters - `HtmlEditorController`

Parameter | Type | Default | Description
------------ | ------------- | ------------- | -------------
**processInputHtml** | `bool` | `true` | Determines whether processing occurs on any input HTML (e.g. escape quotes, apostrophes, and remove `/n`s)
**processNewLineAsBr** | `bool` | `false` | Determines whether a new line (`\n`) becomes a `<br/>` in any *input* HTML
**processOutputHtml** | `bool` | `true` | Determines whether processing occurs on any output HTML (e.g. `<p><br/><p>` becomes `""`)

### Parameters - `HtmlEditorOptions`

Parameter | Type | Default | Description
------------ | ------------- | ------------- | -------------
**autoAdjustHeight** | `bool` | `true` | Automatically adjust the height of the text editor by analyzing the HTML height once the editor is loaded. Recommended value: `true`.  See [below](#autoadjustheight) for more details.
**adjustHeightForKeyboard** | `bool` | `true` | Adjust the height of the editor if the keyboard is active and it overlaps the editor to prevent the overlap. Recommended value: `true`, only works on mobile.  See [below](#adjustheightforkeyboard) for more details.
**darkMode** | `bool` | `null` | Sets the status of dark mode - `false`: always light, `null`: follow system, `true`: always dark
**decoration** | `BoxDecoration` |  | `BoxDecoration` that surrounds the widget
**filePath** | `String` | `null` | Allows you to specify your own HTML to be loaded into the webview. You can create a custom page with Summernote, or theoretically load any other editor/HTML.
**hint** | `String` | empty | Placeholder hint text
**shouldEnsureVisible** | `bool` | `false` | Scroll the parent `Scrollable` to the top of the editor widget when the webview is focused. Do *not* use this parameter if `HtmlEditor` is not inside a `Scrollable`. See [below](#shouldensurevisible) for more details.
**showBottomToolbar** | `bool` | true | Show or hide bottom toolbar

### Methods

Access these methods like this: `<controller name>.<method name>`

Method | Argument(s) | Returned Value(s) | Description
------------ | ------------- | ------------- | -------------
**addNotification()** | `String` html, `NotificationType` notificationType | N/A | Adds a notification to the bottom of the editor with the provided HTML content. `NotificationType` determines how it is styled.
**clear()** | N/A | N/A | Resets the HTML editor to its default state
**clearFocus()** | N/A | N/A | Clears focus for the webview and resets the height to the original height on mobile. Do *not* use this method in Flutter Web.
**disable()** | N/A | N/A | Disables the editor (a gray mask is applied and all touches are absorbed)
**enable()** | N/A | N/A | Enables the editor
**getText()** | N/A | `Future<String>` | Returns the current HTML in the editor
**insertHtml()** | `String` | N/A | Inserts the provided HTML string into the editor at the current cursor position. Do *not* use this method for plaintext strings.
**insertLink()** | `String` text, `String` url, `bool` isNewWindow | N/A | Inserts a hyperlink using the provided text and url into the editor at the current cursor position. `isNewWindow` defines whether a new browser window is launched if the link is tapped.
**insertNetworkImage()** | `String` url, `String` filename (optional) | N/A | Inserts an image using the provided url and optional filename into the editor at the current cursor position. The image must be accessible via a URL.
**insertText()** | `String` | N/A | Inserts the provided text into the editor at the current cursor position. Do *not* use this method for HTML strings.
**recalculateHeight()** | N/A | N/A | Recalculates the height of the editor by re-evaluating `document.body.scrollHeight`
**redo()** | N/A | N/A | Redoes the last command in the editor
**reloadWeb()** | N/A | N/A | Reloads the webpage in Flutter Web. This is mainly provided to refresh the text editor theme when the theme is changed. Do *not* use this method in Flutter Mobile.
**removeNotification()** | N/A | N/A | Removes the current notification from the bottom of the editor
**resetHeight()** | N/A | N/A | Resets the height of the webview to the original height. Do *not* use this method in Flutter Web.
**setHint()** | `String` | N/A | Sets the current hint text of the editor
**setFocus()** | N/A | N/A | If the pointer is in the webview, the focus will be set to the editor box
**setFullScreen()** | N/A | N/A | Sets the editor to take up the entire size of the webview
**setText()** | `String` | N/A | Sets the current text in the HTML to the input HTML string
**toggleCodeview()** | N/A | N/A | Toggles between the code view and the rich text view
**undo()** | N/A | N/A | Undoes the last command in the editor

### Callbacks

Every callback is defined as a `Function(<parameters in some cases>)`. See the [documentation](https://pub.dev/documentation/html_editor_enhanced/latest/) for more specific details on each callback.
 
Callback | Parameter(s) | Description
------------ | ------------- | -------------
**onBeforeCommand** | `String` | Called before certain commands are called (like undo and redo), passes the HTML in the editor before the command is called
**onChange** | `String` | Called when the content of the editor changes, passes the current HTML in the editor
**onChangeCodeview** | `String` | Called when the content of the codeview changes, passes the current code in the codeview
**onDialogShown** | N/A | Called when either the image, link, video, or help dialogs are shown
**onEnter** | N/A | Called when enter/return is pressed
**onFocus** | N/A | Called when the rich text field gains focus
**onBlur** | N/A | Called when the rich text field or the codeview loses focus
**onBlurCodeview** | N/A | Called when the codeview either gains or loses focus
**onImageLinkInsert** | `String` | Called when an image is inserted via URL, passes the URL of the image
**onImageUpload** | `FileUpload` | Called when an image is inserted via upload, passes `FileUpload` which holds filename, date modified, size, and MIME type
**onImageUploadError** | `FileUpload`, `String`, `UploadError` | Called when an image fails to inserted via upload, passes `FileUpload` which may hold filename, date modified, size, and MIME type (or be null), `String` which is the base64 (or null), and `UploadError` which describes the type of error
**onInit** | N/A | Called when the rich text field is initialized and JavaScript methods can be called
**onKeyDown** | `int` | Called when a key is downed, passes the keycode of the downed key
**onKeyUp** | `int` | Called when a key is released, passes the keycode of the released key
**onMouseDown** | N/A | Called when the mouse/finger is downed
**onMouseUp** | N/A | Called when the mouse/finger is released
**onPaste** | N/A | Called when content is pasted into the editor
**onScroll** | N/A | Called when editor box is scrolled

### Getters

Currently, the package has one getter: `<controller name>.editorController`. This returns the `InAppWebViewController`, which manages the webview that displays the editor.

This is extremely powerful, as it allows you to create your own custom methods and implementations directly in your app. See [`flutter_inappwebview`](https://github.com/pichillilorenzo/flutter_inappwebview) for documentation on the controller.

This getter *should not* be used in Flutter Web. If you are making a cross platform implementation, please use `kIsWeb` to check the current platform in your code.

### Toolbar

This API allows you to customize Summernote's toolbar in a nice, readable format (you don't have to mess around with strings!).

By default, the toolbar will be set to:

```text
toolbar: [
  ['style', ['style']],
  ['font', ['bold', 'underline', 'clear']],
  ['color', ['color']],
  ['para', ['ul', 'ol', 'paragraph']],
  ['insert', ['link', 'picture', 'video', 'table']],
  ['view', ['fullscreen', 'codeview', 'help']],
],
```

This is pretty close to Summernote's [default options](https://summernote.org/deep-dive/#custom-toolbar-popover). Setting `toolbar` to null or empty will initialize the editor with these options.

Well, what if you want to customize it? Don't worry, it's a nice and neat API:

```dart
HtmlEditorController controller = HtmlEditorController();
Widget htmlEditor = HtmlEditor(
  controller: controller, //required
  //other options
  toolbar: [
    Style(),
    Font(buttons: [FontButtons.bold, FontButtons.underline, FontButtons.italic])
  ]
);
```

In the above example, the editor will only be initialized with the 'style', 'bold', 'underline', and 'italic' buttons.

If you leave the `Toolbar` constructor blank (like `Style()` above), then the package interprets that you want the default buttons for `Style` to be visible.

You can specify a list of buttons that are visible for each `Toolbar` constructor. Each constructor accepts a different type of enum in its button list, so you'll always put the right buttons in the right places.

If you don't want to show an entire group of buttons, simply don't include their constructor in the `Toolbar` list!

Note: Setting `buttons: []` will also be interpreted as wanting the default buttons for the constructor rather than not showing the group of buttons.

### Plugins

This API allows you to add certain Summernote plugins from the [Summernote Awesome library](https://github.com/summernote/awesome-summernote).

Currently the following plugins are supported:

1. [Summernote Emoji from Ajax](https://github.com/tylerecouture/summernote-ext-emoji-ajax/) -
Adds a button to the toolbar to allow the user to insert emojis. These are loaded via Ajax.

2. [Summernote Add Text Tags](https://github.com/tylerecouture/summernote-add-text-tags) -
Adds a button to the toolbar to support tags like var, code, samp, and more.

3. [Summernote Case Converter](https://github.com/piranga8/summernote-case-converter) -
Adds a button to the toolbar to convert the selected text to all lowercase, all uppercase, sentence case, or title case.

4. [Summernote List Styles](https://github.com/tylerecouture/summernote-list-styles) -
Adds a button to the toolbar to customize the ul and ol list style.

5. [Summernote RTL](https://github.com/virtser/summernote-rtl-plugin) -
Adds two buttons to the toolbar that switch the currently selected text between LTR and RTL format.

6. [Summernote At Mention](https://github.com/team-loxo/summernote-at-mention) -
Shows a dropdown of available mentions when the '@' character is typed into the editor. The implementation requires that you pass a list of available mentions, and you can also provide a function to call when a mention is inserted into the editor.

7. [Summernote Codewrapper](https://github.com/semplon/summernote-ext-codewrapper) -
Adds a button to the toolbar that wraps the selected text in a code block.

8. [Summernote File](https://github.com/mathieu-coingt/summernote-file) -
Adds a button to the toolbar that allows the user to upload any type of file. It supports picture files (jpg, png, gif, wvg, webp), audio files (mp3, ogg, oga), and video files (mp4, ogv, webm) in base64. For all other formats, you must use the onFileUpload callback to upload the files to a server and then insert an HTML node into the editor.<br>
See [below](#summernote-file-plugin) for more details.

This list is not final, more will be added. If there's a specific plugin you'd like to see support for, please file a feature request!

By default, no plugins will be activated. What if you want to activate some? Don't worry, it's a nice and neat API:

```dart
HtmlEditorController controller = HtmlEditorController();
Widget htmlEditor = HtmlEditor(
  controller: controller, //required
  //other options
  plugins: [
    SummernoteEmoji(),
    SummernoteAtMention(
      mentions: ['test1', 'test2', 'test3'],
      onSelect: (String value) {
        print(value);
    }),
    SummernoteFile(onFileUpload: (file) {
      print(file.name);
      print(file.size);
      print(file.type);
    }),
  ]
);
```

In the above example, only those three plugins will be activated in the editor. Order matters here - whatever order you define the plugins is the order their buttons will be displayed in the toolbar.

All plugin buttons will be displayed in one section in the toolbar. Overriding the toolbar using the `toolbar` parameter does not affect how the plugin buttons are displayed. 

Please see the `plugins.dart` file for more specific details on each plugin, including some important notes to consider when deciding whether or not to use them in your implementation.

### `onImageUpload` and `onImageLinkInsert`

These two callbacks pass the file data or URL of the inserted image, respectively.

The important thing to note with these callbacks is that they override Summernote's default implementation.

THis means that you must provide code, using either `<controller name>.insertHtml()` or `<controller name>.insertNetworkImage()`, to insert the image into the editor because it will not insert automatically.

See [below](#example-for-onimageupload-and-onimagelinkinsert) for an example.

### `autoAdjustHeight`

Default value: true

This option parameter sets the height of the editor automatically by getting the value returned by the JS `document.body.scrollHeight`. 

This is useful because the Summernote toolbar could have either 1, 2, or 3 rows depending on the widget's configuration, screen size, orientation, etc. There is no reliable way to tell how large the toolbar is going to be before the webview content is loaded, and thus simply hardcoding the height of the webview can induce either empty space at the bottom or a scrollable webview. By using the JS, the editor can get the exact height and update the widget to reflect that.

There is a drawback: The webview will visibly shift size after the page is loaded. Depending on how large the change is, it could be jarring. Sometimes, it takes a second for the webview to adjust to the new size and you might see the editor page jump down/up a second or two after the webview container adjusts itself.

If this does not help your use case feel free to disable it, but the recommended value is `true`.

### `adjustHeightForKeyboard`

Default value: true, only considered on mobile

This option parameter changes the height of the editor if the keyboard is active and it overlaps with the editor. 

This is useful because webviews do not shift their view when the keyboard is active on Flutter at the moment. This means that if your editor spans the height of the page, if the user types a long text they might not be able to see what they are typing because it is obscured by the keyboard.

When this parameter is enabled, the webview will shift to the perfect height to ensure all the typed content is visible, and as soon as the keyboard is hidden, the editor shifts back to its original height.

The webview does take a moment to shift itself back and forth after the keyboard pops up/keyboard disappears, but the delay isn't too bad. It is highly recommended to have the webview in a `Scrollable`  and `shouldEnsureVisible` enabled if there are other widgets on the page - if the editor is on the bottom half of the page it will be scrolled to the top and then the height will be set accordingly, rather than the plugin trying to set the height for a webview obscured completely by the keyboard.

See [below](#example-for-adjustheightforkeyboard) for an example use case.

If this does not help your use case feel free to disable it, but the recommended value is `true`.

### `filePath`

This option parameter allows you to fully customize what HTML is loaded into the webview, by providing a file path to a custom HTML file from assets.

There is a particular format that is required/recommended when providing a file path for web, because the web implementation will load the HTML as a `String` and make changes to it directly using `replaceAll().`, rather than using a method like `evaluateJavascript()` - because that does not exist on Web.

On Web, you should include the following:

1. `<!--darkCSS-->` inside `<head>` - this enables dark mode support

2. `<!--headString-->` inside `<body>` and below your summernote `<div>` - this allows the JS and CSS files for any enabled plugins to be loaded

3. `<!--summernoteScripts-->` inside `<body>` and below your summernote `<div>` - REQUIRED - this allows Dart and JS to communicate with each other. If you don't include this, then methods/callbacks will do nothing. 

Notes:

1. Do *not* initialize the Summernote editor in your custom HTML file! The package will take care of that.

2. Make sure to set the `id` for Summernote to `summernote-2`! - `<div id="summernote-2"></div>`.

3. Make sure to include jquery and the Summernote JS/CSS in your file! The package does not do this for you.<br><br>
You can use these files from the package to avoid adding more asset files:

```html
<script src="assets/packages/html_editor_enhanced/assets/jquery.min.js"></script>
<link href="assets/packages/html_editor_enhanced/assets/summernote-lite.min.css" rel="stylesheet">
<script src="assets/packages/html_editor_enhanced/assets/summernote-lite.min.js"></script>
```

See the example HTML file [below](#example-html-for-filepath) for an actual example.

### `shouldEnsureVisible`

Default value: false

This option parameter will scroll the editor container into view whenever the webview is focused or text is typed into the editor. 

You can only use this parameter if your `HtmlEditor` is inside a `Scrollview`, otherwise it does nothing.

This is useful in cases where the page is a `SingleChildScrollView` or something similar with multiple widgets (eg a form). When the user is going through the different fields, it will pop the webview into view, just like a `TextField` would scroll into in view if text is being typed inside it. 

See [below](#example-for-shouldensurevisible) for an example with a good way to use this.

### `processInputHtml`, `processOutputHtml`, and `processNewLineAsBr`

Default values: true, true, false, respectively

`processInputHtml` replaces any occurrences of `"` with `\\"`, `'` with `\\'`, and `\r`, `\r\n`, `\n`, and `\n\n` with empty strings. This is necessary to prevent syntax exceptions when inserting HTML into the editor as quotes and other special characters will not be escaped. If you have already sanitized and escaped all relevant characters from your HTML input, it is recommended to set this parameter `false`. You may also want to set this parameter `false` on Web, as in testing it seems these characters are handled correctly by default, but that may not be the case for your HTML.

`processOutputHtml` replaces the output HTML with `""` if: 

1. It is empty

2. It is `<p></p>`

3. It is `<p><br></p>`

4. It is `<p><br/></p>`

These may seem a little random, but they are the three possible default/initial HTML codes the Summernote editor will have. If you'd like to still receive these outputs, set the parameter `false`.

`processNewLineAsBr` will replace `\n` and `\n\n` with `<br/>`. This is only recommended when inserting plaintext as the initial value. In typical HTML any new-lines are ignored, and therefore this parameter defaults to `false`.

### Summernote File Plugin

Adds a button to the toolbar that allows the user to upload any type of file. It supports picture files (jpg, png, gif, wvg, webp), audio files (mp3, ogg, oga), and video files (mp4, ogv, webm) in base64. 

Callbacks and parameters: `onFileUpload` (fired when a file is uploaded), `onFileLinkInsert` (fired when a file is inserted by link), `onFileUploadError` (fired when a file insertion fails for any reason), and `maximumFileSize` (allows you to set a max file size to upload, if exceeded, then onFileUploadError is called)

For all other formats, you can use the onFileUpload callback to upload the files to a server and then insert an HTML node into the editor.

Please be aware that setting the onFileUpload callback removes the base64 functionality - instead you will also have to provide a solution to upload the picture, audio, and video files in your Dart code. Then, you can use the `<controller name>.insertHtml(<html string>)` method to insert the relevant HTML element at the current cursor position.

Another way to upload any other type of file without overriding the default handler is to use `onFileUploadError`. This function will return the same data as `onFileUpload`, and it will also describe which error occurred (either unsupported file, exceeded max size, or JavaScript error). Using the base64 data, you can upload the files and create your HTML node.

`onFileLinkInsert` will pass the link of the inserted file as a `String`. Note that the link insertion has no validation, so if a user inserts "test" as the link, this function will be called rather than `onFileUploadError`.

Setting onFileLinkInsert also overrides the default handler, so you must provide code to manually insert the link into the editor.

See [below](#example-for-onimageupload-and-onimagelinkinsert) for an example that shows how to insert HTML and upload files.

## Examples

See the [example app](https://github.com/tneotia/html-editor-enhanced/blob/master/example/lib/main.dart) to see how the majority of methods & callbacks can be used. You can also play around with the parameters to see how they function.

This section will be updated later with more specialized and specific examples as this library grows and more features are implemented.

### Example for `onImageUpload` and `onImageLinkInsert`:

Note: This example could also be easily refactored for the Summernote File plugin's `onFileUpload`, `onFileLinkInsert`, and `onFileUploadError`.

<details><summary>Example code</summary>

Note: This example uses the [http](https://pub.dev/packages/http) package.

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

  Widget editor = HtmlEditor(
    controller: controller,
    hint: "Your text here...",
    //initialText: "<p>text content initial, if any</p>",
    callbacks: Callbacks(
      onImageLinkInsert: (String? url) {
        if (url != null && url.contains(website_url)) {
          controller.insertNetworkImage(url!);
        } else {
          controller.insertText("This image is invalid!");
        }
      },
      onImageUpload: (FileUpload file) async {
        print(file.name); //filename
        print(file.size); //size in bytes
        print(file.type); //MIME type (e.g. image/jpg)
        print(file.lastModified.toString()); //DateTime object for last modified
        //either upload to server:
        if (file.base64 != null) {
          //you must remove the initial identifying data (MIME type and dnd data type) from the
          //base64 string before decoding it - split helps us do this
          Uint8List list = base64.decode(file.base64!.split(",")[1]);
          final request = http.MultipartRequest('POST', Uri.parse("your_server_url"));
          request.files.add(http.MultipartFile.fromBytes("file", bytes, filename: file.name)); //your server may require a different key than "file"
          final response = await request.send();
          //try to insert as network image, but if it fails, then try to insert as base64:
          if (response.statusCode == 200) {
            controller.insertNetworkImage(response.body["url"], filename: file.name); //where "url" is the url of the uploaded image returned in the body JSON
          } else {
            String base64Image =
              """<img src="${file.base64!}" data-filename="${file.name}"/>""";
            controller.insertHtml(base64Image);
          }
        }
        //or insert as base64:
        if (file.base64 != null) {
          String base64Image =
              """<img src="${file.base64!}" data-filename="${file.name}"/>""";
          controller.insertHtml(base64Image);
        }
      },
    ),
  );
```

</details>

### Example for `adjustHeightForKeyboard`:

<details><summary>Example code</summary>

```dart
class _HtmlEditorExampleState extends State<HtmlEditorExample> {
  final HtmlEditorController controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          // this is extremely important to the example, as it allows the user to tap any blank space outside the webview,
          // and the webview will lose focus and reset to the original height as expected. 
          controller.clearFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //other widgets
              HtmlEditor(
                controller: controller,
                hint: "Your text here...",
                //initialText: "<p>text content initial, if any</p>",
                options: HtmlEditorOptions(
                  height: 550,
                  shouldEnsureVisible: true,
                  //adjustHeightForKeyboard is true by default
                ),
              ),
              //other widgets
            ],
          ),
        ),
      ),
    );
  }
}
```

</details>

### Example for `shouldEnsureVisible`:

<details><summary>Example code</summary>

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class _ExampleState extends State<Example> {
  final HtmlEditorController controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          //these lines of code hide the keyboard and clear focus from the webview when any empty
          //space is clicked. These are very important for the shouldEnsureVisible to work as intended.
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          controller.editorController!.clearFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          actions: [
            IconButton(
               icon: Icon(Icons.check),
               tooltip: "Save",
               onPressed: () {
                  //save profile details
               }
            ),
          ]   
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 18, right: 18),
                child: TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  focusNode: titleFocusNode,
                  decoration: InputDecoration(
                      hintText: "Name",
                      border: InputBorder.none
                  ),
                ),
              ),
              SizedBox(height: 16),
              HtmlEditor(
                controller: controller,
                hint: "Description",
                options: HtmlEditorOptions(
                  height: 450,
                  shouldEnsureVisible: true,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(left: 18, right: 18),
                child: TextField(
                  controller: bioController,
                  textInputAction: TextInputAction.next,
                  focusNode: bioFocusNode,
                  decoration: InputDecoration(
                    hintText: "Bio",
                    border: InputBorder.none
                  ),
                ),
              ),
              Image.network("path_to_profile_picture"),
              IconButton(
                 icon: Icon(Icons.edit, size: 35),
                 tooltip: "Edit profile picture",
                 onPressed: () async {
                    //open gallery and make api call to update profile picture   
                 }
              ),
              //etc... just a basic form.
            ],
          ),
        ),
      ),
    );
  }
}
```

</details>

### Example HTML for `filePath`:

<details><summary>Example HTML</summary>

```html
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="description" content="Flutter Summernote HTML Editor">
    <meta name="author" content="xrb21">
    <title>Summernote Text Editor HTML</title>
    <script src="assets/packages/html_editor_enhanced/assets/jquery.min.js"></script>
    <link href="assets/packages/html_editor_enhanced/assets/summernote-lite.min.css" rel="stylesheet">
    <script src="assets/packages/html_editor_enhanced/assets/summernote-lite.min.js"></script>
    <!--darkCSS-->
</head>
<body>
<div id="summernote-2"></div>
<!--headString-->
<!--summernoteScripts-->
<style>
  body {
      display: block;
      margin: 0px;
  }
  .note-editor.note-airframe, .note-editor.note-frame {
      border: 0px solid #a9a9a9;
  }
  .note-frame {
      border-radius: 0px;
  }
</style>
</body>
</html>
```

</details>

## Notes

Due to this package depending on a webview for rendering the HTML editor, there will be some general weirdness in how the editor behaves. Unfortunately, these are not things I can fix, they are inherent problems with how webviews function on Flutter.

If you do find any issues, please report them in the Issues tab and I will see if a fix is possible, but if I close the issue it is likely due to the above fact.

1. When switching between dark and light mode, a reload is required for the HTML editor to switch to the correct color scheme. You can implement this programmatically in Flutter Mobile: `<controller name>.editorController.reload()`, or in Flutter Web: `<controller name>.reloadWeb()`. This will reset the editor! You can save the current text, reload, and then set the text if you'd like to maintain the state.

2. If you are making a cross platform implementation and are using either the `controller` getter or the `reloadWeb()` method, use `kIsWeb` in your app to ensure you are calling these in the correct platform.

3. Inline notifications are finnicky on mobile. It seems that adding/removing a notification adds 2 px to the height of the editor, even though the height is recalculated each time. At the moment I have not found a workaround. This behavior is not present on Web, however.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contribution Guide

> Coming soon!
>
> Meanwhile, PRs are always welcome

Original html_editor by [xrb21](https://github.com/xrb21) - [repo link](https://github.com/xrb21/flutter-html-editor). Credits for the original idea and original base code to him. This library is a fork of his repo.
