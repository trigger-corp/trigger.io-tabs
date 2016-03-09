/*global forge, module, asyncTest, ok, start, askQuestion, equal */
module("forge.tabs");

asyncTest("Open tab in foreground", 1, function() {
	forge.tools.getURL("fixtures/tabs/close.html", function (url) {
		forge.tabs.open(url, function () {
			askQuestion("Did a tab/view just open in the foreground with the text 'Close me!'?", {
				Yes: function () {
					ok(true, "Success");
					start();
				},
				No: function () {
					ok(false, "User claims failure");
					start();
				}
			});
		}, function (e) {
			ok(false, "API call failure: "+e.message);
			start();
		});
	});
});

if (forge.is.android()) {
	asyncTest("Open tab in foreground - close with back button", 1, function() {
		forge.tools.getURL("fixtures/tabs/back-out.html", function (url) {
			forge.tabs.open(url, function () {
				askQuestion("Did a view just open with the text 'Press the back button'?", {
					Yes: function () {
						ok(true, "Success");
						start();
					},
					No: function () {
						ok(false, "User claims failure");
						start();
					}
				});
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		});
	});

	asyncTest("Truncate and ellipsize title text", 1, function() {
		forge.tools.getURL("fixtures/tabs/truncate.html", function (url) {
			forge.tabs.openWithOptions({
				url: url,				
				title: "This is a long title text which should be neatly truncated and ellipsized",
				buttonText: "Leave"
			}, function () {
				askQuestion("Did a tab open with truncated and ellipsized title text and a visible 'Leave' button?", {
					Yes: function () {
						ok(true, "Success");
						start();
					},
					No: function () {
						ok(false, "User claims failure");
						start();
					}
				});
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		});
	});
}

if (forge.is.mobile()) {
	asyncTest("Tab with match pattern", 1, function() {
		forge.tools.getURL("fixtures/tabs/goto.html", function (url) {
			forge.tabs.openWithOptions({
				url: url,
				pattern: "https://trigger.io/*"
			}, function (data) {
				equal(data.url, "https://trigger.io/", "Correct url");
				start();
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		});
	});

	asyncTest("Tab with options", 1, function() {
		forge.tools.getURL("fixtures/tabs/taboptions.html", function (url) {
			forge.tabs.openWithOptions({
				url: url,
				tint: [75, 0, 0, 255],
				titleTint: [0, 0, 255, 255],
				buttonTint: [0, 75, 0, 255],
				title: "Hello",
				buttonText: "Leave",
				translucent: true
			}, function () {
				askQuestion("Did a tab open and describe itself correctly?", {
					Yes: function () {
						ok(true, "Success");
						start();
					},
					No: function () {
						ok(false, "User claims failure");
						start();
					}
				});
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		});
	});

	asyncTest("Advanced tab", 1, function() {
		forge.tools.getURL("fixtures/tabs/close.html", function (url) {
			forge.tabs.openAdvanced({
				url: url
			}, function (modal) {
				modal.loadFinished.addListener(function () {
					modal.executeJS("window.document.body.innerHTML = '<h1>Hello! Close me.</h1>';");
				});
				modal.closed.addListener(function () {
					askQuestion("Did a tab open say hello?", {
						Yes: function () {
							ok(true, "Success");
							start();
						},
						No: function () {
							ok(false, "User claims failure");
							start();
						}
					});
				});
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		});
	});

}
