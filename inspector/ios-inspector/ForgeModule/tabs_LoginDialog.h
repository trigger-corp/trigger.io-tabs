//
//  LoginDialog.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/23.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface tabs_LoginDialog : NSObject<UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong,nonatomic) AlertViewCompletionBlock callback;

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;

@end

NS_ASSUME_NONNULL_END
