package io.trigger.forge.android.modules.tabs;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeJSBridge;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeTask;
import io.trigger.forge.android.core.ForgeUtil;
import io.trigger.forge.android.core.ForgeWebView;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.webkit.ValueCallback;

import com.google.gson.JsonElement;

import org.xwalk.core.XWalkResourceClient;
import org.xwalk.core.XWalkUIClient;
import org.xwalk.core.XWalkView;
import org.xwalk.core.internal.XWalkSettings;

public class WebViewProxy {
	ForgeWebView webView = null;
	ModalView parentView = null;
	ForgeActivity activity = null;

	protected final ForgeWebView getWebView() {
		return webView;
	}

	public WebViewProxy(ForgeActivity forgeActivity, ModalView parentView) {
		this.activity = forgeActivity;
		this.parentView = parentView;
	}

	public ForgeWebView register(final ForgeTask task, final String url) {

		// Create webview
		final ForgeWebView forgeWebView = new ForgeWebView(ForgeApp.getActivity(), null);
		this.webView = forgeWebView;

		// Configure ForgeWebView
		XWalkSettings webSettings = forgeWebView.getSettings();
		webSettings.setSupportMultipleWindows(true);
		webSettings.setJavaScriptEnabled(true);
		webSettings.setDomStorageEnabled(true);
		webSettings.setDatabaseEnabled(true);
		webSettings.setGeolocationEnabled(true);
		webSettings.setAllowContentAccess(true);
		webSettings.setAllowFileAccess(true);
		webSettings.setAllowFileAccessFromFileURLs(true);
		webSettings.setAllowUniversalAccessFromFileURLs(true);
		webSettings.setUseWideViewPort(true);
		// TODO webSettings.setBuiltInZoomControls(true); // Make webview behave more like Android browser

		forgeWebView.setUIClient(new XWalkUIClient(webView) {
			@Override
			public boolean onConsoleMessage(XWalkView view, String message, int lineNumber, String sourceId, ConsoleMessageType messageType) {
				if (forgeWebView != null && !message.startsWith(">") && !(message.startsWith("[") && !message.endsWith("]"))) {
					forgeWebView.loadUrl("javascript:console.error('> " + (message + " -- From line " + lineNumber + " of " + sourceId).replace("\\", "\\\\").replace("'", "\\'") + "')");
					ForgeLog.e(message + " -- From line " + lineNumber + " of " + sourceId);
				}
				return true;
			}

			@Override
			public void onPageLoadStarted(XWalkView view, String url) {
				super.onPageLoadStarted(view, url);
				parentView.onLoadStarted(url);
			}

			@Override
			public void onPageLoadStopped(XWalkView view, String url, LoadStatus status) {
				super.onPageLoadStopped(view, url, status);
				parentView.onLoadFinished(url);
			}
		});

		forgeWebView.setResourceClient(new XWalkResourceClient(forgeWebView) {
			@Override
			public void onProgressChanged(XWalkView view, int newProgress) {
				parentView.onProgressChanged(newProgress);
				super.onProgressChanged(view, newProgress);
			}

			@Override
			public void onLoadStarted(XWalkView view, String url) {
				super.onLoadStarted(view, url);
				parentView.onLoadResource(url);
			}

			@Override
			public void onReceivedLoadError(XWalkView view, int errorCode, String description, String failingUrl) {
				parentView.onLoadError(description, failingUrl);
			}

			@Override
			public boolean shouldOverrideUrlLoading(XWalkView view, String url) {
				ForgeLog.i("subView load " + url);

				if (parentView.checkMatchPattern(url)) {
					return true;
				}

				if (url.startsWith("content://" + ForgeApp.getActivity().getApplicationContext().getPackageName())) {
					// Local file, allow the WebView to handle it.
					ForgeLog.i("Webview switching to internal URL: " + url);
					return false;

				} else if (url.startsWith("forge:///")) {
					ForgeLog.i("forge:/// URL loaded in modal view, closing and redirecting main webview.");

					ForgeApp.getActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							parentView.closeModal(ForgeApp.getActivity(), null, false); // TODO Yeaugh
						}
					});
					ForgeApp.getActivity().gotoUrl("content://" + ForgeApp.getActivity().getApplicationContext().getPackageName() + "/src" + url.substring(9));
					return true;

				} else if (url.startsWith("about:")) {
					// Ignore about:* URLs
					return true;

				} else if (url.startsWith("http:") || url.startsWith("https:")) {
					// Normal urls
					// can't use removeJavascriptInterface on 2.x
					forgeWebView.addJavascriptInterface(new Object(), "__forge");
					if (ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").has("trusted_urls")) {
						for (JsonElement whitelistPattern : ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").getAsJsonArray("trusted_urls")) {
							if (ForgeUtil.urlMatchesPattern(url, whitelistPattern.getAsString())) {
								ForgeLog.i("Enabling forge JavaScript API for whitelisted URL in tabs browser: " + url);
								forgeWebView.addJavascriptInterface(new ForgeJSBridge(forgeWebView), "__forge");
								break;
							}
						}
					}
					return false;

				} else {
					// Some other URI scheme, let the phone handle it if
					// possible
					Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
					final PackageManager packageManager = ForgeApp.getActivity().getPackageManager();
					List<ResolveInfo> list = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
					if (list.size() > 0) {
						// Intent exists, invoke it.
						ForgeLog.i("Allowing another Android app to handle URL: " + url);
						ForgeApp.getActivity().startActivity(intent);
					} else {
						ForgeLog.w("Attempted to open a URL which could not be handled: " + url);
					}
					return true;
				}
			}
		});

		// Add JS Bridge for whitelisted remote URLs
		if (ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").has("trusted_urls")) {
			for (JsonElement whitelistPattern : ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").getAsJsonArray("trusted_urls")) {
				if (ForgeUtil.urlMatchesPattern(url, whitelistPattern.getAsString())) {
					ForgeLog.i("Enabling forge JavaScript API for whitelisted URL in tabs browser: " + url);
					forgeWebView.addJavascriptInterface(new ForgeJSBridge(forgeWebView), "__forge");
					break;
				}
			}
		}

		return forgeWebView;
	}

	public void stringByEvaluatingJavaScriptFromString(final ForgeTask task, final String script) {
		ForgeApp.getActivity().runOnUiThread(new Runnable() {

			public void run() {
				try {
					ValueCallback<String> cb = new ValueCallback<String>() {
						@Override
						public void onReceiveValue(String value) {
							if (value == null) {
								task.success();
							} else {
								task.success(value.substring(1, value.length()-1));
							}
						}
					};
					Method method = webView.getClass().getMethod("evaluateJavascript", String.class, ValueCallback.class);
					method.invoke(webView, script, cb);
				} catch (NoSuchMethodException e) {
					ForgeLog.e("Error returning data from Java to JavaScript");
					return;
				} catch (IllegalAccessException e) {
					ForgeLog.e("Error returning data from Java to JavaScript");
					return;
				} catch (IllegalArgumentException e) {
					ForgeLog.e("Error returning data from Java to JavaScript");
					return;
				} catch (InvocationTargetException e) {
					ForgeLog.e("Error returning data from Java to JavaScript");
					return;
				}
			}
		});

	}

}
