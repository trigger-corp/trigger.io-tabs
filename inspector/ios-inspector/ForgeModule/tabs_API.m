//
//  tabs_API.m
//  Forge
//
//  Created by Connor Dunn on 14/03/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "tabs_API.h"
#import "tabs_Util.h"

#import "tabs_WKWebViewController.h"

static NSMutableDictionary<NSString*, tabs_WKWebViewController*> *tabs_viewControllers = nil;

@implementation tabs_API

+ (void) open:(ForgeTask*)task {
    NSString *url = task.params[@"url"];
    if (url == nil) {
        [task error:@"Missing url" type:@"BAD_INPUT" subtype:nil];
        return;
    }
    NSURL* param_url = [NSURL URLWithString:url];
    if (param_url == nil) {
        param_url = [NSURL fileURLWithPath:url];
    }
    if (param_url == nil) {
        [task error:@"Invalid url" type:@"BAD_INPUT" subtype:nil];
        return;
    }
    NSString *param_pattern = task.params[@"pattern"];

    tabs_WKWebViewController *viewController = [[tabs_WKWebViewController alloc]
        initWithNibName:@"tabs_WKWebViewController"
                 bundle:[NSBundle bundleWithPath:[[NSBundle mainBundle]
        pathForResource:@"tabs"
                 ofType:@"bundle"]]];

    viewController.url = param_url;
    viewController.pattern = param_pattern;
    viewController.task = task;

    if (([task.params objectForKey:@"statusBarStyle"] != nil) &&
        ([[task.params objectForKey:@"statusBarStyle"] isEqualToString:@"light_content"])) {
        viewController.statusBarStyle = UIStatusBarStyleLightContent;
    } else {
        viewController.statusBarStyle = UIStatusBarStyleDefault;
    }

    viewController.title = task.params[@"title"] ?: @"";

    viewController.navigationBarTint = [tabs_Util colorFromArrayU8:task.params[@"tint"]];
    viewController.navigationBarTitleTint = [tabs_Util colorFromArrayU8:task.params[@"titleTint"]];
    viewController.navigationBarIsOpaque = task.params[@"opaqueTopBar"]
                                         ? [[task.params objectForKey:@"opaqueTopBar"] boolValue]
                                         : NO;

    viewController.navigationBarButtonTint = [tabs_Util colorFromArrayU8:task.params[@"buttonTint"]];
    viewController.navigationBarButtonIconPath = task.params[@"buttonIcon"];
    viewController.navigationBarButtonText = task.params[@"buttonText"];

    viewController.enableToolBar = task.params[@"navigationToolbar"]
                                 ? [[task.params objectForKey:@"navigationToolbar"] boolValue]
                                 : NO;
                                 
    if (tabs_viewControllers == nil) {
        tabs_viewControllers = [[NSMutableDictionary alloc] init];
    }
    tabs_viewControllers[task.callid] = viewController;
    viewController.releaseHandler = ^{
        [ForgeLog d:[NSString stringWithFormat:@"Deleting tab with callid:%@ url:%@", task.callid, task.params[@"url"]]];
        tabs_viewControllers[task.callid] = nil;
    };


    if (@available(iOS 13.0, *)) {
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        // As of Xcode 11 GM "UIModalPresentationOverFullScreen" also works on iOS 13 devices (until Apple breaks it again?)
    } else {
        viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    [ForgeApp.sharedApp.viewController presentViewController:viewController animated:YES completion:^{
        [task success:task.callid];
    }];
}


+ (void) executeJS:(ForgeTask*)task modal:(NSString*)modal script:(NSString*)script {
    tabs_WKWebViewController *viewController = tabs_viewControllers[modal];
    if (viewController == nil) {
        [task error:[NSString stringWithFormat:@"No tab found with callid: %@", modal]];
        return;
    }

    [viewController.webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            [task error:[error localizedDescription]];
            return;
        }
        [task success:result];
    }];
}


+ (void) close:(ForgeTask*)task modal:(NSString*)modal {
    tabs_WKWebViewController *viewController = tabs_viewControllers[modal];
    if (viewController == nil) {
        [task error:[NSString stringWithFormat:@"No tab found with callid: %@", modal]];
        return;
    }

    NSString *url = viewController.webView.URL.absoluteString ?: viewController.failingURL;
    viewController.result = @{
        @"userCancelled": [NSNumber numberWithBool:NO],
        @"url": url
    };
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [task success:nil];
    }];
}


+ (void) addButton:(ForgeTask*)task modal:(NSString*)modal params:(NSDictionary*)params {
    tabs_WKWebViewController *viewController = tabs_viewControllers[modal];
    if (viewController == nil) {
        [task error:[NSString stringWithFormat:@"No tab found with callid: %@", modal]];
        return;
    }

    NSString* text = nil;
    NSString* icon = nil;
    NSString* position = nil;
    NSString* style = nil;
    UIColor*  tint = nil;
    
    if ([params objectForKey:@"text"] != nil) {
        text = [params objectForKey:@"text"];
    }
    if ([params objectForKey:@"icon"] != nil) {
        icon = [params objectForKey:@"icon"];
    }
    if ([params objectForKey:@"position"] != nil) {
        position = [params objectForKey:@"position"];
    }
    if ([params objectForKey:@"style"] != nil) {
        style = [params objectForKey:@"style"];
    }
    if ([params objectForKey:@"tint"] != nil) {
        NSArray* array = [params objectForKey:@"tint"];
        tint = [tabs_Util colorFromArrayU8:array];
    }

    [viewController addButtonWithTask:task text:text icon:icon position:position style:style tint:tint];
}


+ (void) removeButtons:(ForgeTask*)task modal:(NSString*)modal {
    tabs_WKWebViewController *viewController = tabs_viewControllers[modal];
    if (viewController == nil) {
        [task error:[NSString stringWithFormat:@"No tab found with callid: %@", modal]];
        return;
    }
    [viewController removeButtonsWithTask:task];
}


+ (void) setTitle:(ForgeTask*)task modal:(NSString*)modal title:(NSString*)title {
    tabs_WKWebViewController *viewController = tabs_viewControllers[modal];
    if (viewController == nil) {
        return;
    }
    viewController.title = title;
    viewController.navigationBarTitle.title = title;
}

@end
