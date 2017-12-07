//
//  tabs_NavigationToolbar.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/21.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class tabs_modalWebViewController;

@interface tabs_NavigationToolbar : UIToolbar <UIPopoverControllerDelegate> {
    bool _hasStartedLoading;
}

@property (strong, nonatomic) tabs_modalWebViewController *webViewController;

@property (strong, nonatomic) UIBarButtonItem *stopButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;
@property (strong, nonatomic) UIBarButtonItem *actionButton;

@property (strong, nonatomic) UIPopoverController *popoverController;
@property (strong, nonatomic) NSArray *applicationActivities;


- initForWebViewController:(tabs_modalWebViewController*)webViewController;

- (void)webViewDidStartLoad:(UIWebView *)webView;
- (void)webViewDidFinishLoad:(UIWebView *)webView;
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;

@end
