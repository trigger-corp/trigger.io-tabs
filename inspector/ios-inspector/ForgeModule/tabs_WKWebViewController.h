//
//  tabs_WKWebViewController.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class tabs_WKWebViewDelegate;


NS_ASSUME_NONNULL_BEGIN

@interface tabs_WKWebViewController : UIViewController {
    tabs_WKWebViewDelegate *webViewDelegate;

    UIView *_blurView;
    UIVisualEffectView *_blurViewVisualEffect;
    NSLayoutConstraint *_blurViewBottomConstraint;

    BOOL opaqueTopBar;
}

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navigationBarButton;

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *pattern;
@property (nonatomic, retain) ForgeTask *task;
@property (nonatomic, retain) NSDictionary *result;

@property (nonatomic, retain) UIColor *navigationBarTint; // TODO should we deprecate?
@property (nonatomic, retain) UIColor *navigationBarTitleTint; // TODO should we deprecate?

@property (nonatomic, retain) UIColor *navigationBarButtonTint;
@property (nonatomic, retain) NSString *navigationBarButtonText;
@property (nonatomic, retain) NSString *navigationBarButtonIconPath;


- (void) addButtonWithTask:(ForgeTask*)task text:(NSString*)text icon:(NSString*)icon position:(NSString*)position style:(NSString*)style tint:(UIColor*)tint;
- (void) removeButtonsWithTask:(ForgeTask*)task;

//- (void) close;

@end

NS_ASSUME_NONNULL_END
