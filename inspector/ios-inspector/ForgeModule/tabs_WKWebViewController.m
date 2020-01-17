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

    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];

    // associate with the global WKProcessPool
    WKWebView* parentWebView = (WKWebView*)ForgeApp.sharedApp.webView;
    if (parentWebView.configuration.processPool != nil) {
        configuration.processPool = parentWebView.configuration.processPool;
    }

    // add script message handler
    [configuration.userContentController addScriptMessageHandler:webViewDelegate name:@"forge"];

    // configure webview preferences
    configuration.preferences.minimumFontSize = 1.0;
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    configuration.preferences.javaScriptEnabled = YES;

    // install custom protocol handler
    if (@available(iOS 11.0, *)) {
        [configuration setURLSchemeHandler:[[ForgeContentSchemeHandler alloc] init] forURLScheme:@"content"];
    }

    // workaround CORS errors when using file:/// - also see: https://bugs.webkit.org/show_bug.cgi?id=154916
    @try {
        [configuration.preferences setValue:@TRUE forKey:@"allowFileAccessFromFileURLs"];
    } @catch (NSException *exception) {}
    @try {
        [configuration setValue:@TRUE forKey:@"allowUniversalAccessFromFileURLs"];
    } @catch (NSException *exception) {}

    // add WKHTTPCookieStoreObserver
    if (@available(iOS 11.0, *)) {
        [configuration.websiteDataStore.httpCookieStore addObserver:self];
    } else { } // not supported

    // configure overscroll behaviour
    NSNumber *bounces = [[[[[ForgeApp sharedApp] appConfig] objectForKey:@"core"] objectForKey:@"ios"] objectForKey:@"bounces"];
    if (bounces != nil) {
        [self.webView.scrollView setBounces:[bounces boolValue]];
    } else {
        [self.webView.scrollView setBounces:NO];
    }

    // set background color to clear
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];

    // set content insets
    if (@available(iOS 11.0, *)) {
        [self.webView.scrollView setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];
    }
    if (self.navigationBarIsOpaque) {
        [self setContentInset:0.0 scrollInset:0.0];
    } else {
        CGFloat contentInset = ForgeConstant.statusBarHeightDynamic + self.navigationBar.frame.size.height;
        CGFloat scrollInset = self.navigationBar.frame.size.height;
        [self setContentInset:contentInset scrollInset:scrollInset];
    }

    // setup translucency or blur effects for status and navigation bar
    [self createNavigationBarVisualEffect:self.webView];
    [self layoutNavigationBar];

    // connect close button
    [self.navigationBarButton setTarget:[tabs_ButtonDelegate withHandler:^{
        self.result = @{
            @"userCancelled": [NSNumber numberWithBool:YES]
        };
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    [self layoutToolbar];

    // recreate WebView with configuration
    [self recreateWebViewWithConfiguration:configuration];

    // connect web view delegate
    webViewDelegate = [tabs_WKWebViewDelegate withViewController:self];
    self.webView.navigationDelegate = webViewDelegate;

    // start URL loading
    if (self.url == nil) {
        self.url = [NSURL URLWithString:@"about:blank"];
    }
    if (self.url.isFileURL) {
        [self.webView loadFileURL:self.url allowingReadAccessToURL:[self.url URLByDeletingLastPathComponent]];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
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

    // if you love someone set them free…
    self.releaseHandler();
}


- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // refresh insets once rotation is complete
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.navigationBarIsOpaque) {
            [self setContentInset:0.0 scrollInset:0.0];
        } else {
            CGFloat contentInset = ForgeConstant.statusBarHeightDynamic + self.navigationBar.frame.size.height;
            CGFloat scrollInset = self.navigationBar.frame.size.height;
            [self setContentInset:contentInset scrollInset:scrollInset];
        }
    }];
}


#pragma mark Layout Helpers

- (void) layoutNavigationBar {
    if (self.navigationBarIsOpaque) {
        webViewTopConstraint.active = NO;
        [_webView.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor constant:0.0].active = YES;
    }

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


- (void) layoutToolbar {
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

- (void) setContentInset:(CGFloat) contentInset scrollInset:(CGFloat)scrollInset {
    UIEdgeInsets scrollEdgeInset  = self.webView.scrollView.scrollIndicatorInsets;
    UIEdgeInsets contentEdgeInset = self.webView.scrollView.contentInset;
    scrollEdgeInset = UIEdgeInsetsMake(scrollInset, scrollEdgeInset.left, scrollEdgeInset.bottom, scrollEdgeInset.right);
    contentEdgeInset = UIEdgeInsetsMake(contentInset, contentEdgeInset.left, contentEdgeInset.bottom, contentEdgeInset.right);
    self.webView.scrollView.scrollIndicatorInsets = scrollEdgeInset;
    self.webView.scrollView.contentInset = contentEdgeInset;
}


#pragma mark API

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
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.buttonPressed.%@", task.callid] withParam:[NSNull null]];
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

- (void) createNavigationBarVisualEffect:(UIView*)theWebView {
    // remove existing status bar blur effect
    [_navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [_navigationBar setShadowImage:[[UIImage alloc] init]];

    // create a replacement blur effect that covers both the status bar and navigation bar
    _blurView = [[UIView alloc] init];
    _blurView.userInteractionEnabled = NO;
    _blurView.backgroundColor = [UIColor clearColor];
    
    if (self.navigationBarIsOpaque == NO) {
        _blurViewVisualEffect = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
        _blurViewVisualEffect.userInteractionEnabled = NO;
        [_blurView addSubview:_blurViewVisualEffect];
    }
    
    [self.view insertSubview:_blurView aboveSubview:theWebView];

    // layout constraints
    _blurViewBottomConstraint = [NSLayoutConstraint constraintWithItem:_blurView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.navigationBar
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0f
                                                             constant:0.0f];
}


#pragma mark - WKHTTPCookieStoreObserver

- (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore  API_AVAILABLE(ios(11.0)){
    NSLog(@"tabs_WKWebViewController::cookiesDidChangeInCookieStore -> %@", cookieStore);
}


#pragma mark - Helpers

// Some configuration options can only be set before WKWebView is created which
// is rather silly given that Apple are so eager to have us use interface
//  builder to create our WKWebViews 🤡
- (void) recreateWebViewWithConfiguration:(WKWebViewConfiguration*)configuration {
    [self.webView removeFromSuperview];

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    [self.view insertSubview:self.webView belowSubview:_navigationBar];
    [self.view sendSubviewToBack:self.webView];

    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}


@end
