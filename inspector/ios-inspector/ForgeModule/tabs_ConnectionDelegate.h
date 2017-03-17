//
//  tabs_LoginDialogDelegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/03/16.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

// good overview: http://mikeabdullah.net/history-of-nsurlconnection-auth.html

@interface ConnectionDelegate : NSObject <NSURLConnectionDelegate> {
    UIWebView *webView;

    bool             _basic_authorized;
    bool             _basic_authorized_failed;
    bool             _basic_authorized_unsupported;
    NSURLRequest    *_basic_request;
    NSURLConnection *_basic_connection;

    ConnectionDelegate *me;
}

- (ConnectionDelegate*) initWithWebView:(UIWebView *)newWebView;
- (void) releaseDelegate;

- (BOOL)handleRequest:(NSURLRequest *)request;

@end


@interface LoginDialogDelegate : NSObject<UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong,nonatomic) AlertViewCompletionBlock callback;

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;

@end
