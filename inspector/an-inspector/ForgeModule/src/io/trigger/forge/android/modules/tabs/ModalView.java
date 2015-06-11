package io.trigger.forge.android.modules.tabs;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeFile;
import io.trigger.forge.android.core.ForgeJSBridge;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeTask;
import io.trigger.forge.android.core.ForgeUtil;
import io.trigger.forge.android.util.BitmapUtil;

import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.text.TextUtils.TruncateAt;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

public class ModalView {
	// Reference to the last created modal view (for back button, etc)
	static ModalView lastModal = null;
	WebView webView = null;
	View view = null;
	ForgeTask task = null;

	public ModalView() {
		lastModal = this;
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
							String result = (String)callJS.invoke(browserFrame, script);
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

	public void closeModal(final ForgeActivity currentActivity, final String url, boolean cancelled) {
		if (view == null) {
			return;
		}

		final JsonObject result = new JsonObject();
		result.addProperty("url", url);
		result.addProperty("userCancelled", cancelled);

		final View savedView = view;
		currentActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				currentActivity.removeModalView(savedView, new Runnable() {
					public void run() {
						ForgeApp.event("tabs."+task.callid+".closed", result);
					}
				});
			}
		});
		
		if (lastModal == this) {
			lastModal = null;
		}

		view = null;
	}

	public void openModal(final ForgeTask task) {
		this.task = task;
		task.performUI(new Runnable() {
			public void run() {
				ForgeLog.i("Displaying modal view.");

				// Get settings
				String url = null;
				String pattern = null;
				String title = null;
				String buttonText = null;
				JsonElement buttonIcon = null;
				JsonArray buttonTint = null;
				JsonArray tint = null;
				JsonArray titleTint = null;
				url = task.params.get("url").getAsString();
				if (task.params.has("pattern")) {
					pattern = task.params.get("pattern").getAsString();
				}
				if (task.params.has("title")) {
					title = task.params.get("title").getAsString();
				}
				if (task.params.has("buttonText")) {
					buttonText = task.params.get("buttonText").getAsString();
				}
				if (task.params.has("buttonIcon")) {
					buttonIcon = task.params.get("buttonIcon");
				}
				if (task.params.has("tint")) {
					tint = task.params.getAsJsonArray("tint");
				}
				if (task.params.has("titleTint")) {
					titleTint = task.params.getAsJsonArray("titleTint");
				}
				if (task.params.has("buttonTint")) {
					buttonTint = task.params.getAsJsonArray("buttonTint");
				}

				// Create webview
				final WebView subView = new WebView(ForgeApp.getActivity());
				// Save static reference
				webView = subView;

				// Create new layout
				LinearLayout layout = new LinearLayout(ForgeApp.getActivity());
				view = layout;
				layout.setOrientation(LinearLayout.VERTICAL);
				layout.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
				layout.setBackgroundColor(0xFF000000);

				// Add a progress bar
				final ProgressBar progress = new ProgressBar(ForgeApp.getActivity(), null, android.R.attr.progressBarStyleHorizontal);
				progress.setMax(100);
				progress.setProgress(0);
				progress.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 2));
				progress.setBackgroundColor(0xFF000000);
				layout.addView(progress);

				// Add a top bar
				RelativeLayout topbar = new RelativeLayout(ForgeApp.getActivity());
				//topbar.setOrientation(LinearLayout.HORIZONTAL);

				int size = 50;
				DisplayMetrics metrics = new DisplayMetrics();
				ForgeApp.getActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);
				int requiredSize = Math.round(metrics.density * size);
				final int margin = Math.round(metrics.density * 8);

				topbar.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, requiredSize));
				topbar.setGravity(Gravity.CENTER);

				int color = 0xFFEEEEEE;
				if (tint != null) {
					color = Color.argb(tint.get(3).getAsInt(), tint.get(0).getAsInt(), tint.get(1).getAsInt(), tint.get(2).getAsInt());
				}
				ColorDrawable bgColor = new ColorDrawable(color);
				topbar.setBackgroundDrawable(bgColor);
				topbar.setPadding(margin, 0, margin, 0);

				// Create default title
				TextView titleView = new TextView(ForgeApp.getActivity());
				titleView.setId(2);
				if (title != null) {
					titleView.setText(title);
				}
				int titleColor = 0xFF000000;
				if (titleTint != null) {
					titleColor = Color.argb(titleTint.get(3).getAsInt(), titleTint.get(0).getAsInt(), titleTint.get(1).getAsInt(), titleTint.get(2).getAsInt());
				}
				titleView.setTextColor(titleColor);
				titleView.setTextSize(TypedValue.COMPLEX_UNIT_PX, metrics.density * 24);
				titleView.setGravity(Gravity.CENTER);
				titleView.setSingleLine();
				titleView.setEllipsize(TruncateAt.END);		
				
				// Create a button
				size = 32;
				final int buttonMargin = Math.round(metrics.density * 4);
				requiredSize = Math.round(metrics.density * size);

				LinearLayout button = new LinearLayout(ForgeApp.getActivity());
				button.setId(1);
				button.setLongClickable(true);
				button.setOnTouchListener(new OnTouchListener() {
					public boolean onTouch(View v, MotionEvent event) {
						if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
							// Highlight
							v.setAlpha(0.3f);
						} else if (event.getAction() == android.view.MotionEvent.ACTION_UP) {
							// Unhighlight
							v.setAlpha(1);

							// Send event
							ForgeLog.i("Modal view close button pressed, returning to main webview.");
							closeModal(ForgeApp.getActivity(), subView.getUrl(), true);
						}
						return false;
					}
				});
				
				int buttonColor = 0xFF1C8DD9;
				if (buttonTint != null) {
					buttonColor = Color.argb(buttonTint.get(3).getAsInt(), buttonTint.get(0).getAsInt(), buttonTint.get(1).getAsInt(), buttonTint.get(2).getAsInt());
				}

				button.setOrientation(LinearLayout.VERTICAL);

				if (buttonIcon != null) {
					ImageView image = new ImageView(ForgeApp.getActivity());
					image.setScaleType(ImageView.ScaleType.CENTER);
					Drawable icon;
					try {
						icon = BitmapUtil.scaledDrawableFromStreamWithTint(ForgeApp.getActivity(), new ForgeFile(ForgeApp.getActivity(), buttonIcon).fd().createInputStream(), 0, 32, buttonColor);
					} catch (IOException e) {
						task.error(e);
						return;
					}
					image.setImageDrawable(icon);
					image.setPadding(buttonMargin, 0, buttonMargin, 0);
					button.addView(image);
				} else {
					TextView text = new TextView(ForgeApp.getActivity());
					if (buttonText != null) {
						text.setText(buttonText);
					} else {
						text.setText("Close");
					}
					text.setTextColor(buttonColor);
					text.setTextSize(TypedValue.COMPLEX_UNIT_PX, metrics.density * 18);
					text.setGravity(Gravity.CENTER);
					text.setPadding(buttonMargin * 2, buttonMargin, buttonMargin * 2, buttonMargin);
					button.addView(text);
				}
				
				// Add button and title text to topbar
				
				RelativeLayout.LayoutParams buttonParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, requiredSize);
				buttonParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT, RelativeLayout.TRUE);				
				button.setGravity(Gravity.CENTER);
				topbar.addView(button, buttonParams);
				
				RelativeLayout.LayoutParams titleParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
				titleParams.addRule(RelativeLayout.RIGHT_OF, button.getId());				
				topbar.addView(titleView, titleParams);
				
				layout.addView(topbar);

				layout.addView(subView, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, 1));

				WebSettings webSettings = subView.getSettings();
				webSettings.setJavaScriptEnabled(true);
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR_MR1) {
					webSettings.setDomStorageEnabled(true);
				}
				webSettings.setGeolocationEnabled(true);

				// Make webview behave more like Android browser
				webSettings.setBuiltInZoomControls(true);
				webSettings.setUseWideViewPort(true);

				final String fPattern = pattern;

				subView.setWebChromeClient(new WebChromeClient() {
					@Override
					public void onProgressChanged(WebView view, int newProgress) {
						progress.setProgress(newProgress);
						if (newProgress == 100) {
							progress.setVisibility(View.INVISIBLE);
						} else {
							progress.setVisibility(View.VISIBLE);
						}
						super.onProgressChanged(view, newProgress);
					}
				});
				subView.setWebViewClient(new WebViewClient() {
					@Override
					public void onPageStarted(WebView view, String url, Bitmap favicon) {
						super.onPageStarted(view, url, favicon);
						final JsonObject result = new JsonObject();
						result.addProperty("url", url);

						ForgeApp.event("tabs."+task.callid+".loadStarted", result);
					}
					@Override
					public void onPageFinished(WebView view, String url) {
						super.onPageFinished(view, url);
						
						final JsonObject result = new JsonObject();
						result.addProperty("url", url);

						ForgeApp.event("tabs."+task.callid+".loadFinished", result);
					}
					@Override
					public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
						ForgeLog.w("[Forge modal WebView error] " + description);
						
						final JsonObject result = new JsonObject();
						result.addProperty("url", failingUrl);
						result.addProperty("description", description);

						ForgeApp.event("tabs."+task.callid+".loadError", result);
					}

					@Override
					public boolean shouldOverrideUrlLoading(WebView view, String url) {
						ForgeLog.i("subView load " + url);

						if (checkMatchPattern(url)) {
							return true;
						}

						if (url.startsWith("forge:///")) {
							ForgeLog.i("forge:/// URL loaded in modal view, closing and redirecting main webview.");

							closeModal(ForgeApp.getActivity(), null, false);
							ForgeApp.getActivity().gotoUrl("content://" + ForgeApp.getActivity().getApplicationContext().getPackageName() + "/src" + url.substring(9));
							return true;
						} else if (url.startsWith("about:")) {
							// Ignore about:* URLs
							return true;
						} else if (url.startsWith("http:") || url.startsWith("https:")) {
							// Normal urls
							// can't use removeJavascriptInterface on 2.x
							subView.addJavascriptInterface(new Object(), "__forge");
							if (ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").has("trusted_urls")) {
								for (JsonElement whitelistPattern : ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").getAsJsonArray("trusted_urls")) {
									if (ForgeUtil.urlMatchesPattern(url, whitelistPattern.getAsString())) {
										ForgeLog.i("Enabling forge JavaScript API for whitelisted URL in tabs browser: "+url);
										subView.addJavascriptInterface(new ForgeJSBridge(subView), "__forge");
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

					@Override
					public void onLoadResource(WebView view, String url) {
						String viewUrl = view.getUrl();
						checkMatchPattern(viewUrl);
					}

					private boolean checkMatchPattern(String url) {
						if (url != null && fPattern != null && url.matches(fPattern) && view != null) {
							ForgeLog.i("Match pattern hit in modal view, closing and returning current URL.");
							closeModal(ForgeApp.getActivity(), url, false);
							return true;
						}
						return false;
					}
				});

				// Check for whitelisted remote URLs
				if (ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").has("trusted_urls")) {
					for (JsonElement whitelistPattern : ForgeApp.appConfig.getAsJsonObject("core").getAsJsonObject("general").getAsJsonArray("trusted_urls")) {
						if (ForgeUtil.urlMatchesPattern(url, whitelistPattern.getAsString())) {
							ForgeLog.i("Enabling forge JavaScript API for whitelisted URL in tabs browser: "+url);
							subView.addJavascriptInterface(new ForgeJSBridge(subView), "__forge");
							break;
						}
					}
				}
				
				subView.loadUrl(url);

				// Add to the view group and switch
				ForgeApp.getActivity().addModalView(layout);
				subView.requestFocus(View.FOCUS_DOWN);
				
				task.success(task.callid);
			}
		});
	}
	
	public void close() {
		closeModal(ForgeApp.getActivity(), webView.getUrl(), false);
	}
}