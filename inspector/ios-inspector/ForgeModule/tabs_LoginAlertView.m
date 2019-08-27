//
//  tabs_LoginAlertView.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/23.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_LoginAlertView.h"

const struct tabs_LoginAlertText tabs_i8n = {
    .titleText = @"Log in to %host%",
    .usernameHintText = @"Login",
    .passwordHintText = @"Password",
    .loginButtonText = @"Log In",
    .cancelButtonText = @"Cancel"
};


@implementation tabs_LoginAlertView
@synthesize callback;

// TODO DEPRECATE
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}
+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback {
    __block tabs_LoginAlertView *loginDialog = [[tabs_LoginAlertView alloc] init];
    alertView.delegate = loginDialog;
    loginDialog.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        loginDialog = nil;
    };
    [alertView show];
}


+ (void)showWithViewController:(tabs_WKWebViewController * _Nonnull)viewController login:(void(^)(NSURLCredential*))login cancel:(void(^)(void))cancel {
    NSDictionary *configuration = [viewController.task.params objectForKey:@"basicAuthConfig"];
    if (configuration == NULL) {
        configuration = @{};
    }
    NSString *titleText = configuration[@"titleText"]               ?: tabs_i8n.titleText;
    NSString *usernameHintText = configuration[@"usernameHintText"] ?: tabs_i8n.usernameHintText;
    NSString *passwordHintText = configuration[@"passwordHintText"] ?: tabs_i8n.passwordHintText;
    NSString *loginButtonText = configuration[@"loginButtonText"]   ?: tabs_i8n.loginButtonText;
    NSString *cancelButtonText = configuration[@"cancelButtonText"] ?: tabs_i8n.cancelButtonText;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:viewController.webView.title
                         message:[titleText stringByReplacingOccurrencesOfString:@"%host%" withString:viewController.webView.URL.host]
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = usernameHintText;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = passwordHintText;
        textField.secureTextEntry = YES;
    }];
    [alert addAction:[UIAlertAction
     actionWithTitle:loginButtonText
               style:UIAlertActionStyleDefault
             handler:^(UIAlertAction * _Nonnull action) {
        NSString *username = alert.textFields.firstObject.text;
        NSString *password = alert.textFields.lastObject.text;
        NSURLCredential *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
        login(credential);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:cancelButtonText style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        cancel();
    }]];

    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
