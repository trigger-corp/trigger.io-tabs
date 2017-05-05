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

- (void) log:(NSString*)message {
    if (verboseLogging) {
        [ForgeLog d:message];
    }
}

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
    useCredentialStorage = YES;
    verboseLogging = NO;
    
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

    [self log:[NSString stringWithFormat:@"[1] Invocation: ConnectionDelegate::handleRequest v2.5.10 %@ authorized: %d asked: %d", requestURL, _basic_authorized, _basic_authorized_did_ask]];

    // assume requests coming through while webview is loading are embedded content
    if (webView.isLoading) {
        [self log:@"Returning ConnectionDelegate::handleRequest YES - embedded content"];
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
        [self log:@"Returning ConnectionDelegate::handleRequest NO - not authorized"];
        return NO;
    }

    // sometimes preceding pages did not have auth so we cannot assume subsequent requests will also be authed
    if (_basic_authorized_embedded == NO && _basic_authorized_did_ask == NO) {
      _basic_authorized = NO; // reset basic auth for next request
    }

    [self log:@"Returning ConnectionDelegate::handleRequest YES - we are authorized"];

    return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection*)connection;
{
    [self log:[NSString stringWithFormat:@"[2] Received callback: ConnectionDelegate::connectionShouldUseCredentialStorage => %d", useCredentialStorage]];

    return useCredentialStorage;
}

- (BOOL)isSupportedAuthenticationMethod:(NSString *const)authenticationMethod
{
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
        return YES;
    } else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodNTLM]) {
        return YES;
    }
    return NO;
}


- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self log:[NSString stringWithFormat:@"[3] Received callback: ConnectionDelegate::willSendRequestForAuthenticationChallenge %@ authorized: %d embedded: %d", [challenge.protectionSpace host], _basic_authorized, _basic_authorized_embedded]];
    [self log:[NSString stringWithFormat:@"  Error: %@", challenge.error]];                                  // NSError
    [self log:[NSString stringWithFormat:@"  Failure Response: %@", challenge.failureResponse]];             // NSURLResponse
    [self log:[NSString stringWithFormat:@"  Previous Failure Count: %ld", challenge.previousFailureCount]]; // int
    [self log:[NSString stringWithFormat:@"  Proposed Credential: %@", challenge.proposedCredential]];       // NSURLCredential
    [self log:[NSString stringWithFormat:@"  Protection Space: %@", challenge.protectionSpace]];             // NSURLProtectionSpace
    [self log:[NSString stringWithFormat:@"    protocol = %@", [[challenge protectionSpace] protocol]]];
    [self log:[NSString stringWithFormat:@"    realm = %@", [[challenge protectionSpace] realm]]];
    [self log:[NSString stringWithFormat:@"    authenticationMethod = %@", [[challenge protectionSpace] authenticationMethod]]];
    [self log:[NSString stringWithFormat:@"  Sender: %@", challenge.sender]];                                // NSURLAuthenticationChallengeSender

    // get challenge information
    NSString *host = [challenge.protectionSpace host];
    NSString *status = @"";
    NSString *server = @"";
    if ([challenge.failureResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse*)challenge.failureResponse;
        status = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
        server = [response.allHeaderFields valueForKey:@"Server"];
    }

    // Handle server trust
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [self log:@"Responding to authentication method: NSURLAuthenticationMethodServerTrust"];
        _basic_authorized = NO;
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return;
    }

    // Handle unsupported authentication challenges
    if (![self isSupportedAuthenticationMethod:[[challenge protectionSpace] authenticationMethod]]) {
        NSString *message = [NSString stringWithFormat:@"Rejecting authentication method: %@", [[challenge protectionSpace] authenticationMethod]];
        [self log:message];
        _basic_authorized = NO;
        [[challenge sender] rejectProtectionSpaceAndContinueWithChallenge:challenge];
        return;
    }

    // Handle supported authentication challenges
    NSString *message = [NSString stringWithFormat:@"Handling supported authentication method: %@", [[challenge protectionSpace] authenticationMethod]];
    [self log:message];

    // update state flags
    _basic_authorized = NO;
    _basic_authorized_did_ask = YES;

    // respond to initial challenge
    if ([challenge previousFailureCount] == 0) {
        [self log:@"Requesting username/password for basic auth"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[i8n.title stringByReplacingOccurrencesOfString:@"%host%" withString:host]
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:i8n.cancelButton
                                              otherButtonTitles:i8n.loginButton, nil];
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [LoginDialogDelegate showAlertView:alert withCallback:^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [self log:@"User cancelled username/password request for basic auth"];
                _basic_authorized_failed = YES;
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                if (closeTabOnCancel == YES) {
                    [modalInstance cancel:nil];
                }
                return;
            }

            [self log:@"Sending username/password challenge response for basic auth"];
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
    [self log:@"Invalid username/password for basic auth"];
    _basic_authorized_failed = YES;
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSString *status = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
    NSString *responseString = [NSString stringWithFormat:@"%@", httpResponse];

    [self log:[NSString stringWithFormat:@"[4] Received callback: ConnectionDelegate::didReceiveResponse status: %@ authorized: %d embedded: %d failed: %d", status, _basic_authorized, _basic_authorized_embedded, _basic_authorized_failed]];
    [self log:[NSString stringWithFormat:@"    Response: %@", responseString]];

    _basic_authorized = YES;
    _basic_connection = nil;

    [webView loadRequest:_basic_request];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self log:[NSString stringWithFormat:@"[5] Received callback: ConnectionDelegate::didReceiveData authorized: %d embedded: %d failed: %d", _basic_authorized, _basic_authorized_embedded, _basic_authorized_failed]];

    if (_basic_authorized_failed == YES) {
        _basic_authorized_failed = NO;
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self log:[NSString stringWithFormat:@"Authorization failed: ConnectionDelegate::didReceiveData %@", html]];
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
