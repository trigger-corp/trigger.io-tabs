package io.trigger.forge.android.modules.tabs;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeWebView;

import android.content.res.Configuration;
import android.view.KeyEvent;

public class EventListener extends ForgeEventListener {
	@Override
	public Boolean onKeyDown(int keyCode, KeyEvent event) {
		if (keyCode == KeyEvent.KEYCODE_BACK && ModalView.instance != null && ModalView.instance.getWebView() != null) {
			final ForgeWebView webView = ModalView.instance.getWebView();
			if (webView != null && webView.canGoBack()) {
				ForgeLog.i("Back button pressed in modal view, navigating to previous URL.");
				webView.goBack();
				return true;
			} else if (webView != null) {
				ForgeLog.i("Back button pressed, closing modal view.");
				ModalView.instance.closeModal(ForgeApp.getActivity(), webView.getUrl(), true);
				return true;
			}
		}
		return null;
	}

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
	    ModalView.instance.updateContentInsets();
    }
}
