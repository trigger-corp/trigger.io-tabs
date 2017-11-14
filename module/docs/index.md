``tabs``: Child Browser
=========================

The ``forge.tabs`` namespace allows you to open a browser tab.

##API

!method: forge.tabs.open(url, success, error)
!param: url `string` the URL to open in the new browser tab
!param: success `function(object)` callback to be invoked when no errors occur
!description: Opens a new tab with the specified url. This will display a [modal view](/docs/current/recipes/integrations/modal.html) and the success callback will be called with an object containing a url and optionally a ``userCancelled`` boolean property.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

!method: forge.tabs.openWithOptions(options, success, error)
!param: options `object` object containing url and optional properties
!param: success `function(object)` callback to be invoked when no errors occur
!description: As ``open`` but takes an object with the parameters listed below enabling control of the child browser which is opened.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

Required:

-  ``url``: Required URL to open

Optional:

-  ``pattern``: Pattern to close the modal view, see
   [modal views](/docs/current/recipes/integrations/modal.html) for more detail on usage.
-  ``title``: Title of the modal view.
-  ``tint``: Color to tint the top bar of the modal view. An array of
   four integers in the range [0,255] that make up the RGBA color. For
   example, opaque red is [255, 0, 0, 255].
-  ``opaqueTopBar``: Set to `true` to turn off the top bar translucency effect (iOS Only)
-  ``titleTint``: Color to tint the top bar title of the modal view. An array of
   four integers in the range [0,255] that make up the RGBA color. For
   example, opaque red is [255, 0, 0, 255].
-  ``buttonText``: Text to show in the button to close the modal view.
-  ``buttonIcon``: Icon to show in the button to close the modal view,
   if ``buttonIcon`` is specified ``buttonText`` will be ignored.
-  ``buttonTint``: Color to tint the button of the top bar in the modal
   view.
- ``basicAuth``: Set to `true` to enable [Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) support for sites opened in the tab.
- ``basicAuthConfig``: Configuration for Basic Authentication. An object containing one or more of the following fields: `closeTabOnCancel`, `useCredentialStorage`, `titleText`, `usernameHintText`, `passwordHintText`, `loginButtonText`, `cancelButtonText`. If you include the pattern, `%host%`, in the `titleText` field it will be replaced by the hostname of the site being logged into.

**Example**:

    forge.tabs.openWithOptions({
      url: 'http://my.server.com/login/',
      pattern: 'http://my.server.com/loggedin/*',
      title: 'Login Page'
    }, function (data) {
      forge.logging.log(data.url);
    });

!method: forge.tabs.openAdvanced(options, success, error)
!platforms: iOS, Android
!param: options `object` object containing url and optional properties
!param: success `function(modalBrowserObject)` callback to be invoked when no errors occur
!param: error `function(content)` called with details of any error which may occu
!description: As ``openWithOptions`` but immediately returns a modalBrowserObject which can be used to listen to events in the modal browser and execute javascript in the page.

> ::Warning:: This API method should only be used if absolutely required, executing JavaScript code on external pages in the modal view can cause issues if not used carefully.

Required:

-  ``url``: Required URL to open

Optional:

-  ``pattern``: Pattern to close the modal view, see
   [modal views](/docs/current/recipes/integrations/modal.html) for more detail on usage.
-  ``title``: Title of the modal view.
-  ``tint``: Color to tint the top bar of the modal view. An array of
   four integers in the range [0,255] that make up the RGBA color. For
   example, opaque red is [255, 0, 0, 255].
-  ``titleTint``: Color to tint the top bar title of the modal view. An array of
   four integers in the range [0,255] that make up the RGBA color. For
   example, opaque red is [255, 0, 0, 255].
-  ``buttonText``: Text to show in the button to close the modal view.
-  ``buttonIcon``: Icon to show in the button to close the modal view,
   if ``buttonIcon`` is specified ``buttonText`` will be ignored.
-  ``buttonTint``: Color to tint the button of the top bar in the modal
   view.
- ``basicAuth``: Set to `true` to enable [Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) support for sites opened in the tab.
- ``basicAuthConfig``: Configuration for Basic Authentication. An object containing one or more of the following fields: `closeTabOnCancel`, `useCredentialStorage`, `titleText`, `usernameHintText`, `passwordHintText`, `loginButtonText`, `cancelButtonText`. If you include the pattern, `%host%`, in the `titleText` field it will be replaced by the hostname of the site being logged into.



### Modal Browser API

The ``modalBrowser`` object returned in the success callback has the following API:

!method: modalBrowser.executeJS(script, success, error)
!param: success `function(result)` callback to be invoked with the result when no errors occur
!description: This will execute the given string in the modal browser, the success callback will be called with the string result. It is recommended you only use this after the loadFinished event (see below) as in other situations JavaScript may not be ready and you may get undefined behaviour.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

!method: modalBrowser.close(success, error)
!param: success `function()` callback to be invoked when no errors occur
!description: Force the modal browser to close immediately.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

!method: modalBrowser.addButton(params, callback, error)
!param: params `object` button options, must contain at least ``icon`` or ``text``
!param: callback `function()` callback to be invoked each time the button is pressed
!description: Add a button to the modal browser's topbar.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

