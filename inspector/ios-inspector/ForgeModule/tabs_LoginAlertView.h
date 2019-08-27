//
//  LoginDialog.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/23.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "tabs_WKWebViewController.h"


NS_ASSUME_NONNULL_BEGIN

struct tabs_LoginAlertText {
    __unsafe_unretained NSString *titleText;
    __unsafe_unretained NSString *usernameHintText;
    __unsafe_unretained NSString *passwordHintText;
    __unsafe_unretained NSString *loginButtonText;
    __unsafe_unretained NSString *cancelButtonText;
};
extern const struct tabs_LoginAlertText tabs_i8n;


@interface tabs_LoginAlertView : NSObject<UIAlertViewDelegate>

+ (void)showWithViewController:(tabs_WKWebViewController * _Nonnull)viewController login:(void(^)(NSURLCredential*))login cancel:(void(^)(void))cancel;

// TODO deprecate these
typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong,nonatomic) AlertViewCompletionBlock callback;
+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;

@end

NS_ASSUME_NONNULL_END
