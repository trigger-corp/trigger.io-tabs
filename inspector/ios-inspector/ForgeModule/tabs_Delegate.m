//
//  tabs_Delegate.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2016/03/16.
//  Copyright © 2016 Trigger Corp. All rights reserved.
//

#import "tabs_Delegate.h"


@implementation tabs_Delegate

- (tabs_Delegate*) initWithId:(NSString *)newId {
    if (self = [super init]) {
        callId = newId;
        // "retain"
        me = self;
    }
    return self;
}


- (void) clicked {
    NSString *eventName = [NSString stringWithFormat:@"tabs.buttonPressed.%@", callId];
    [[ForgeApp sharedApp] event:eventName withParam:[NSNull null]];
}


- (void) releaseDelegate {
    me = nil;
}

@end
