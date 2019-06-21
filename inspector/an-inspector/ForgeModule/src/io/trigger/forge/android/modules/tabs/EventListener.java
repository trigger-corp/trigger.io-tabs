package io.trigger.forge.android.modules.tabs;

import android.content.Intent;
import android.net.Uri;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeWebView;

import android.content.res.Configuration;
import android.view.KeyEvent;

import static android.app.Activity.RESULT_OK;

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
	public void onActivityResult(int RequestCode, int resultCode, Intent intent) {
		if (RequestCode == ModalView.FILE_CHOOSER_RESULT_CODE) {
			ForgeLog.i("Got file upload intent result.");
			Uri result = intent == null || resultCode != RESULT_OK ? null
					: intent.getData();

			if (ModalView.instance == null) {
				ForgeLog.i("onActivityResult: ModalView.instance is null (already closed)");
				return;
			}

			ModalView.instance.onFileUploadSelected(result);
		}
	}

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
		if (ModalView.instance == null) {
			ForgeLog.i("onConfigurationChanged: ModalView.instance is null (already closed)");
			return;
		}

		ModalView.instance.updateContentInsets();
    }
}