The first parameter is an object describing the button with the following properties:

-  ``icon``: An icon to be shown on the button: this should be relative
   to the ``src`` directory, e.g. ``"img/button.png"``.
-  ``text``: Text to be shown on the button, either ``text`` or ``icon``
   must be set.
-  ``position``: The position to display the button, either ``left`` or
   ``right``. If not specified the first free space will be used.
-  ``tint``: The color of the button, defined as an array as used for ``tint``.
-  ``style``: The style of the button on iOS, ``done`` (bold text) or default (iOS Only)

!method: modalBrowser.removeButtons(success, error)
!description: This will remove all buttons from the browser's topbar.
!param: success `function()` callback to be invoked when no errors occur
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

### Modal Browser Events

Additionally, the following event listeners are supported:

- ``modalBrowser.loadStarted.addListener(callback)``: This callback will be called whenever a page load is started. The callback will be passed an object with a ``url`` field for the pages url.
- ``modalBrowser.loadFinished.addListener(callback)``: This callback will be called whenever a page load finishes. The callback will be passed an object with a ``url`` field for the pages url.
- ``modalBrowser.loadError.addListener(callback)``: This callback will be called whenever a page load fails. The callback will be passed an object with a ``url`` field for the pages url and a ``description`` field with a text description of the error.
- ``modalBrowser.closed.addListener(callback)``: This callback will be called whenever the modalBrowser is closed. The callback will be passed an object with a ``url`` field for the browsers final url and ``userCancelled`` which is a boolean to indicate whether the user closed the modal browser.


### Example:

    forge.tabs.openAdvanced({
      url: 'http://my.server.com/page/',
    }, function (modal) {
      modal.loadFinished.addListener(function () {
        modal.executeJS("window.document.body.innerHTML = 'Hello Forge user!';");
      });
      modal.closed.addListener(function () {
        alert("Modal closed!");
      }
    });


## Notes

::Crosswalk developers::

There is currently an issue with Crosswalk WebView versions 16 and higher that causes the app display to flicker when opening the on-screen keyboard.

One workaround for this issue is to force Crosswalk to use SurfaceView instead of TextureView by setting ANIMATABLE_XWALK_VIEW to false. This does, however, come at the cost of breaking modules that need to launch additional Crosswalk windows. For example, `forge.tabs`.

Therefore, if you are using the `forge.tabs` module with a `crosswalk` build you will need to set the value of the "Enable Animatable Xwalk View" property to `true` in your `src/config.json` file:

    "crosswalk": {
        "enable_animatable_xwalk_view": true
    }

If you are experiencing flickering when opening the on-screen keyboard you can use the second workaround for this issue which is to set the "Window Soft Input Mode" property to `"adjustPan"` in your `src/config.json` file:

    "android" {
        "windowSoftInputMode": "adjustPan"
    }

This workaround will resolve the flickering, albeit at the cost of the WebView no longer scrolling up when the on-screen keyboard is opened.

The workaround for this depends on your web framework of choice, but a good place to start would be [StackOverflow](http://stackoverflow.com/search?q=%5Bjavascript%5D+%5Bandroid%5D+scroll+page+keyboard).

**tl;dr** If you want to use `forge.tabs` with the `crosswalk` target you need to:
> 1. Set `crosswalk.enable_animatable_xwalk_view` to `true`.
> 2. Set `android.windowSoftInputMode` to `"adjustPan"`.
> 3. Manually handle keyboard show/hide events to ensure your form inputs aren't obscured.

For more information see: [XWALK-3547 -
XWalkView window stretches momentarily when hiding native ui elements](https://crosswalk-project.org/jira/browse/XWALK-3547).

----

::iOS developers:: Beginning with iOS 7, navigation bars and tab bars are configured to be translucent by default.

A translucent bar mixes its `tint` color with gray before combining it with a system-defined alpha value to produce the final background color that is used to composite the bar with the content it overlies.

This can be challenging to work with if you need to maintain a consistent color scheme throughout your app or match a Corporate or Brand color.

If your application needs to set the color of the Tabs top bar with greater precision there are two options available:

1. Turn off top bar translucency: Set the `translucent` property in the options object passed to `tabs.openWithOptions` or `tabs.openAdvanced` to `false`. The color rendered will now match the value of `tint`.

2. Compute a bar tint color to match a given color. Arriving at the correct color may require some experimentation. You may also need to take into account the app content passing under the bar. (e.g. photos, app background color etc.)

> A starting point is to darken each of the RGB channels in your `tint` color by 30, For Example:
>
>     tint: [64, 64, 128, 255]  // starting color
>     tint: [34, 34,  98, 255]  // adjusted color
>
>
> Note that if the starting color in a channel is already less than 30, you may need to darken the other channels by more than 30, for instance:
>
>     tint: [10, 102, 51, 255]  // starting color
>     tint: [ 0,  62, 11, 255]  // adjusted color

For more information see: [Technical Q&A QA1808 - Matching a Bar Tint Color To Your Corporate or Brand Color](https://developer.apple.com/library/ios/qa/qa1808/_index.html)
