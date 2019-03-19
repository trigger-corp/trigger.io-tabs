//
//  tabs_ConnectionDelegate.m
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
        [ForgeLog d:[NSString stringWithFormat:@"[ConnectionDelegate] %@", message]];
    }
}

- (ConnectionDelegate*) initWithModalView:(tabs_modalWebViewController*)newModalInstance webView:(UIWebView *)newWebView pattern:(NSString*)newPattern {
    if (self = [super init]) {
        modalInstance = newModalInstance;
        webView = newWebView;
        pattern = newPattern;
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
    retryFailedLogin =  NO;
    
    _basic_authorized_failed = NO;

    authorizationCache = [[NSMutableDictionary alloc] init];

    return self;
}


- (void) releaseDelegate {
    me = nil;
}


- (BOOL)handleRequest:(NSURLRequest *)request
{
    NSString *requestURL = [[request URL] absoluteString];

    [self log:[NSString stringWithFormat:@"[1] Invocation: ConnectionDelegate::handleRequest %@", requestURL]];

    // assume requests coming through while webview is loading are embedded content
    if (webView.isLoading) {
        [self log:@"Returning ConnectionDelegate::handleRequest YES - embedded content"];
        return YES;
    }

    // whitelist display of the basic_auth unauthorized message
    if ([requestURL isEqualToString:@"about:blank"]) {
        NSLog(@"about:blank");
        return YES;
    }

    // check if this URL has been authorized in the past
    NSNumber *authorized = [authorizationCache objectForKey:requestURL];
    bool _basic_authorized = NO;
    if (authorized != nil) {
        [self log:[NSString stringWithFormat:@"ConnectionDelegate::handleRequest authorizationCache: %@", authorized]];
        _basic_authorized = [authorized boolValue];
    }
    
    if (_basic_authorized == YES) {
        [self log:@"Returning ConnectionDelegate::handleRequest YES - we are authorized"];
        return YES;
    }

    
    [self log:@"Returning ConnectionDelegate::handleRequest NO - not authorized"];
    [NSURLConnection connectionWithRequest:request delegate:self];
    return NO;
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
    }
    
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodNTLM]) {
        return YES;
    }
    
    return NO;
}


- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self log:[NSString stringWithFormat:@"[3] Received callback: ConnectionDelegate::willSendRequestForAuthenticationChallenge %@", [challenge.protectionSpace host]]];
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
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return;
    }

    // Handle unsupported authentication challenges
    if (![self isSupportedAuthenticationMethod:[[challenge protectionSpace] authenticationMethod]]) {
        NSString *message = [NSString stringWithFormat:@"Rejecting authentication method: %@", [[challenge protectionSpace] authenticationMethod]];
        [self log:message];
        [[challenge sender] rejectProtectionSpaceAndContinueWithChallenge:challenge];
        return;
    }

    // Handle supported authentication challenges
    NSString *message = [NSString stringWithFormat:@"Handling supported authentication method: %@", [[challenge protectionSpace] authenticationMethod]];
    [self log:message];

    // allow up to three retries if retryFailedLogin is set
    int tries = 1;
    if (retryFailedLogin) {
        tries = 3;
    }
    [self log:[NSString stringWithFormat:@"Previous failure count is: %ld", [challenge previousFailureCount]]];

    // stop if user supplied invalid credentials and hit max retries
    if ([challenge previousFailureCount] >= tries) {
        [self log:@"Invalid username/password for basic auth"];
        _basic_authorized_failed = YES;
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    // open login dialog in ui thread
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // stop if already closed
    if (me == nil) {
        return;
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    NSString *status = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
    NSString *responseString = [NSString stringWithFormat:@"%@", httpResponse];

    [self log:[NSString stringWithFormat:@"[4] Received callback: ConnectionDelegate::didReceiveResponse status: %@ failed: %d", status, _basic_authorized_failed]];
    [self log:[NSString stringWithFormat:@"    Response: %@", responseString]];

    NSString *url = [[[connection currentRequest] URL] absoluteString];
    [authorizationCache setObject:[NSNumber numberWithBool:YES] forKey:url];

    // check return pattern
    NSString *responseURL = [[response URL] absoluteString];
    if (pattern != nil) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        if ([regex numberOfMatchesInString:responseURL options:0 range:NSMakeRange(0, [responseURL length])] > 0) {
            NSDictionary *returnObj = [NSDictionary dictionaryWithObjectsAndKeys:responseURL, @"url",
                                                        [NSNumber numberWithBool:NO], @"userCancelled", nil];
            [modalInstance setReturnObj:returnObj];
            [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:nil];
            [[[ForgeApp sharedApp] viewController] performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];
            return;
        }
    }
    
    // remember the current url until response body is loaded
    currentUrl = [NSURL URLWithString:responseURL];
    
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self log:[NSString stringWithFormat:@"[5] Received callback: ConnectionDelegate::didReceiveData failed: %d", _basic_authorized_failed]];

    NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    _basic_authorized_failed = NO;
    
    // The webview won't load the page content automatically.
    [self log:[NSString stringWithFormat:@"[6] Received callback: Load body after basicAuthFlow: %@", html]];
    [webView loadHTMLString:html baseURL:currentUrl];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self log:[NSString stringWithFormat:@"[6] Received callback: ConnectionDelegate::didFailWithError: %@ failed: %d", error, _basic_authorized_failed]];
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
