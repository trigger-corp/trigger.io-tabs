//
//  tabs_ToolbarBar.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/21.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "tabs_ToolBar.h"
#import "tabs_ActivityPopover.h"

#import "tabs_WKWebViewController.h"

@implementation tabs_ToolBar

- initWithViewController:(tabs_WKWebViewController*)viewController {
    self = [super init];
    if (self) {
        _hasStartedLoading = NO;
        self.viewController = viewController;
        [self createToolbar];
    }
    return self;
}


- (void)createToolbar {
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                    target:self.viewController.webView
                                                                    action:@selector(stopLoading)];
    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self.viewController.webView
                                                                      action:@selector(reload)];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[self backImage]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self.viewController.webView
                                                      action:@selector(goBack)];
    self.backButton.enabled = NO;
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[self forwardImage]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self.viewController.webView
                                                         action:@selector(goForward)];
    self.forwardButton.enabled = NO;
    self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                      target:self
                                                                      action:@selector(action:)];

    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];

    [self setItems:@[self.backButton, space, self.forwardButton, space, self.actionButton, space, self.stopButton]];
}


- (UIImage *)backImage {
    static UIImage *image;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        CGFloat width = 12.0f;
        CGFloat height = 20.0f;
        CGSize size = CGSizeMake(width, height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(width * 5.0/6.0, height * 0.0/10.0)];
        [path addLineToPoint:CGPointMake(width * 0.0/6.0, height * 5.0/10.0)];
        [path addLineToPoint:CGPointMake(width * 5.0/6.0, height * 10.0/10.0)];
        [path addLineToPoint:CGPointMake(width * 6.0/6.0, height * 9.0/10.0)];
        [path addLineToPoint:CGPointMake(width * 2.0/6.0, height * 5.0/10.0)];
        [path addLineToPoint:CGPointMake(width * 6.0/6.0, height * 1.0/10.0)];
        [path closePath];
        [path fill];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}


- (UIImage *)forwardImage {
    static UIImage *rightTriangleImage;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        UIImage *leftTriangleImage = [self backImage];
        CGSize size = leftTriangleImage.size;
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGFloat x_mid = size.width / 2.0f;
        CGFloat y_mid = size.height / 2.0f;
        CGContextTranslateCTM(context, x_mid, y_mid);
        CGContextRotateCTM(context, M_PI);
        [leftTriangleImage drawAtPoint:CGPointMake((x_mid * -1), (y_mid * -1))];
        rightTriangleImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return rightTriangleImage;
}


- (void)action:(id)sender {
    NSURL *url = self.viewController.webView.URL;
    if (_hasStartedLoading == NO || url == nil || [[url absoluteString] isEqualToString:@""]){
        return;
    }

    [tabs_ActivityPopover presentWithViewController:self.viewController
        barButtonItem:self.items[4]
        completion:^(UIActivityType activityType, BOOL completed, NSArray * returnedItems, NSError * activityError) {

    }];
}


- (void)toggleState {
    NSURL *url = self.viewController.webView.URL;
    self.actionButton.enabled = _hasStartedLoading && url != nil && ![[url absoluteString] isEqualToString:@""];
    self.backButton.enabled = self.viewController.webView.canGoBack;
    self.forwardButton.enabled = self.viewController.webView.canGoForward;
    NSMutableArray *toolbarItems = [self.items mutableCopy];
    if (self.viewController.webView.loading) {
        toolbarItems[6] = self.stopButton;
    } else {
        toolbarItems[6] = self.reloadButton;
    }
    self.items = [toolbarItems copy];
}


#pragma mark - WKNavigationDelegate

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    _hasStartedLoading = YES;
    [self toggleState];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self toggleState];
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self toggleState];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self toggleState];
}

@end
