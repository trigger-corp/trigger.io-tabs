//
//  tabs_Delegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2016/03/16.
//  Copyright © 2016 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface tabs_Delegate : UIViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UITabBarDelegate> {
    NSString *callId;
    tabs_Delegate *me;
}

- (tabs_Delegate*) initWithId:(NSString *)newId;
- (void) releaseDelegate;

@end


// extend protocol for UIButton with our custom selector
@interface UIButton ()
-(void)clicked;
@end

