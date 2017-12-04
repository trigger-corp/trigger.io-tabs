//
//  tabs_NavigationToolbar.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/21.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import "tabs_NavigationToolbar.h"
#import "tabs_Activities.h"

#import "tabs_modalWebViewController.h"

@implementation tabs_NavigationToolbar

- initForWebViewController:(tabs_modalWebViewController*)webViewController
{
    self = [super init];
    if (self) {
        self.webViewController = webViewController;
        [self createToolbar];
    }
    return self;
}


- (void)createToolbar
{

    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                    target:self.webViewController.webView
                                                                    action:@selector(stopLoading)];
    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self.webViewController.webView
                                                                      action:@selector(reload)];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[self backImage]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self.webViewController.webView
                                                      action:@selector(goBack)];
    self.backButton.enabled = NO;
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[self forwardImage]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self.webViewController.webView
                                                         action:@selector(goForward)];
    self.forwardButton.enabled = NO;
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                  target:self
                                                                                  action:@selector(action:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];

    [self setItems:@[self.backButton, space , self.forwardButton, space, actionButton, space, self.stopButton]];


    tabs_SafariActivity *safari = [[tabs_SafariActivity alloc] init];
    tabs_ChromeActivity *chrome = [[tabs_ChromeActivity alloc] init];
    self.applicationActivities = @[safari,chrome];
}


- (UIImage *)backImage
{
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

- (UIImage *)forwardImage
{
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


#pragma mark - Action button

- (void)action:(id)sender
{
    if (self.popoverController.popoverVisible) {
        [self.popoverController dismissPopoverAnimated:YES];
        return;
    }

    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[self.webViewController.webView.request.URL]
                                                                     applicationActivities:self.applicationActivities];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.webViewController presentViewController:vc animated:YES completion:NULL];
    } else {
        if (!self.popoverController) {
            self.popoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
        }
        self.popoverController.delegate = self;
        [self.popoverController presentPopoverFromBarButtonItem:self.items[4]
                                       permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)toggleState
{
    self.backButton.enabled = self.webViewController.webView.canGoBack;
    self.forwardButton.enabled = self.webViewController.webView.canGoForward;
    NSMutableArray *toolbarItems = [self.items mutableCopy];
    if (self.webViewController.webView.loading) {
        toolbarItems[6] = self.stopButton;
    } else {
        toolbarItems[6] = self.reloadButton;
    }
    self.items = [toolbarItems copy];
}


#pragma mark - Web view delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self toggleState];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self toggleState];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self toggleState];
}

#pragma mark - Popover controller delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popoverController = nil;
}


@end
