package io.trigger.forge.android.modules.tabs;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeJSBridge;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeTask;
import io.trigger.forge.android.core.ForgeUtil;
import io.trigger.forge.android.core.ForgeWebView;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.google.gson.JsonElement;

public class WebViewProxy {
	public ForgeWebView webView = null; // TODO private
	ModalView parentView = null; // TODO better name e.g. parentView
	ForgeActivity activity = null;

	public WebViewProxy(ForgeActivity forgeActivity, ModalView parentView) {
		activity = forgeActivity;
		this.parentView = parentView;
		//webView = new ForgeWebView(ForgeApp.getActivity());
	}

	public ForgeWebView register(final ForgeTask task, final String url) {
		// Create webview
		final ForgeWebView forgeWebView = new ForgeWebView(activity);
		// Save static reference - TODO lose one of these surely?
		webView = forgeWebView;

		// Configure ForgeWebView
		WebSettings webSettings = forgeWebView.getSettings();
		webSettings.setJavaScriptEnabled(true);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR_MR1) {
			webSettings.setDomStorageEnabled(true);
		}
		webSettings.setGeolocationEnabled(true);
		webSettings.setBuiltInZoomControls(true); // Make webview behave more like Android browser
		webSettings.setUseWideViewPort(true);     // Make webview behave more like Android browser

		forgeWebView.setWebChromeClient(new WebChromeClient() {
			@Override
			public void onProgressChanged(WebView view, int newProgress) {
				parentView.onProgressChanged(newProgress);
				super.onProgressChanged(view, newProgress);
			}
		});

		forgeWebView.setWebViewClient(new WebViewClient() {

			@Override
			public void onLoadResource(WebView view, String url) {
				super.onLoadResource(view, url);
				parentView.onLoadResource(url);
			}

			@Override
			public void onPageStarted(WebView view, String url, Bitmap favicon) {
				super.onPageStarted(view, url, favicon);
				parentView.onLoadStarted(url);
			}

			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				parentView.onLoadFinished(url);
			}

			@Override
			public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
				parentView.onLoadError(description, failingUrl);
			}

			@Override
			public boolean shouldOverrideUrlLoading(WebView view, String url) {
				ForgeLog.i("subView load " + url);
				if (parentView.checkMatchPattern(url)) { // TODO yeaugh
					return true;
				}

				if (url.startsWith("forge:///")) {
					ForgeLog.i("forge:/// URL loaded in modal view, closing and redirecting main webview.");
					ForgeApp.getActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							parentView.closeModal(ForgeApp.getActivity(), null, false); // TODO Yaugh
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
					// TODO we need a DummyForgeJSBridge object probably
					// subView.addJavascriptInterface(new Object(), "__forge");
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

		// Add JSBridge for whitelisted remote URLs
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
		if (Build.VERSION.SDK_INT >= 19 /* KITKAT */) {
			ForgeApp.getActivity().runOnUiThread(new Runnable() {

				public void run() {
					try {
						ValueCallback<String> cb = new ValueCallback<String>() {
							@Override
							public void onReceiveValue(String value) {
								if (value == null) {
									task.success();
								} else {
									task.success(value.substring(1, value.length() - 1));
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
		} else {
			Object wvObj = webView;
			try {
				Field f = wvObj.getClass().getDeclaredField("mProvider");
				f.setAccessible(true);
				wvObj = f.get(wvObj);
			} catch (NoSuchFieldException e) {
			} catch (IllegalArgumentException e) {
				return;
			} catch (IllegalAccessException e) {
				return;
			}

			try {
				Field f = wvObj.getClass().getDeclaredField("mWebViewCore");
				f.setAccessible(true);
				wvObj = f.get(wvObj);

				Field eventHubField = wvObj.getClass().getDeclaredField("mEventHub");
				eventHubField.setAccessible(true);
				Object eventHub = eventHubField.get(wvObj);
				@SuppressWarnings("rawtypes")
				Class eventHubClass = eventHub.getClass();

				Field handlerField = eventHubClass.getDeclaredField("mHandler");
				handlerField.setAccessible(true);
				Handler handler = (Handler) handlerField.get(eventHub);

				Field frameField = wvObj.getClass().getDeclaredField("mBrowserFrame");
				frameField.setAccessible(true);
				final Object browserFrame = frameField.get(wvObj);

				final Method callJS = browserFrame.getClass().getMethod("stringByEvaluatingJavaScriptFromString", String.class);

				handler.post(new Runnable() {
					@Override
					public void run() {
						try {
							String result = (String) callJS.invoke(browserFrame, script);
							if (result == null) {
								task.success();
							} else {
								task.success(result);
							}
						} catch (IllegalArgumentException e) {
						} catch (IllegalAccessException e) {
						} catch (InvocationTargetException e) {
						}
					}
				});
			} catch (NoSuchFieldException e) {
				return;
			} catch (IllegalArgumentException e) {
				return;
			} catch (IllegalAccessException e) {
				return;
			} catch (NoSuchMethodException e) {
				return;
			} catch (NullPointerException e) {
				return;
			}
		}
	}

	protected final ForgeWebView getWebView() {
		return webView;
	}

}