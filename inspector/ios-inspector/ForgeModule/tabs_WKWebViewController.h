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
}

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) ForgeTask *task;
@property (nonatomic, retain) NSDictionary *result;

- (void)cancel:(id)nothing;
//- (void)close;

@end

NS_ASSUME_NONNULL_END
