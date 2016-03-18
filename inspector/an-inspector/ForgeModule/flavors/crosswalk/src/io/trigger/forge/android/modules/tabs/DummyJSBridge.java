package io.trigger.forge.android.modules.tabs;

import org.xwalk.core.JavascriptInterface;

import io.trigger.forge.android.core.ForgeLog;

/**
 * Created by antoine on 16/03/18.
 */
public class DummyJSBridge {

    @JavascriptInterface
    public void callJavaFromJavaScript(final String callid, final String method, final String params) {
        ForgeLog.d("DummyJSBridge.callJavaFromJavaScript -> " + method + " -> " + params);
    }
}
