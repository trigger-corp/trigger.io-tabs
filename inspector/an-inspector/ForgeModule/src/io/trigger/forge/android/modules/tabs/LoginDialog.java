package io.trigger.forge.android.modules.tabs;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.text.InputType;
import android.webkit.HttpAuthHandler;
import android.webkit.WebView;
import android.widget.EditText;
import android.widget.LinearLayout;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;

public class LoginDialog {
    private AlertDialog.Builder builder;

    public static class Text {
        public String title = "Log in to %host%";
        public String usernameHint = "Login";
        public String passwordHint = "Password";
        public String loginButton = "Log In";
        public String cancelButton = "Cancel";
    };

    public LoginDialog(final Activity context, final ModalView modalInstance, final WebView webView, final HttpAuthHandler handler, final String host, final String realm, final Text i8n, final boolean closeTabOnCancel, final boolean retryFailedLogin) {
        LinearLayout layout = new LinearLayout(context);
        final EditText usernameInput = new EditText(context);
        final EditText passwordInput = new EditText(context);
        usernameInput.setHint(i8n.usernameHint);
        usernameInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        passwordInput.setHint(i8n.passwordHint);
        passwordInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS | InputType.TYPE_TEXT_VARIATION_PASSWORD);

        layout.setOrientation(LinearLayout.VERTICAL);
        layout.addView(usernameInput);
        layout.addView(passwordInput);

        builder = new AlertDialog.Builder(context);
        builder.setTitle(i8n.title.replace("%host%", host));
        builder.setView(layout);
        builder.setPositiveButton(i8n.loginButton, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String username = usernameInput.getText().toString();
                String password = passwordInput.getText().toString();
                webView.setHttpAuthUsernamePassword(host, realm, username, password);
                if (handler != null) {
                    handler.proceed(username, password);
                }
                if (retryFailedLogin && modalInstance.previousFailureCount < 3) {
                    modalInstance.previousFailureCount++; // try again
                } else {
                    modalInstance.previousFailureCount = 0;
                    modalInstance.terminateBasicAuthHandling = true;
                }
            }
        });
        builder.setNegativeButton(i8n.cancelButton, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                handler.cancel();
                if (closeTabOnCancel == true && modalInstance != null) {
                    modalInstance.closeModal(ForgeApp.getActivity(), webView.getUrl(), true);
                }
            }
        });
    }

    public void show() {
        builder.create().show();
    }
}
