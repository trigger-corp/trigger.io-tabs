/* global forge, module, asyncTest, ok, start, equal */

module("forge.tabs");

asyncTest("openWithOptions - fail", 1, function() {
    forge.tabs.openWithOptions({

    }, function () {
        ok(false);
        start();
    }, function () {
        ok(true);
        start();
    });
});

asyncTest("openWithOptions - everything", 1, function() {
    forge.tabs.openWithOptions({
        url: "https://www.trigger.io",
        pattern: "https://trigger.io/*",
        tint: [40, 20, 50, 255],
        buttonText: "Test",
        buttonIcon: "fixtures/tabs/1.png",
        buttonTint: [10, 50, 100, 255],
    }, function (ret) {
        if ("userCancelled" in ret) {
            equal(ret.userCancelled, false);
        } else {
            ok(true);
        }
        start();
    }, function () {
        ok(false);
        start();
    });
});

asyncTest("Advanced tab", 2, function() {
    forge.tools.getURL("fixtures/tabs/close.html", function (url) {
        forge.tabs.openAdvanced({
            url: url
        }, function (modal) {
            modal.loadStarted.addListener(function () {
                console.log("loadStarted");
                ok(true, "Success");
            });
            modal.loadFinished.addListener(function () {
                console.log("loadFinished");
                modal.close();
                console.log("loadFinished fin");
            });
            modal.closed.addListener(function () {
                console.log("modal.closed");
                ok(true, "Success");
                start();
                console.log("modal.closed fin");
            });
        }, apiError("tabs.openAdvanced"));
    });
});

asyncTest("Advanced tab - error", 1, function() {
    forge.tabs.openAdvanced({
        url: "https://does.not.exist/foo/index.html"
    }, function (modal) {
        modal.loadError.addListener(function () {
            modal.close();
            ok(true, "Success");
        });
        modal.closed.addListener(function () {
            start();
        });
    }, function (e) {
        ok(false, "API call failure: "+e.message);
        start();
    });
});

asyncTest("Trusted remote in tab", 1, function() {
    forge.tools.getURL("fixtures/tabs/trusted.html", function (url) {
        forge.logging.log("Got URL: " + url);
        forge.tabs.openAdvanced({
            url: url
        }, function (modal) {
            modal.loadFinished.addListener(function () {
                modal.executeJS("forge.tools.UUID();", function (result) {
                    var valid_uuid = result.search(/........-....-4...-....-............/);
                    ok(valid_uuid === 0, "UUID returned: " + result);
                    start();
                    modal.close();
                }, function (e) {
                    ok(false, "Failed to execute JS: " + JSON.stringify(e));
                    start();
                    modal.close();
                });
            });
        }, apiError("tabs.openAdvanced"));
    });
});
