//
//  LoginDialog.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/23.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_LoginDialog.h"

@implementation tabs_LoginDialog
@synthesize callback;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback {
    __block tabs_LoginDialog *loginDialog = [[tabs_LoginDialog alloc] init];
    alertView.delegate = loginDialog;
    loginDialog.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        loginDialog = nil;
    };
    [alertView show];
}

@end
