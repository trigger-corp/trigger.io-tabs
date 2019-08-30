//
//  tabs_API.m
//  Forge
//
//  Created by Connor Dunn on 14/03/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "tabs_API.h"
#import "tabs_Util.h"

#import "tabs_UIWebViewController.h"
#import "tabs_WKWebViewController.h"

static NSMutableDictionary* tabs_viewControllers = nil;

@implementation tabs_API

+ (void)open:(ForgeTask*)task {
    if (![task.params objectForKey:@"url"]) {
        [task error:@"Missing url" type:@"BAD_INPUT" subtype:nil];
        return;
    }

    tabs_WKWebViewController *viewController = [[tabs_WKWebViewController alloc]
        initWithNibName:@"tabs_WKWebViewController"
                 bundle:[NSBundle bundleWithPath:[[NSBundle mainBundle]
        pathForResource:@"tabs"
                 ofType:@"bundle"]]];

    viewController.url = [NSURL URLWithString:task.params[@"url"]];
    viewController.pattern = task.params[@"pattern"];
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
    tabs_viewControllers[task.callid] = [NSValue valueWithNonretainedObject:viewController];

    if (@available(iOS 13.0, *)) {
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [ForgeApp.sharedApp.viewController presentViewController:viewController animated:YES completion:^{
        [task success:task.callid];
    }];
}


/*+ (void)open_:(ForgeTask*)task {
    if (![task.params objectForKey:@"url"]) {
        [task error:@"Missing url" type:@"BAD_INPUT" subtype:nil];
        return;
    }

    tabs_UIWebViewController *viewController = [[tabs_UIWebViewController alloc] initWithNibName:@"tabs_UIWebViewController"
                 bundle:[NSBundle bundleWithPath:[[NSBundle mainBundle]
        pathForResource:@"tabs"
                 ofType:@"bundle"]]];

    [viewController setUrl:[NSURL URLWithString:[task.params objectForKey:@"url"]]];
    [viewController setPattern:[task.params objectForKey:@"pattern"]];
    //[modalView setRootView:ForgeApp.sharedApp.viewController];

    if ([task.params objectForKey:@"title"] != nil) {
        [viewController setTitle:[task.params objectForKey:@"title"]];
    } else {
        [viewController setTitle:@""];
    }

    if ([task.params objectForKey:@"buttonIcon"] != nil) {
        [viewController setBackImage:[task.params objectForKey:@"buttonIcon"]];
    } else if ([task.params objectForKey:@"buttonText"] != nil) {
        [viewController setBackLabel:[task.params objectForKey:@"buttonText"]];
    } else {
        [viewController setBackLabel:@"Close"];
    }

    if ([task.params objectForKey:@"tint"] != nil) {
        NSArray* color = [task.params objectForKey:@"tint"];
        [viewController setTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255
                                                     green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255
                                                      blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255
                                                     alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
    }

    if ([task.params objectForKey:@"titleTint"] != nil) {
        NSArray* color = [task.params objectForKey:@"titleTint"];
        [viewController setTitleTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255
                                                          green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255
                                                           blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255
                                                          alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
    }

    if ([task.params objectForKey:@"buttonTint"] != nil) {
        NSArray* color = [task.params objectForKey:@"buttonTint"];
        [viewController setButtonTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255
                                                           green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255
                                                            blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255
                                                           alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
    }

    if ([task.params objectForKey:@"opaqueTopBar"] != nil) {
        [viewController setOpaqueTopBar:[[task.params objectForKey:@"opaqueTopBar"] boolValue]];
    } else {
        [viewController setOpaqueTopBar:false];
    }

    if (([task.params objectForKey:@"statusBarStyle"] != nil) &&
        ([[task.params objectForKey:@"statusBarStyle"] isEqualToString:@"light_content"])) {
        [viewController setStatusBarStyle:UIStatusBarStyleLightContent];
    } else {
        [viewController setStatusBarStyle:UIStatusBarStyleDefault];
    }

    // status bar options
    if (([task.params objectForKey:@"statusBarStyle"] != nil) &&
        ([[task.params objectForKey:@"statusBarStyle"] isEqualToString:@"light_content"])) {
            [viewController setStatusBarStyle:UIStatusBarStyleLightContent];
    } else {
        [viewController setStatusBarStyle:UIStatusBarStyleDefault];
    }

    // scaling options
    if ([task.params objectForKey:@"scalePagesToFit"] != nil) {
        viewController.scalePagesToFit = [NSNumber numberWithBool:[[task.params objectForKey:@"scalePagesToFit"] boolValue]];
    } else {
        viewController.scalePagesToFit = [NSNumber numberWithBool:NO];
    }

    // navigation toolbar options
    if ([task.params objectForKey:@"navigationToolbar"] != nil) {
        viewController.enableNavigationToolbar = [NSNumber numberWithBool:[[task.params objectForKey:@"navigationToolbar"] boolValue]];
    } else {
        viewController.enableNavigationToolbar = [NSNumber numberWithBool:NO];
    }

    // basic auth options
    if ([task.params objectForKey:@"basicAuth"] != nil) {
        viewController.enableBasicAuth = [NSNumber numberWithBool:[[task.params objectForKey:@"basicAuth"] boolValue]];
    } else {
        viewController.enableBasicAuth = [NSNumber numberWithBool:NO];
    }

    NSDictionary *basicAuthConfig = [task.params objectForKey:@"basicAuthConfig"];
    if (basicAuthConfig != nil && [basicAuthConfig objectForKey:@"insecure"] != nil) {
        viewController.enableInsecureBasicAuth = [NSNumber numberWithBool:[[basicAuthConfig objectForKey:@"insecure"] boolValue]];
    } else {
        viewController.enableInsecureBasicAuth = [NSNumber numberWithBool:NO];;
    }

    [viewController setTask:task];

    // https://medium.com/@hacknicity/view-controller-presentation-changes-in-ios-13-ac8c901ebc4e
    if (@available(iOS 13.0, *)) {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    [ForgeApp.sharedApp.viewController presentViewController:viewController animated:YES completion:nil];
    [task success:task.callid];

    if (tabs_modal_map == nil) {
        tabs_modal_map = [[NSMutableDictionary alloc] init];
    }
    [tabs_modal_map setObject:[NSValue valueWithNonretainedObject:viewController] forKey:task.callid];
}*/


+ (void)executeJS:(ForgeTask*)task modal:(NSString*)modal script:(NSString*)script {
    tabs_WKWebViewController *viewController = [((NSValue *)tabs_viewControllers[modal]) nonretainedObjectValue];
    if (viewController == nil) {
        [task error:[NSString stringWithFormat:@"No tab found for callid: %@", modal]];
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


+ (void)close:(ForgeTask*)task modal:(NSString*)modal {
    tabs_WKWebViewController *viewController = [((NSValue *)tabs_viewControllers[modal]) nonretainedObjectValue];
    NSString *url = viewController.webView.URL.absoluteString ?: viewController.failingURL;
    viewController.result = @{
        @"userCancelled": [NSNumber numberWithBool:NO],
        @"url": url
    };
    [ForgeApp.sharedApp.viewController dismissViewControllerAnimated:YES completion:^{
        [task success:nil];
    }];
}


+ (void)addButton:(ForgeTask*)task modal:(NSString*)modal params:(NSDictionary*)params {
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

    [[((NSValue *)tabs_viewControllers[modal]) nonretainedObjectValue] addButtonWithTask:task text:text icon:icon position:position style:style tint:tint];
}


+ (void)removeButtons:(ForgeTask*)task modal:(NSString*)modal {
    [[((NSValue *)tabs_viewControllers[modal]) nonretainedObjectValue] removeButtonsWithTask:task];
}


+ (void)setTitle:(ForgeTask*)task modal:(NSString*)modal title:(NSString*)title {
    tabs_WKWebViewController *viewController = [((NSValue *)tabs_viewControllers[modal]) nonretainedObjectValue];
    viewController.navigationBarTitle.title = title;
}

@end
