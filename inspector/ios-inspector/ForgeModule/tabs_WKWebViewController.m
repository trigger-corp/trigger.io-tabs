//
//  tabs_WKWebViewController.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2019/08/22.
//  Copyright © 2019 Trigger Corp. All rights reserved.
//

#import "tabs_WKWebViewController.h"
#import "tabs_WKWebViewDelegate.h"
#import "tabs_Util.h"

#import <ForgeCore/WKWebView+AdditionalSafeAreaInsets.h>
#import <ForgeCore/ForgeContentSchemeHandler.h>

@implementation tabs_WKWebViewController


#pragma mark UIViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // fix rotation
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // configure webview preferences
    self.webView.configuration.preferences.minimumFontSize = 1.0;
    self.webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    self.webView.configuration.preferences.javaScriptEnabled = YES;

    // configure overscroll behaviour
    NSNumber *bounces = [[[[[ForgeApp sharedApp] appConfig] objectForKey:@"core"] objectForKey:@"ios"] objectForKey:@"bounces"];
    if (bounces != nil) {
        [self.webView.scrollView setBounces:[bounces boolValue]];
    } else {
        [self.webView.scrollView setBounces:NO];
    }

    // connect web view delegate
    webViewDelegate = [tabs_WKWebViewDelegate withViewController:self];
    self.webView.navigationDelegate = webViewDelegate;
    [self.webView.configuration.userContentController addScriptMessageHandler:webViewDelegate name:@"forge"];

    // install custom protocol handler
    if (@available(iOS 11.0, *)) {
        [self.webView.configuration setURLSchemeHandler:[[ForgeContentSchemeHandler alloc] init] forURLScheme:@"content"];
    }

    // workaround CORS errors when using file:/// - also see: https://bugs.webkit.org/show_bug.cgi?id=154916
    @try {
        [self.webView.configuration.preferences setValue:@TRUE forKey:@"allowFileAccessFromFileURLs"];
    } @catch (NSException *exception) {}
    @try {
        [self.webView.configuration setValue:@TRUE forKey:@"allowUniversalAccessFromFileURLs"];
    } @catch (NSException *exception) {}

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

    // connect close button
    [self.navigationBarButton setTarget:[tabs_ButtonDelegate withHandler:^{
        self.result = @{
            @"userCancelled": [NSNumber numberWithBool:YES]
        };
        // TODO consider rather triggering event here instead of relying on viewDidDisappear
        //      to return ?
        [ForgeApp.sharedApp.viewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self.navigationBarButton setAction:@selector(tabs_ButtonDelegate_clicked)];

    // apply ui properties
    self.navigationBarTitle.title = self.title;

    if (self.navigationBarTint != nil) {
        _blurView.backgroundColor = self.navigationBarTint;
    }
    if (self.navigationBarTitleTint != nil) {
        self.navigationBar.titleTextAttributes = @{
            NSForegroundColorAttributeName: self.navigationBarTitleTint
        };
    }
    _blurViewVisualEffect.hidden = self.navigationBarIsOpaque;
    if (self.navigationBarButtonTint != nil) {
        self.navigationBarButton.tintColor = self.navigationBarButtonTint;
    }
    if (self.navigationBarButtonIconPath != nil) {
        [[[ForgeFile alloc] initWithObject:self.navigationBarButtonIconPath] data:^(NSData *data) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            image = [image imageWithWidth:0 andHeight:28 andRetina:YES];
            self.navigationBarButton.image = image;
        } errorBlock:^(NSError *error) { }];
    } else if (self.navigationBarButtonText != nil) {
        self.navigationBarButton.title = self.navigationBarButtonText;
    }

    // create toolbar
    self.toolBar = [[tabs_ToolBar alloc] initWithViewController:self];
    self.toolBar.hidden = !self.enableToolBar;
    [self.view insertSubview:self.toolBar aboveSubview:self.webView];
    [self layoutNavigationToolbar];

    // start URL loading
    if (_url == nil) {
        _url = [NSURL URLWithString:@"about:blank"];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
}


- (void) viewDidDisappear:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (self.result != nil) {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.closed", self.task.callid] withParam:self.result];
    } else {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.closed", self.task.callid] withParam:@{
            @"userCancelled": [NSNumber numberWithBool:YES]
        }];
    }

    [super viewDidDisappear:animated];
}


- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // refresh insets once rotation is complete
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGFloat topInset = self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height;
        [self setTopInset:topInset];
    }];
}


#pragma mark Layout Helpers

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


- (void)layoutNavigationToolbar {
    self.toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.toolBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    if (@available(iOS 11.0, *)) {
        [self.toolBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [self.toolBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    }
}


#pragma mark Insets

- (void) setTopInset:(CGFloat) topInset {
    UIEdgeInsets scrollInset  = self.webView.scrollView.scrollIndicatorInsets;
    UIEdgeInsets contentInset = self.webView.scrollView.contentInset;
    scrollInset = UIEdgeInsetsMake(topInset, scrollInset.left, scrollInset.bottom, scrollInset.right);
    contentInset = UIEdgeInsetsMake(topInset, contentInset.left, contentInset.bottom, contentInset.right);
    self.webView.scrollView.scrollIndicatorInsets = scrollInset;
    self.webView.scrollView.contentInset = contentInset;
}


#pragma mark UI Delegates

/*- (void)close {
    self.result = @{
        @"userCancelled": [NSNumber numberWithBool:NO],
        @"url": self.webView.URL.absoluteString
    };

    [self dismissViewControllerAnimated:YES completion:nil];
}*/


#pragma mark API // TODO consider moving these guys to tabs_API

- (void) addButtonWithTask:(ForgeTask*)task text:(NSString*)text icon:(NSString*)icon position:(NSString*)position style:(NSString*)style tint:(UIColor*)tint {
    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] init];

    if (style != nil && [style isEqualToString:@"done"]) {
        [buttonItem setStyle:UIBarButtonItemStyleDone];
    } else {
        [buttonItem setStyle:UIBarButtonItemStylePlain];
    }

    if (text != nil) {
        [buttonItem setTitle:text];

    } else if (icon != nil) {
        [[[ForgeFile alloc] initWithObject:icon] data:^(NSData *data) {
            UIImage *icon = [[UIImage alloc] initWithData:data];
            icon = [icon imageWithWidth:0 andHeight:28 andRetina:YES];
            [buttonItem setImage:icon];
        } errorBlock:^(NSError *error) {
        }];

    } else {
        [task error:@"You need to specify either a 'text' or 'icon' property for your button."];
        return;
    }

    if (tint != nil) {
        [buttonItem setTintColor:tint];
    }

    [buttonItem setTarget:[tabs_ButtonDelegate withHandler:^{
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.buttonPressed.%@", self.task.callid] withParam:[NSNull null]];
    }]];
    [buttonItem setAction:@selector(tabs_ButtonDelegate_clicked)];


    UINavigationItem *navigationItem = ((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]);
    if (position != nil && [position isEqualToString:@"right"]) {
        [navigationItem setRightBarButtonItem:buttonItem];
    } else {
        [navigationItem setLeftBarButtonItem:buttonItem];
    }

    [task success:task.callid];
}


- (void) removeButtonsWithTask:(ForgeTask*)task {
    UINavigationItem *navigationItem = ((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]);

    if (navigationItem.leftBarButtonItem.target != nil) {
        [((tabs_ButtonDelegate*)navigationItem.leftBarButtonItem.target) releaseDelegate];
    }
    [navigationItem setLeftBarButtonItem:nil];

    if (navigationItem.rightBarButtonItem.target != nil) {
        [((tabs_ButtonDelegate*)navigationItem.rightBarButtonItem.target) releaseDelegate];
    }
    [navigationItem setRightBarButtonItem:nil];

    [task success:nil];
}


#pragma mark Blur Effect

- (void) createStatusBarVisualEffect:(UIView*)theWebView {
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


@end
