//
//  tabs_Util.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/27.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface tabs_Util : NSObject
+ (UIColor*) colorFromArrayU8:(NSArray*)array;
@end


/**
 * tabs_ButtonDelegate
 */
@interface tabs_ButtonDelegate : UIViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UITabBarDelegate> {
    tabs_ButtonDelegate *me;
    void (^handler)(void);
}

+ (tabs_ButtonDelegate*) withHandler:(void(^_Nonnull)(void))handler;
- (void) releaseDelegate;
@end


// extend protocol for UIButton with a custom selector
@interface UIButton ()
-(void)tabs_ButtonDelegate_clicked;
@end

NS_ASSUME_NONNULL_END
