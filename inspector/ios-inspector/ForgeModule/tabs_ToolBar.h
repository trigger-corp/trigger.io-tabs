//
//  tabs_ToolBar.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/21.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class tabs_ActivityPopover;
@class tabs_WKWebViewController;

@interface tabs_ToolBar : UIToolbar {
    bool _hasStartedLoading;
}

@property (strong, nonatomic) tabs_WKWebViewController *viewController;

@property (strong, nonatomic) UIBarButtonItem *stopButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;
@property (strong, nonatomic) UIBarButtonItem *actionButton;

- initWithViewController:(tabs_WKWebViewController*)viewController;

// WKNavigationDelegate
- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;
- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;
- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error;

@end
