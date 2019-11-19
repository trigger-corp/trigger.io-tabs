/* global forge, module, asyncTest, ok, start, askQuestion, equal */

module("forge.tabs");

if (forge.file) {
    var pdf_url = "https://ops.trigger.io/75d92dce/tests/test.pdf";
    asyncTest("Save remote PDF locally and open it", 1, function() {
        forge.file.saveURL(pdf_url, function (file) {
            forge.tools.getURL(file, function (url) {
                forge.tabs.openAdvanced({
                    url: url,
                    title: "PDF File",
                    buttonText: "Done"
                }, function (modal) {
                    modal.closed.addListener(function () {
                        askQuestion("Did a tab/view just open containing a pdf file?", {
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
    });
}


asyncTest("Open Local PDF", 1, function() {
    forge.tools.getURL("fixtures/tabs/size.pdf", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "PDF File",
            buttonText: "Done"
        }, function (modal) {
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open containing a pdf file?", {
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


asyncTest("Open tab with website", 1, function() {
    forge.tabs.open("https://trigger.io", function () {
        askQuestion("Did a tab/view just open in the foreground with the Trigger.io website?", {
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


asyncTest("Open tab with website & navigation toolbar", 1, function() {
    forge.tabs.openWithOptions({
        url: "https://trigger.io",
        scalePagesToFit: true,
        navigationToolbar: true,
        statusBarStyle: "light_content"
    }, function () {
        askQuestion("Did a tab/view just open in the foreground with the Trigger.io website and a navigation toolbar?", {
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


asyncTest("Test HTTP browsing with Basic Auth enabled", 1, function() {
    forge.tabs.openAdvanced({
        url: "https://example.org",
        basicAuth: true,
        basicAuthConfig: {
            retryFailedLogin: true,
            verboseLogging: true
        }
    }, function (modal) {
        modal.closed.addListener(function () {
            askQuestion("Did a tab/view of https://example.org just open in the foreground ?", {
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


asyncTest("Test HTTPS Basic Auth Advanced", 1, function() {
    forge.tabs.openAdvanced({
        url: "https://docker.trigger.io/staffbase/A.html",
        pattern: "https://docker.trigger.io/staffbase/D-close-tab.html?*",
        basicAuth: true,
        basicAuthConfig: {
            titleText: "titleText %host%",
            usernameHintText: "usernameHintText",
            passwordHintText: "passwordHintText",
            loginButtonText: "loginButtonText",
            cancelButtonText: "cancelButtonText",
            closeTabOnCancel: true,
            retryFailedLogin: true,
            verboseLogging: true
        },
        opaqueTopBar: true,
        tint: [255, 255, 255, 255]
    }, function (modal) {
        modal.closed.addListener(function (response) {
            askQuestion("Did a tab/view just open in the foreground with a basic auth prompt and respond with: " + JSON.stringify(response), {
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


asyncTest("Test size", 1, function() {
    forge.tools.getURL("fixtures/tabs/size.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Title Text",
            buttonText: "button"
        }, function (modal) {
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open with a border matching the view size?", {
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


asyncTest("Test Title Text", 1, function() {
    forge.tools.getURL("fixtures/tabs/close.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Set Title Failed",
            buttonText: "button"
        }, function (modal) {
            if (forge.is.ios()) {
                modal.setTitle("Title Text");
            }
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open with one button labelled \"button\" and a title set to \"Title Text\"?", {
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


asyncTest("Add an extra button", 1, function() {
    forge.tools.getURL("fixtures/tabs/buttons.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Test buttons",
            buttonText: "default",
            pattern: "http://localhost/close.me.now"
        }, function (modal) {
            modal.addButton({
                position: "right",
                text: "right",
                tint: [255, 0, 0, 255]
            }, function () {
                forge.logging.log("clicked right");
                alert("clicked right");
            }, function (e) {
                ok(false, "API call failure: " + e.message);
                start();
            });

            askQuestion("Did a tab/view just open with two buttons?", {
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


asyncTest("Remove buttons", 1, function() {
    forge.tools.getURL("fixtures/tabs/buttons.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Test buttons",
            buttonText: "default",
            pattern: "http://localhost/close.me.now"
        }, function (modal) {
            modal.removeButtons(function ()	{
                askQuestion("Did a tab/view just open with no buttons?", {
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


asyncTest("Left Button", 1, function() {
    forge.tools.getURL("fixtures/tabs/buttons.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Test buttons",
            buttonText: "default",
            pattern: "http://localhost/close.me.now"
        }, function (modal) {
            modal.removeButtons(function ()	{
                modal.addButton({
                    position: "left",
                    icon: "fixtures/tabs/1.png",
                    tint: [255, 0, 0, 255]
                }, function () {
                    forge.logging.log("clicked left");
                    alert("clicked left");
                    modal.close();
                }, function (e) {
                    ok(false, "API call failure: " + e.message);
                    start();
                });
            });
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open with a button on the left?", {
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


asyncTest("Right Button", 1, function() {
    forge.tools.getURL("fixtures/tabs/buttons.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Test buttons",
            buttonText: "default",
            pattern: "http://localhost/close.me.now"
        }, function (modal) {
            modal.removeButtons(function ()	{
                modal.addButton({
                    position: "right",
                    icon: "fixtures/tabs/1.png",
                    tint: [255, 0, 0, 255]
                }, function () {
                    forge.logging.log("clicked right");
                     alert("clicked right");
                     modal.close();
                }, function (e) {
                    ok(false, "API call failure: " + e.message);
                    start();
                });
            });
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open with a button on the right?", {
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

asyncTest("Both Buttons", 1, function() {
    forge.tools.getURL("fixtures/tabs/buttons.html", function (url) {
        forge.tabs.openAdvanced({
            url: url,
            title: "Test buttons",
            buttonText: "default",
            pattern: "http://localhost/close.me.now"
        }, function (modal) {
            modal.removeButtons(function ()	{
                modal.addButton({
                    position: "left",
                    text: "left",
                    tint: [0, 0, 255, 255]
                }, function () {
                    forge.logging.log("clicked left");
                    alert("clicked left");
                }, function (e) {
                    ok(false, "API call failure: " + e.message);
                    start();
                });
                modal.addButton({
                    position: "right",
                    text: "right",
                    tint: [255, 0, 0, 255]
                }, function () {
                    forge.logging.log("clicked right");
                    alert("clicked right");
                }, function (e) {
                    ok(false, "API call failure: " + e.message);
                    start();
                });
            });
            modal.closed.addListener(function () {
                askQuestion("Did a tab/view just open with a button on the left and right?", {
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
}

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
            statusBarStyle: "light_content"
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

asyncTest("Open tab with file picker for upload", 1, function() {
    forge.tabs.open("https://req-playground.scthi.tech/upload", function () {
        askQuestion("Have you been able to pick files and upload them?", {
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

asyncTest("Open tab with downloads", 1, function() {
    forge.tabs.open("https://req-playground.scthi.tech/downloads", function () {
        askQuestion("Have you been able to open the files listed on the download page?", {
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
