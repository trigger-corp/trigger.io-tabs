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

- (ConnectionDelegate*) initWithWebView:(UIWebView *)newWebView {
    if (self = [super init]) {
        webView = newWebView;
        // "retain"
        me = self;
    }
    
    _basic_authorized = NO;
    _basic_authorized_failed = NO;
    _basic_authorized_unsupported = NO;

    return self;
}


- (void) releaseDelegate {
    me = nil;
}


- (BOOL)handleRequest:(NSURLRequest *)request
{
    NSString *requestURL = [[request URL] absoluteString];

    [ForgeLog d:[NSString stringWithFormat:@"Invocation: ConnectionDelegate::handleRequest %@", requestURL]];

    // TODO API method to disable basicAuth support
    // if (disabled) {
    //     return YES;
    // }

    // don't try to handle subsequent requests for sites with unsupported auth protocols
    if (_basic_authorized_unsupported == YES) {
        return YES;
    }

    // whitelist display of the basic_auth unauthorized message
    if ([requestURL isEqualToString:@"about:blank"]) {
        NSLog(@"about:blank");
        return YES;
    }

    //
    if (_basic_authorized == NO) {
        _basic_request = request;
        _basic_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [ForgeLog d:@"Returning ConnectionDelegate::handleRequest NO"];
        return NO;
    }

    [ForgeLog d:@"Returning ConnectionDelegate::handleRequest YES"];
    _basic_authorized = NO; // reset basic auth for next request

    return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection*)connection;
{
    [ForgeLog d:@"Received callback: ConnectionDelegate::connectionShouldUseCredentialStorage"];
    return NO;
}


- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    _basic_authorized = NO;

    [ForgeLog d:@"Received callback: ConnectionDelegate::willSendRequestForAuthenticationChallenge"];
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
        NSString *html = [NSString stringWithFormat:@"<html>"
                                                     "<head><title>%@</title></head>"
                                                     "<body bgcolor='white'>"
                                                     "<center><h1>%@</h1></center>"
                                                     "<hr><center>%@</center>"
                                                     "</body>"
                                                     "</html>", status, status, message];
        //[[challenge sender] cancelAuthenticationChallenge:challenge];
        //[webView loadHTMLString:html baseURL:nil];
        _basic_authorized = YES;
        _basic_authorized_unsupported = YES;
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
        return;
    } else {
        _basic_authorized_unsupported = NO;
    }

    // respond to initial challenge
    if ([challenge previousFailureCount] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Log in to %@", host]
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Log In", nil];
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [LoginDialogDelegate showAlertView:alert withCallback:^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [ForgeLog d:@"User cancelled login"];
                _basic_authorized_failed = YES;
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                return;
            }
            [[challenge sender] useCredential:[NSURLCredential credentialWithUser:[[alert textFieldAtIndex:0] text]
                                                                         password:[[alert textFieldAtIndex:1] text]
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
    [ForgeLog d:@"Received callback: ConnectionDelegate::didReceiveResponse"];

    _basic_authorized = YES;
    _basic_connection = nil;

    [webView loadRequest:_basic_request];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
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
