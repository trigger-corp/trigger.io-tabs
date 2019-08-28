//
//  tabs_Activities.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/22.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "tabs_ActivityPopover.h"

// = tabs_SafariActivity =======================================================

@implementation tabs_SafariActivity

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return @"Open in Safari";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"ActivityImages.bundle/Safari"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            url = activityItem;
        } else {
            url = nil;
        }
    }
}

- (void)performActivity {
    if (url == nil) {
        NSLog(@"No active URL for tabs_SafariActivity");
        return;
    }

    BOOL completed = [[UIApplication sharedApplication] openURL:url];
    [self activityDidFinish:completed];
}

@end


// = tabs_ChromeActivity =======================================================

@implementation tabs_ChromeActivity

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
    return @"Open in Chrome";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"ActivityImages.bundle/Chrome"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:self.schemePrefix]]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            url = activityItem;
        } else {
            url = nil;
        }
    }
}

- (void)performActivity {
    if (url == nil) {
        NSLog(@"No active URL for tabs_ChromeActivity");
        return;
    }

    NSURL *chromeURL = url;
    NSString *scheme = url.scheme;

    // Replace the URL Scheme with the Chrome equivalent.
    NSString *chromeScheme = nil;
    if ([scheme isEqualToString:@"http"]) {
        chromeScheme = @"googlechrome";
    } else if ([scheme isEqualToString:@"https"]) {
        chromeScheme = @"googlechromes";
    }

    // Proceed only if a valid Google Chrome URI Scheme is available.
    if (chromeScheme) {
        NSString *absoluteString = [url absoluteString];
        NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
        NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
        NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
        chromeURL = [NSURL URLWithString:chromeURLString];
    }

    // Open the URL with Chrome.
    BOOL completed = [[UIApplication sharedApplication] openURL:chromeURL];
    [self activityDidFinish:completed];
}

@end
