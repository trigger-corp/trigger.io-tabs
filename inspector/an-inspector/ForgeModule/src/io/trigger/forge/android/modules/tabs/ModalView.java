package io.trigger.forge.android.modules.tabs;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.HttpAuthHandler;
import android.webkit.ValueCallback;
import android.webkit.WebView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.IOException;
import java.util.List;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeFile;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeTask;
import io.trigger.forge.android.core.ForgeWebView;
import io.trigger.forge.android.util.BitmapUtil;

public class ModalView {
    public static void openURIAsIntent(Uri uri) {
        // Some other URI scheme, let the phone handle it if
        // possible
        ForgeLog.i("Trying to open URI as intent: " + uri.toString());
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        final PackageManager packageManager = ForgeApp.getActivity().getPackageManager();
        List<ResolveInfo> list = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
        if (list.size() > 0) {
            // Intent exists, invoke it.
            ForgeLog.i("Allowing another Android app to handle URL: " + uri.toString());
            ForgeApp.getActivity().startActivity(intent);
        } else {
            ForgeLog.w("Attempted to open a URL which could not be handled: " + uri.toString());
        }
    }

    // Reference to the last created modal view (for back button, etc)
    static ModalView instance = null;

    public WebViewProxy webViewProxy = null;
    ForgeTask task = null;
    String match_url_pattern = null;

    // UI Elements
    LinearLayout view = null;
    RelativeLayout topbar = null;
    LinearLayout buttonLeft = null;
    LinearLayout buttonRight = null;
    ProgressBar progressBar = null;

    final static int ID_TITLE  = 10;
    final static int ID_BUTTON_LEFT = 11;
    final static int ID_BUTTON_RIGHT = 12;

    public int previousFailureCount = 0;
    public boolean terminateBasicAuthHandling = false;



    // - ACCESSORS ---------------------------------------------------------------------------------

    public final ForgeWebView getWebView() {
        return webViewProxy.getWebView();
    }


    // - LIFECYCLE ---------------------------------------------------------------------------------

    public ModalView() {
        instance = this;
    }

    public void closeModal(final ForgeActivity currentActivity, final String url, boolean cancelled) {
        if (view == null) {
            return;
        }

        final JsonObject result = new JsonObject();
        result.addProperty("url", url);
        result.addProperty("userCancelled", cancelled);
        currentActivity.removeModalView(view, new Runnable() {
            public void run() {
                ForgeApp.event("tabs." + task.callid + ".closed", result);
            }
        });

        if (instance == this) {
            instance = null;
        }
        view = null;
    }

