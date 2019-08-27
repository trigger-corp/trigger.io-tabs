//
//  tabs_Util.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/27.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_Util.h"

@implementation tabs_Util

+ (UIColor*) colorFromArrayU8:(NSArray*)array {
    if (array == nil) {
        return nil;
    }
    return [UIColor colorWithRed:[(NSNumber*)[array objectAtIndex:0] floatValue] / 255.
                           green:[(NSNumber*)[array objectAtIndex:1] floatValue] / 255.
                            blue:[(NSNumber*)[array objectAtIndex:2] floatValue] / 255.
                           alpha:[(NSNumber*)[array objectAtIndex:3] floatValue] / 255.];
}


@end


@implementation tabs_ButtonDelegate

+ (tabs_ButtonDelegate*) withHandler:(void(^_Nonnull)(void))handler {
    tabs_ButtonDelegate *buttonDelegate = [[tabs_ButtonDelegate alloc] init];
    if (buttonDelegate) {
        buttonDelegate->handler = handler;
        buttonDelegate->me = buttonDelegate;
    }
    return buttonDelegate;
}

- (void) tabs_ButtonDelegate_clicked {
    //NSString *eventName = [NSString stringWithFormat:@"tabs.buttonPressed.%@", callId];
    //[[ForgeApp sharedApp] event:eventName withParam:[NSNull null]];
    handler();
}


- (void) releaseDelegate {
    me = nil;
}

@end
