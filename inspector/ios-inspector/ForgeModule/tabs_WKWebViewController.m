//
//  tabs_WKWebViewController.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_WKWebViewController.h"
#import "tabs_WKWebViewDelegate.h"

#import <ForgeCore/WKWebView+AdditionalSafeAreaInsets.h>

@implementation tabs_WKWebViewController


#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // install SafeAreaInsets handler
    /*self.webView.safeAreaInsetsHandler = ^UIEdgeInsets(UIEdgeInsets insets) {
        [ForgeLog i:@"tabs_WKWebViewController :: safeAreaInsetsHandler"];
        insets.top += ;
        return insets;
    };*/

    // fix rotation
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // connect web view delegate
    webViewDelegate = [tabs_WKWebViewDelegate withViewController:self];
    self.webView.navigationDelegate = webViewDelegate;

    // set background color to clear
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];

    // set content insets
    if (@available(iOS 11.0, *)) {
        [self.webView.scrollView setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];
    }
    CGFloat topInset = self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height;
    [self setTopInset:topInset];

    // create blur view for status and navigation bar
    [self createStatusBarVisualEffect:self.webView];
    /*if (tint != nil) {
        _blurView.backgroundColor = tint;
    }
    _blurViewVisualEffect.hidden = opaqueTopBar;*/

    // connect close button
    [self.closeButton setTarget:self];
    [self.closeButton setAction:@selector(cancel:)];

    // start URL loading
    if (_url == nil) {
        _url = [NSURL URLWithString:@"about:blank"];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
            //[self setNavigationToolbarHidden:YES];
        } else {
            //[self setNavigationToolbarHidden:NO];
        }
    }

    // refresh insets once rotation is complete
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGFloat topInset = self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height;
        [self setTopInset:topInset];
        //CGRect f = self.view.frame;
        //self.view.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width + 1, f.size.height + 1);
        //self.view.frame = f;
    }];
}




#pragma mark Insets

- (void) setTopInset:(CGFloat) topInset {
    UIEdgeInsets scrollInset  = self.webView.scrollView.scrollIndicatorInsets;
    UIEdgeInsets contentInset = self.webView.scrollView.contentInset;
    scrollInset = UIEdgeInsetsMake(topInset, scrollInset.left, scrollInset.bottom, scrollInset.right);
    contentInset = UIEdgeInsetsMake(topInset, contentInset.left, contentInset.bottom, contentInset.right);
    self.webView.scrollView.scrollIndicatorInsets = scrollInset;
    self.webView.scrollView.contentInset = contentInset;

    //CGRect rect = CGRectMake(0, 0, self.webView.scrollView., <#CGFloat height#>);
    //[self.webView.scrollView scrollRectToVisible:rect animated:NO];
}


#pragma mark Blur Effect

- (void)createStatusBarVisualEffect:(UIView*)theWebView {
    // remove existing status bar blur effect
    [_navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [_navigationBar setShadowImage:[[UIImage alloc] init]];

    // create a replacement blur effect that covers both the status bar and navigation bar
    _blurView = [[UIView alloc] init];
    _blurView.userInteractionEnabled = NO;
    _blurView.backgroundColor = [UIColor clearColor];
    _blurViewVisualEffect = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    _blurViewVisualEffect.userInteractionEnabled = NO;
    [_blurView addSubview:_blurViewVisualEffect];
    [self.view insertSubview:_blurView aboveSubview:theWebView];

    // layout constraints
    _blurViewBottomConstraint = [NSLayoutConstraint constraintWithItem:_blurView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.navigationBar
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0f
                                                             constant:0.0f];

    [self layoutStatusBarVisualEffect];
}


- (void)layoutStatusBarVisualEffect {
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [_blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_blurView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;

    _blurViewBottomConstraint.active = YES;

    _blurViewVisualEffect.translatesAutoresizingMaskIntoConstraints = NO;
    [_blurViewVisualEffect.leadingAnchor constraintEqualToAnchor:_blurView.leadingAnchor].active = YES;
    [_blurViewVisualEffect.trailingAnchor constraintEqualToAnchor:_blurView.trailingAnchor].active = YES;
    [_blurViewVisualEffect.topAnchor constraintEqualToAnchor:_blurView.topAnchor].active = YES;
    [_blurViewVisualEffect.bottomAnchor constraintEqualToAnchor:_blurView.bottomAnchor].active = YES;
}


#pragma mark UI Delegates

- (void)cancel:(id)nothing {
    self.result = @{
        @"userCancelled": [NSNumber numberWithBool:YES]
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        //[self dismissViewControllerAnimated:YES completion:nil];
        //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        [ForgeApp.sharedApp.viewController dismissViewControllerAnimated:YES completion:nil];
    });
}

/*- (void)close {
    self.result = @{
        @"userCancelled": [NSNumber numberWithBool:NO],
        @"url": self.webView.URL.absoluteString
    };

    [self dismissViewControllerAnimated:YES completion:nil];
}*/



#pragma mark Helpers

/*- (void)forceUpdateWebView {
    CGRect f = self.webView.frame;
    self.webView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width + 1, f.size.height + 1);
    self.webView.frame = f;
}*/

@end
