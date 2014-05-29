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
-  ``buttonText``: Text to show in the button to close the modal view.
-  ``buttonIcon``: Icon to show in the button to close the modal view,
   if ``buttonIcon`` is specified ``buttonText`` will be ignored.
-  ``buttonTint``: Color to tint the button of the top bar in the modal
   view.

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
-  ``buttonText``: Text to show in the button to close the modal view.
-  ``buttonIcon``: Icon to show in the button to close the modal view,
   if ``buttonIcon`` is specified ``buttonText`` will be ignored.
-  ``buttonTint``: Color to tint the button of the top bar in the modal
   view.

The ``modalBrowser`` returned in the success callback has the following methods:

- ``modalBrowser.executeJS(script, success, error)``: This will execute the given string in the modal browser, the success callback will be called with the string result. It is recommended you only use this after the loadFinished event (see below) as in other situations JavaScript may not be ready and you may get undefined behaviour.
- ``modalBrowser.close(success, error)``: Force the modal browser to close immediately.
- ``modalBrowser.loadStarted.addListener(callback)``: This callback will be called whenever a page load is started. The callback will be passed an object with a ``url`` field for the pages url.
- ``modalBrowser.loadFinished.addListener(callback)``: This callback will be called whenever a page load finishes. The callback will be passed an object with a ``url`` field for the pages url.
- ``modalBrowser.loadError.addListener(callback)``: This callback will be called whenever a page load fails. The callback will be passed an object with a ``url`` field for the pages url and a ``description`` field with a text description of the error.
- ``modalBrowser.closed.addListener(callback)``: This callback will be called whenever the modalBrowser is closed. The callback will be passed an object with a ``url`` field for the browsers final url and ``userCancelled`` which is a boolean to indicate whether the user closed the modal browser.


**Example**:

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