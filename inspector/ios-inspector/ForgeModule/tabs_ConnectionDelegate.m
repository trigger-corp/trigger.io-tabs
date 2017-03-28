//
//  tabs_LoginDialogDelegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/03/16.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "tabs_ConnectionDelegate.h"

#pragma mark - ConnectionDelegate

@implementation ConnectionDelegate

- (ConnectionDelegate*) initWithModalView:(tabs_modalWebViewController*)newModalInstance webView:(UIWebView *)newWebView {
    if (self = [super init]) {
        modalInstance = newModalInstance;
        webView = newWebView;
        // "retain"
        me = self;
    }

    i8n.title = @"Log in to %host%";
    i8n.usernameHint = @"Login";
    i8n.passwordHint = @"Password";
    i8n.loginButton = @"Log In";
    i8n.cancelButton = @"Cancel";

    closeTabOnCancel = NO;
    
    _basic_authorized = NO;
    _basic_authorized_failed = NO;
    _basic_authorized_did_ask = NO;
    _basic_authorized_embedded = NO;

    return self;
}


- (void) releaseDelegate {
    me = nil;
}


- (BOOL)handleRequest:(NSURLRequest *)request
{
    NSString *requestURL = [[request URL] absoluteString];

    [ForgeLog d:[NSString stringWithFormat:@"Invocation: ConnectionDelegate::handleRequest %@ authorized: %d asked: %d", requestURL, _basic_authorized, _basic_authorized_did_ask]];

    // TODO API method to disable basicAuth support
    // if (disabled) {
    //     return YES;
    // }

    // assume requests coming through while webview is loading are embedded content
    if (webView.isLoading) {
        [ForgeLog d:@"Returning ConnectionDelegate::handleRequest YES - embedded content"];
        _basic_authorized = YES;
        _basic_authorized_embedded = YES;
        return YES;
    }

    // whitelist display of the basic_auth unauthorized message
    if ([requestURL isEqualToString:@"about:blank"]) {
        NSLog(@"about:blank");
        return YES;
    }

    // this request has not yet been checked for basic auth, check it
    if (_basic_authorized == NO) {
        _basic_request = request;
        _basic_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [ForgeLog d:@"Returning ConnectionDelegate::handleRequest NO - not authorized"];
        return NO;
    }

    // sometimes preceding pages did not have auth so we cannot assume subsequent requests will also be authed
    if (_basic_authorized_embedded == NO && _basic_authorized_did_ask == NO) {
        _basic_authorized = NO; // reset basic auth for next request
    }

    [ForgeLog d:@"Returning ConnectionDelegate::handleRequest YES - we are authorized"];

    return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection*)connection;
{
    [ForgeLog d:@"Received callback: ConnectionDelegate::connectionShouldUseCredentialStorage"];
    return YES;
}


- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [ForgeLog d:[NSString stringWithFormat:@"Received callback: ConnectionDelegate::willSendRequestForAuthenticationChallenge %@ authorized: %d embedded: %d", [challenge.protectionSpace host], _basic_authorized, _basic_authorized_embedded]];
    [ForgeLog d:[NSString stringWithFormat:@"  Error: %@", challenge.error]];                                  // NSError
    [ForgeLog d:[NSString stringWithFormat:@"  Failure Response: %@", challenge.failureResponse]];             // NSURLResponse
    [ForgeLog d:[NSString stringWithFormat:@"  Previous Failure Count: %ld", challenge.previousFailureCount]]; // int
    [ForgeLog d:[NSString stringWithFormat:@"  Proposed Credential: %@", challenge.proposedCredential]];       // NSURLCredential
    [ForgeLog d:[NSString stringWithFormat:@"  Protection Space: %@", challenge.protectionSpace]];             // NSURLProtectionSpace
    [ForgeLog d:[NSString stringWithFormat:@"    protocol = %@", [[challenge protectionSpace] protocol]]];
    [ForgeLog d:[NSString stringWithFormat:@"    realm = %@", [[challenge protectionSpace] realm]]];
    [ForgeLog d:[NSString stringWithFormat:@"    authenticationMethod = %@", [[challenge protectionSpace] authenticationMethod]]];
    [ForgeLog d:[NSString stringWithFormat:@"  Sender: %@", challenge.sender]];                                // NSURLAuthenticationChallengeSender

    // get challenge information
    NSString *host = [challenge.protectionSpace host];
    NSString *status = @"";
    NSString *server = @"";
    if ([challenge.failureResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse*)challenge.failureResponse;
        status = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
        server = [response.allHeaderFields valueForKey:@"Server"];
    }

    // check that it's basic auth and fall back to default handling if it's not
    if ([[challenge protectionSpace] authenticationMethod] != NSURLAuthenticationMethodHTTPBasic) {
        NSString *message = [NSString stringWithFormat:@"Unsupported authentication method: %@", [[challenge protectionSpace] authenticationMethod]];
        [ForgeLog d:message];
        _basic_authorized = YES;
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
        return;
    }

    // update state flags
    _basic_authorized = NO;
    _basic_authorized_did_ask = YES;

    // respond to initial challenge
    if ([challenge previousFailureCount] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[i8n.title stringByReplacingOccurrencesOfString:@"%host%" withString:host]
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:i8n.cancelButton
                                              otherButtonTitles:i8n.loginButton, nil];
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [LoginDialogDelegate showAlertView:alert withCallback:^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                _basic_authorized_failed = YES;
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                if (closeTabOnCancel == YES) {
                    [modalInstance cancel:nil];
                }
                return;
            }

            NSString *username = [[alert textFieldAtIndex:0] text];
            NSString *password = [[alert textFieldAtIndex:1] text];
            [[challenge sender] useCredential:[NSURLCredential credentialWithUser:username
                                                                         password:password
                                                                      persistence:NSURLCredentialPersistenceForSession]
                   forAuthenticationChallenge:challenge];
        }];

        return;
    }

    // user supplied invalid credentials
    [ForgeLog d:@"Invalid username/password"];
    _basic_authorized_failed = YES;
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [ForgeLog d:[NSString stringWithFormat:@"Received callback: ConnectionDelegate::didReceiveResponse authorized: %d embeded: %d failed: %d", _basic_authorized, _basic_authorized_embedded, _basic_authorized_failed]];

    _basic_authorized = YES;
    _basic_connection = nil;

    [webView loadRequest:_basic_request];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [ForgeLog d:[NSString stringWithFormat:@"Received callback: ConnectionDelegate::didReceiveData authorized: %d embedded: %d failed: %d", _basic_authorized, _basic_authorized_embedded, _basic_authorized_failed]];

    if (_basic_authorized_failed == YES) {
        _basic_authorized_failed = NO;
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [ForgeLog d:[NSString stringWithFormat:@"Authorization failed: ConnectionDelegate::didReceiveData %@", html]];
        [webView loadHTMLString:html baseURL:nil];
        return;
    }
}


@end



#pragma mark - LoginDialogDelegate

@implementation LoginDialogDelegate
@synthesize callback;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback {
    __block LoginDialogDelegate *delegate = [[LoginDialogDelegate alloc] init];
    alertView.delegate = delegate;
    delegate.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        delegate = nil;
    };
    [alertView show];
}

@end
