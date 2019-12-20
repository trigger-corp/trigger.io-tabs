//
//  tabs_WKWebViewDelegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_WKWebViewDelegate.h"

#import "tabs_LoginAlertView.h"

#define WebKitErrorFrameLoadInterruptedByPolicyChange 102


@implementation tabs_WKWebViewDelegate

#pragma mark Life Cycle

+ (tabs_WKWebViewDelegate*) withViewController:(tabs_WKWebViewController *)viewController {
    tabs_WKWebViewDelegate *me = [[tabs_WKWebViewDelegate alloc] init];
    if (me != nil) {
        me.viewController = viewController;
        me.hasLoaded = NO;
    }
    return me;
}


#pragma mark WKNavigationDelegate

- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    NSURL *url = navigationAction.request.URL;
    if ([self matchesPattern:url]) {
        [ForgeLog w:[NSString stringWithFormat:@"Encountered url matching pattern, closing the tab now: %@", url]];
        self.viewController.result = @{
            @"url": [url absoluteString],
            @"userCancelled": [NSNumber numberWithBool:NO]
        };
        [self.viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    if (![url.scheme hasPrefix:@"http"] && [[UIApplication sharedApplication]openURL:url]) {
        [ForgeLog w:[NSString stringWithFormat:@"Encountered custom scheme, opening it externally: %@", url]];
        [[UIApplication sharedApplication]openURL:url];
        return decisionHandler(WKNavigationActionPolicyCancel);
    }

    return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    
    NSURLResponse* response = [navigationResponse response];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
       NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) [navigationResponse response];
       //create cookie array from http response
        NSDictionary* allHeaderFields = [httpResponse allHeaderFields];
        NSURL* url = [httpResponse URL];
       NSArray* httpCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:allHeaderFields forURL:url];
       //iterate over each one and store them
       for(NSHTTPCookie* cookie in httpCookies)
       {
         //group identifier is important and it should be created in the apple developer portal
         [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:@"group.com.yourorg.*"] setCookie:cookie];
       }
    }
    
    return decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.viewController.toolBar webView:webView didStartProvisionalNavigation:navigation];

    if (self.viewController.title == nil || [self.viewController.title isEqualToString:@""]) {
        self.viewController.navigationBarTitle.title =@"";
    }

    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadStarted", self.viewController.task.callid] withParam:@{@"url": webView.URL.absoluteString}];
}


- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (self.hasLoaded == NO) {
        [[ForgeApp sharedApp] nativeEvent:@selector(firstWebViewLoad) withArgs:@[]];
    }
    self.hasLoaded = YES;

    [self.viewController.toolBar webView:webView didFinishNavigation:navigation];

    if (self.viewController.title == nil || [self.viewController.title isEqualToString:@""]) {
        [webView evaluateJavaScript:@"document.title" completionHandler:^(id result, NSError *error) {
            if (!error) {
                self.viewController.navigationBarTitle.title = result;
            }
        }];
    }

    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadFinished", self.viewController.task.callid] withParam:@{@"url": webView.URL.absoluteString}];
}


- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [ForgeLog w:[NSString stringWithFormat:@"WKWebViewDelegate didFailProvisionalNavigation error: %@", error]];
    [self.viewController.toolBar webView:webView didFailProvisionalNavigation:navigation withError:error];

    // URL is not always set if navigation failed
    NSString *url = webView.URL.absoluteString;
    if (url == nil) {
        url = error.userInfo[NSURLErrorFailingURLStringErrorKey];
        self.viewController.failingURL = url;
    }

    if (error.code == NSURLErrorNotConnectedToInternet) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Error loading"
                             message:@"No Internet connection available."
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController presentViewController:alert animated:YES completion:nil];
        });

    } else if ([error.domain isEqualToString:@"WebKitErrorDomain"] &&
                error.code == WebKitErrorFrameLoadInterruptedByPolicyChange) {
        NSURL *failedRequestURL = [self getFailedUrlFromError:error];

        if (failedRequestURL != nil) {
            // If we haven't done yet, we retry to load the failed url
            // Note: The 102 error can happen for various reasons, so we want to retry first to make sure we really can't open it "inline"
            if (![failedRequestURL.absoluteString isEqualToString:_retryURL.absoluteString]) {
                _retryURL = failedRequestURL;
                [ForgeLog w:[NSString stringWithFormat:@"Retry to load url: %@", failedRequestURL]];
                [self.viewController.webView loadRequest:[NSURLRequest requestWithURL:failedRequestURL]];

            // Retry failed, determine if the system can deal with the it. If so, open it with the appropriate application
            // Example: ics, vcf -> Calendar
            } else if (![self matchesPattern:failedRequestURL] && [[UIApplication sharedApplication]canOpenURL:failedRequestURL]) {
               [ForgeLog w:[NSString stringWithFormat:@"Open url by external app: %@", failedRequestURL]];
               [[UIApplication sharedApplication]openURL:failedRequestURL];
            }
        }
    } else {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadError", self.viewController.task.callid] withParam:@{
            @"url": url,
            @"description": error.localizedDescription
        }];
    }
}

-(NSURL*)getFailedUrlFromError:(NSError *)error
{
    id errorUserInfoDict=[error userInfo];
    
    if (errorUserInfoDict == nil || ![errorUserInfoDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if ([errorUserInfoDict objectForKey:@"NSErrorFailingURLKey"] == nil) {
        return nil;
    }
    
    return [errorUserInfoDict objectForKey:@"NSErrorFailingURLKey"];
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [ForgeLog w:[NSString stringWithFormat:@"WKWebViewDelegate didFailNavigation error: %@", error]];
    [self.viewController.toolBar webView:webView didFailNavigation:navigation withError:error];
}


- (void) webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
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

- (void) userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"forge"]) {
        [ForgeLog d:[NSString stringWithFormat:@"Unknown native call: %@ -> %@", message.name, message.body]];
        return;
    }

    NSURL *url = message.webView.URL;
    if (![ForgeApp.sharedApp.viewController isWhiteListedURL:url]) {
        [ForgeLog w:[NSString stringWithFormat:@"Blocking execution of script for untrusted URL: %@", url]];
        return;
    }

    [ForgeLog d:[NSString stringWithFormat:@"Native call: %@", message.body]];
    [BorderControl runTask:message.body forWebView:message.webView];
}


#pragma mark Helpers

- (BOOL) matchesPattern:(NSURL*)url {
    if (self.viewController.pattern == nil) {
        return NO;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.viewController.pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSString *urlStr = [url absoluteString];

    return [regex numberOfMatchesInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])] > 0;
}

@end
