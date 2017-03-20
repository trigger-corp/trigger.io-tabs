//
//  modalWebViewController.h
//  Forge
//
//  Created by Connor Dunn on 27/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface tabs_modalWebViewController : UIViewController <UIWebViewDelegate, UIBarPositioningDelegate> {
	IBOutlet UIWebView *webView;
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UINavigationBar *navBar;
	NSURL *url;
	UIViewController *rootView;

	NSString *backLabel;
    NSString *backImage;
    UIColor *buttonTint;

	NSString *title;
	UINavigationItem *navigationItem;
	ForgeTask *task;
	NSString *pattern;
	UIColor *tint;
	UIColor *titleTint;
    bool translucent;
    UIStatusBarStyle statusBarStyle;
    UIStatusBarStyle savedStatusBarStyle;
    
	NSDictionary *returnObj;
}

@property (nonatomic, strong) IBOutlet NSNumber* enableBasicAuth;

@property (nonatomic, strong) IBOutlet UINavigationItem *navigationItem;

- (void)setUrl:(NSURL*)newUrl;
- (void)setRootView:(UIViewController*)newRootView;

- (void)setBackLabel:(NSString *)newLabel;
- (void)setBackImage:(NSString *)newImage;
- (void)setButtonTintColor:(UIColor *)newTint;

- (void)setTitle:(NSString *)newTitle;
- (void)setTitleTintColor:(UIColor *)newTint;
- (void)setTintColor:(UIColor *)newTint;
- (void)setTranslucent:(bool)newTranslucent;
- (void)setStatusBarStyle:(UIStatusBarStyle)newStatusBarStyle;
- (void)setTask:(ForgeTask *)newTask;
- (void)setPattern:(NSString *)newPattern;
- (void)cancel:(id)nothing;
- (void)stringByEvaluatingJavaScriptFromString:(ForgeTask*)evalTask string:(NSString*)string;
- (void)close;

- (void)addButtonWithTask:(ForgeTask*)newTask text:(NSString*)newText icon:(NSString*)newIcon position:(NSString*)newPosition style:(NSString*)newStyle tint:(UIColor*)newTint;
- (void)removeButtons:(ForgeTask*)newTask;

@end