    public void close() {
        ForgeApp.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                closeModal(ForgeApp.getActivity(), getWebView().getUrl(), false);
            }
        });
    }

    public void openModal(final ForgeTask task) {
        this.task = task;
        if (task.params.has("pattern")) {
            this.match_url_pattern = task.params.get("pattern").getAsString();
        }

        task.performUI(new Runnable() {
            public void run() {
                // Parse options
                String url = null;
                String titleText = null;
                String buttonText = null;
                JsonElement buttonIcon = null;
                JsonArray buttonTint = null;
                JsonArray tint = null;
                JsonArray titleTint = null;
                url = task.params.get("url").getAsString();
                if (task.params.has("title")) {
                    titleText = task.params.get("title").getAsString();
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

                ForgeLog.i("Displaying modal view.");

                // Create new view
                view = new LinearLayout(ForgeApp.getActivity());
                view.setOrientation(LinearLayout.VERTICAL);
                view.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
                view.setBackgroundColor(0xFF000000);

                // Add a progressBar bar
                progressBar = new ProgressBar(ForgeApp.getActivity(), null, android.R.attr.progressBarStyleHorizontal);
                progressBar.setMax(100);
                progressBar.setProgress(0);
                progressBar.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 2));
                progressBar.setBackgroundColor(0xFF000000);
                view.addView(progressBar);

                // Get display density
                DisplayMetrics metrics = new DisplayMetrics();
                ForgeApp.getActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);

                // Add a top bar
                topbar = createTopBar(metrics, tint);

                // Create a button
                try {
                    buttonLeft = createButton(metrics, buttonText, buttonIcon, buttonTint);
                    buttonLeft.setId(ID_BUTTON_LEFT);
                } catch (IOException e) {
                    task.error(e.getLocalizedMessage());
                    return;
                }

                // Add button to topbar
                final int requiredSize = Math.round(metrics.density * 32);
                //RelativeLayout.LayoutParams buttonParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);//, requiredSize);
                RelativeLayout.LayoutParams buttonParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, requiredSize);
                buttonParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT, RelativeLayout.TRUE);
                topbar.addView(buttonLeft, buttonParams);

                // Add titleText to topbar
                TextView titleView = createTitle(metrics, titleText, titleTint);
                RelativeLayout.LayoutParams titleParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
                titleParams.addRule(RelativeLayout.RIGHT_OF, buttonLeft.getId());
                topbar.addView(titleView, titleParams);

                // Add topbar to view
                view.addView(topbar);

                // add webview
                webViewProxy = new WebViewProxy(instance);
                final ForgeWebView webView = webViewProxy.register(ForgeApp.getActivity(), url);
                view.addView(webView, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, 1));
                webView.loadUrl(url);

                // Add to the view group and switch
                ForgeApp.getActivity().addModalView(view);
                webView.requestFocus(View.FOCUS_DOWN);

                task.success(task.callid);
            }
        });
    }


    // - WebViewProxy callbacks --------------------------------------------------------------------

    public void onDownloadStart(String url, String userAgent, String contentDisposition, String mimetype, long contentLength) {
        // Don't load the URL in web view for downloadable files.
        webViewProxy.getWebView().stopLoading();
        ForgeLog.i("Received a file download response. Opening URL externally ");
        openURIAsIntent(Uri.parse(url));
    }

    public void onFileUpload(ValueCallback<Uri> uploadMsg) {
        int FILE_CHOOSER_RESULT_CODE=1;
        Intent i = new Intent(Intent.ACTION_GET_CONTENT);
        i.addCategory(Intent.CATEGORY_OPENABLE);
        i.setType("*/*");
        ForgeApp.getActivity().startActivityForResult(
                Intent.createChooser(i, "File Browser"),
                FILE_CHOOSER_RESULT_CODE);
    }

    public void onProgressChanged(int newProgress) {
        progressBar.setProgress(newProgress);
        if (newProgress == 100) {
            progressBar.setVisibility(View.INVISIBLE);
        } else {
            progressBar.setVisibility(View.VISIBLE);
        }
    }

    public void onLoadResource(String url) {
        checkMatchPattern(url);
    }

    public void onLoadStarted(String url) {
        final JsonObject result = new JsonObject();
        result.addProperty("url", url);
        ForgeApp.event("tabs." + task.callid + ".loadStarted", result);
    }

    public void onLoadFinished(String url) {
        final JsonObject result = new JsonObject();
        result.addProperty("url", url);
        ForgeApp.event("tabs." + task.callid + ".loadFinished", result);
    }

    public void onLoadError(String description, String failingUrl) {
        ForgeLog.w("[Forge modal WebView error] " + description);
        final JsonObject result = new JsonObject();
        result.addProperty("url", failingUrl);
        result.addProperty("description", description);
        ForgeApp.event("tabs." + task.callid + ".loadError", result);
    }

    public boolean shouldOverrideUrlLoading(String url) {
        return checkMatchPattern(url);
    }

    private boolean checkMatchPattern(final String url) {
        if (url != null && this.match_url_pattern != null && url.matches(this.match_url_pattern) && view != null) {
            ForgeLog.i("Match pattern hit in modal view, closing and returning current URL.");
            ForgeApp.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    closeModal(ForgeApp.getActivity(), url, false);
                }
            });
            return true;
        }
        return false;
    }

    public boolean onReceivedHttpAuthRequest(final WebView webView, final HttpAuthHandler handler, final String host, final String realm) {
        ForgeLog.i("ModalView::onReceivedHttpAuthRequest");

        // check if basicAuth is enabled
        if (!task.params.has("basicAuth")) {
            ForgeLog.i("ModalView::onReceivedHttpAuthRequest basicAuth disabled 1");
            return true;
        } else if (task.params.get("basicAuth").getAsBoolean() == false) {
            ForgeLog.i("ModalView::onReceivedHttpAuthRequest basicAuth disabled 2");
            return true;
        } else if (instance.terminateBasicAuthHandling == true) {
            return true;
        }

        // check if we're on HTTPS and not set to be insecure for testing purposes
        String url = webView.getUrl();
        boolean insecure = false;
        if (task.params.has("basicAuthConfig")) {
            JsonObject cfg = task.params.getAsJsonObject("basicAuthConfig");
            insecure = cfg.has("insecure") ? cfg.get("insecure").getAsBoolean() : false;
        }
        if (!url.startsWith("https:") && !insecure) {
            ForgeLog.w("Basic Auth is only supported for sites served over https");
            return true;
        }

        // try existing credentials
        String [] storedCredentials = webView.getHttpAuthUsernamePassword(host, realm);
        if (handler.useHttpAuthUsernamePassword() && storedCredentials != null && storedCredentials.length >= 2) {
            ForgeLog.i("ModalView::onReceivedHttpAuthRequest useHttpAuthUsernamePassword is TRUE");
            ForgeLog.i("\tStored credentials are: " + storedCredentials[0] + " " + storedCredentials[1]);
            handler.proceed(storedCredentials[0], storedCredentials[1]);
            return false;
        }

        // prompt user for credentials
        task.performUI(new Runnable() {
            public void run() {

                LoginDialog.Text i8n = new LoginDialog.Text();
                boolean closeTabOnCancel = false;
                boolean retryFailedLogin = false;
                if (task.params.has("basicAuthConfig")) {
                    JsonObject cfg = task.params.getAsJsonObject("basicAuthConfig");
                    i8n.title = cfg.has("titleText") ? cfg.get("titleText").getAsString() : i8n.title;
                    i8n.passwordHint = cfg.has("passwordHintText") ? cfg.get("passwordHintText").getAsString() : i8n.passwordHint;
                    i8n.usernameHint = cfg.has("usernameHintText") ? cfg.get("usernameHintText").getAsString() : i8n.usernameHint;
                    i8n.loginButton = cfg.has("loginButtonText") ? cfg.get("loginButtonText").getAsString() : i8n.loginButton;
                    i8n.cancelButton = cfg.has("cancelButtonText") ? cfg.get("cancelButtonText").getAsString() : i8n.cancelButton;
                    closeTabOnCancel = cfg.has("closeTabOnCancel") ? cfg.get("closeTabOnCancel").getAsBoolean() : false;
                    retryFailedLogin = cfg.has("retryFailedLogin") ? cfg.get("retryFailedLogin").getAsBoolean() : false;
                }

                final LoginDialog dialog = new LoginDialog(ForgeApp.getActivity(), instance, webView, handler, host, realm, i8n, closeTabOnCancel, retryFailedLogin);
                dialog.show();
            }
        });

        return false;
    }


    // - UI Elements -------------------------------------------------------------------------------

    private RelativeLayout createTopBar(DisplayMetrics metrics, JsonArray tint) {
        RelativeLayout topbar = new RelativeLayout(ForgeApp.getActivity());

        // calculate * set topbar sizes
        int requiredSize = Math.round(metrics.density * 50);
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

        return topbar;
    }

    private TextView createTitle(DisplayMetrics metrics, String title, JsonArray titleTint) {
        TextView titleView = new TextView(ForgeApp.getActivity());
        titleView.setId(ID_TITLE);
        if (title != null) {
            titleView.setText(title);
        } else {
            titleView.setText("");
        }
        int titleColor = 0xFF000000;
        if (titleTint != null) {
            titleColor = Color.argb(titleTint.get(3).getAsInt(), titleTint.get(0).getAsInt(), titleTint.get(1).getAsInt(), titleTint.get(2).getAsInt());
        }
        titleView.setTextColor(titleColor);
        titleView.setTextSize(TypedValue.COMPLEX_UNIT_PX, metrics.density * 24);
        titleView.setGravity(Gravity.LEFT);
        titleView.setSingleLine();
        titleView.setEllipsize(TextUtils.TruncateAt.END);

        return titleView;
    }
    private LinearLayout createButton(DisplayMetrics metrics, String buttonText, JsonElement buttonIcon, JsonArray buttonTint) throws IOException {
        return this.createButton(metrics, buttonText, buttonIcon, buttonTint, null);
    }

    private LinearLayout createButton(DisplayMetrics metrics, String buttonText, JsonElement buttonIcon, JsonArray buttonTint, final ForgeTask task) throws IOException {
        LinearLayout button = new LinearLayout(ForgeApp.getActivity());
        button.setLongClickable(true);
        button.setOnTouchListener(new View.OnTouchListener() {
            public boolean onTouch(View v, MotionEvent event) {
                if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
                    if (Build.VERSION.SDK_INT >= 11 /* HONEYCOMB */) {
                        // Highlight
                        v.setAlpha(0.3f);
                    }
                } else if (event.getAction() == android.view.MotionEvent.ACTION_UP) {
                    if (Build.VERSION.SDK_INT >= 11 /* HONEYCOMB */) {
                        // Unhighlight
                        v.setAlpha(1);
                    }

                    if (task != null) {
                        ForgeApp.event("tabs.buttonPressed." + task.callid);
                    } else {
                        // Send event
                        ForgeLog.i("Modal view close button pressed, returning to main webview.");
                        ForgeApp.getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                closeModal(ForgeApp.getActivity(), webViewProxy.webView.getUrl(), true);
                            }
                        });
                    }
                }
                return false;
            }
        });

        int buttonColor = 0xFF1C8DD9;
        if (buttonTint != null) {
            buttonColor = Color.argb(buttonTint.get(3).getAsInt(), buttonTint.get(0).getAsInt(), buttonTint.get(1).getAsInt(), buttonTint.get(2).getAsInt());
        }

        button.setOrientation(LinearLayout.VERTICAL);
        button.setGravity(Gravity.CENTER);

        final int buttonMargin = Math.round(metrics.density * 4);
        if (buttonIcon != null) {
            ImageView image = new ImageView(ForgeApp.getActivity());
            image.setScaleType(ImageView.ScaleType.CENTER);
            Drawable icon;
            ForgeFile buttonFile = new ForgeFile(ForgeApp.getActivity(), buttonIcon);
            String error = "Could not create button from image file: '" +
                    buttonIcon.getAsString() +
                    "' Please check that this file exists in your app's src/config.json directory and that it is a valid PNG file.";
            if (buttonFile == null || buttonFile.fd() == null) {
                throw new IOException(error);
            }
            icon = BitmapUtil.scaledDrawableFromStreamWithTint(ForgeApp.getActivity(), buttonFile.fd().createInputStream(), 0, 32, buttonColor);
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

        return button;
    }

    // - UI API's ----------------------------------------------------------------------------------
    public void addButton(final ForgeTask task, final JsonObject params) {
        task.performUI(new Runnable() {
            public void run() {
                String text = null;
                String position = null;
                JsonElement icon = null;
                JsonArray tint = null;
                if (params.has("text")) {
                    text = params.get("text").getAsString();
                }
                if (params.has("position")) {
                    position = params.get("position").getAsString();
                }
                if (params.has("icon")) {
                    icon = params.get("icon");
                }
                if (params.has("tint")) {
                    tint = params.getAsJsonArray("tint");
                }

                // create button
                DisplayMetrics metrics = new DisplayMetrics();
                ForgeApp.getActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);
                LinearLayout button = null;
                try {
                    button = createButton(metrics, text, icon, tint, task);
                } catch (IOException e) {
                    task.error(e.getLocalizedMessage());
                    return;
                }

                // Add button to left or right of topbar
                final int requiredSize = Math.round(metrics.density * 32);
                RelativeLayout.LayoutParams buttonParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, requiredSize);
                if (position != null && position.equalsIgnoreCase("right")) {
                    if (buttonRight != null) {
                        topbar.removeView(buttonRight);
                        buttonRight = null;
                    }
                    button.setId(ID_BUTTON_RIGHT);
                    buttonParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT, RelativeLayout.TRUE);
                    buttonRight = button;
                } else {
                    if (buttonLeft != null) {
                        topbar.removeView(buttonLeft);
                        buttonLeft = null;
                    }
                    button.setId(ID_BUTTON_LEFT);
                    buttonParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT, RelativeLayout.TRUE);
                    buttonLeft = button;
                }

                // layout buttons relative to title
                RelativeLayout.LayoutParams titleParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
                if (buttonLeft != null) {
                    titleParams.addRule(RelativeLayout.RIGHT_OF, buttonLeft.getId());
                }
                if (buttonRight != null) {
                    titleParams.addRule(RelativeLayout.LEFT_OF, buttonRight.getId());
                }
                topbar.findViewById(ID_TITLE).setLayoutParams(titleParams);
                topbar.addView(button, buttonParams);

                task.success(task.callid);
            }
        });
    }

    public void removeButtons(final ForgeTask task) {
        task.performUI(new Runnable() {
            public void run() {

                if (buttonLeft != null) {
                    topbar.removeView(buttonLeft);
                    buttonLeft = null;
                }
                if (buttonRight != null) {
                    topbar.removeView(buttonRight);
                    buttonRight = null;
                }

                RelativeLayout.LayoutParams titleParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
                topbar.findViewById(ID_TITLE).setLayoutParams(titleParams);

                task.success();
            }
        });
    }


}