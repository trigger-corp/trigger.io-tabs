//
//  tabs_WKWebViewController.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "tabs_ToolBar.h"

@class tabs_WKWebViewDelegate;


NS_ASSUME_NONNULL_BEGIN

@interface tabs_WKWebViewController : UIViewController {
    tabs_WKWebViewDelegate *webViewDelegate;

    UIView *_blurView;
    UIVisualEffectView *_blurViewVisualEffect;
    NSLayoutConstraint *_blurViewBottomConstraint;
    __weak IBOutlet NSLayoutConstraint *webViewTopConstraint;
}

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navigationBarButton;

@property (retain, nonatomic) NSURL *url;
@property (retain, nonatomic) NSString *pattern;
@property (retain, nonatomic) ForgeTask *task;
@property (retain, nonatomic) NSDictionary *result;
@property (retain, nonatomic) NSString *failingURL; // WKWebView does not set the webView.URL property if navigation failed

@property (nonatomic, copy, nonnull) void (^releaseHandler)(void);

@property (assign, nonatomic) UIStatusBarStyle statusBarStyle;

@property (retain, nonatomic) UIColor *navigationBarTint;
@property (retain, nonatomic) UIColor *navigationBarTitleTint;
@property (assign, nonatomic) BOOL navigationBarIsOpaque;

@property (retain, nonatomic) UIColor *navigationBarButtonTint;
@property (retain, nonatomic) NSString *navigationBarButtonText;
@property (retain, nonatomic) NSString *navigationBarButtonIconPath;

@property (retain, nonatomic) tabs_ToolBar *toolBar;
@property (assign, nonatomic) BOOL enableToolBar;

- (void) addButtonWithTask:(ForgeTask*)task text:(NSString*)text icon:(NSString*)icon position:(NSString*)position style:(NSString*)style tint:(UIColor*)tint;
- (void) removeButtonsWithTask:(ForgeTask*)task;

@end

NS_ASSUME_NONNULL_END
