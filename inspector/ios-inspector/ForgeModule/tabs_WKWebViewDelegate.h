//
//  tabs_WKWebViewDelegate.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "tabs_WKWebViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface tabs_WKWebViewDelegate : NSObject <WKNavigationDelegate,
                                              WKScriptMessageHandler> {
    NSURL *_retryURL;
}

@property (weak, nonatomic) tabs_WKWebViewController* viewController;

@property (nonatomic, assign) BOOL hasLoaded;

+ (tabs_WKWebViewDelegate*)withViewController:(tabs_WKWebViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
