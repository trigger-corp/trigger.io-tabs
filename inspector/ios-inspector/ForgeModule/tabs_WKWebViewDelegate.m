//
//  tabs_WKWebViewDelegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_WKWebViewDelegate.h"

#import "tabs_LoginAlertView.h"


@implementation tabs_WKWebViewDelegate

#pragma mark Life Cycle

+ (tabs_WKWebViewDelegate*)withViewController:(tabs_WKWebViewController *)viewController {
    tabs_WKWebViewDelegate *me = [[tabs_WKWebViewDelegate alloc] init];
    if (me != NULL) {
        me.viewController = viewController;
    }
    return me;
}


#pragma mark WKHTTPCookieStoreObserver

//- (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore  API_AVAILABLE(ios(11.0)){
//}


#pragma mark WKNavigationDelegate

/*- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    return [self shouldAllowRequest:navigationAction.request]
        ? decisionHandler(WKNavigationActionPolicyAllow)
        : decisionHandler(WKNavigationActionPolicyCancel);
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [ForgeLog w:[NSString stringWithFormat:@"Webview error: %@", error]];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [ForgeLog w:[NSString stringWithFormat:@"Webview error: %@", error]];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (hasLoaded == NO) {
        // First webview load
        [[ForgeApp sharedApp] nativeEvent:@selector(firstWebViewLoad) withArgs:@[]];
    }
    hasLoaded = YES;
}*/


- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    NSLog(@"didReceiveAuthenticationChallenge -> %@", challenge);

    NSString *method = challenge.protectionSpace.authenticationMethod;
    BOOL isLocalhost = [method isEqualToString:NSURLAuthenticationMethodServerTrust]
                    && [challenge.protectionSpace.host isEqualToString:@"localhost"];
    BOOL isBasicAuth = [method isEqualToString:NSURLAuthenticationMethodDefault]
                    || [method isEqualToString:NSURLAuthenticationMethodHTTPBasic]
                    || [method isEqualToString:NSURLAuthenticationMethodHTTPDigest];

    // support self-signed certificates for localhost
    if (isLocalhost == YES) {
        NSURLCredential * credential = [[NSURLCredential alloc] initWithTrust:[challenge protectionSpace].serverTrust];
        [ForgeLog d:@"[tabs_WKWebView] Trusting self-signed certificate for localhost"];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);

    // support basic auth
    } else if (isBasicAuth == YES) {
        [ForgeLog d:@"[tabs_WKWebView] Handling Basic Auth challenge"];    
        [tabs_LoginAlertView showWithViewController:self.viewController login:^(NSURLCredential * _Nonnull credential) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } cancel:^{
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }];

    // default handling
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}


#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"forge"]) {
        [ForgeLog d:[NSString stringWithFormat:@"Unknown native call: %@ -> %@", message.name, message.body]];
        return;
    }
    [ForgeLog d:[NSString stringWithFormat:@"Native call: %@", message.body]];
    [BorderControl runTask:message.body forWebView:self.viewController.webView];
}


#pragma mark WKUIDelegate


@end
