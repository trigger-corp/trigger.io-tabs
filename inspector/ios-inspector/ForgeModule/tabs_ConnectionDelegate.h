//
//  tabs_ConnectionDelegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/03/16.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "tabs_modalWebViewController.h"

// good overview: http://mikeabdullah.net/history-of-nsurlconnection-auth.html

@interface ConnectionDelegate : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    NSMutableDictionary<NSString*, NSNumber*> *authorizationCache;
    bool _in_basic_auth_flow;
    bool _basic_authorized_failed;
    NSString *pattern;

    NSHTTPURLResponse* httpResponse;
    NSMutableData *receivedData;

    UIWebView *webView;
    tabs_modalWebViewController *modalInstance;
    ConnectionDelegate *me;

@public
    struct Text {
        __unsafe_unretained NSString *title;
        __unsafe_unretained NSString *usernameHint;
        __unsafe_unretained NSString *passwordHint;
        __unsafe_unretained NSString *loginButton;
        __unsafe_unretained NSString *cancelButton;
    } i8n;
    bool closeTabOnCancel;
    bool useCredentialStorage;
    bool verboseLogging;
    bool retryFailedLogin;
}

- (ConnectionDelegate*) initWithModalView:(tabs_modalWebViewController*)newModalInstance webView:(UIWebView*)newWebView pattern:(NSString*)newPattern;
- (void) releaseDelegate;

- (BOOL)handleRequest:(NSURLRequest *)request;

@end


@interface LoginDialogDelegate : NSObject<UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong,nonatomic) AlertViewCompletionBlock callback;

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;

@end
