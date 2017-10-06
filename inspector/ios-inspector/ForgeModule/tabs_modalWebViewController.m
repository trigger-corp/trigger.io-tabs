//
//  modalWebViewController.m
//  Forge
//
//  Created by Connor Dunn on 27/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "tabs_modalWebViewController.h"
#import "tabs_Delegate.h"
#import "tabs_ConnectionDelegate.h"
#import "tabs_API.h"

@implementation tabs_modalWebViewController
@synthesize navigationItem;
@synthesize title;

static ConnectionDelegate *connectionDelegate = nil;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if ( self.presentedViewController) {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // save app status bar style
    savedStatusBarStyle = [[[[UIApplication sharedApplication] keyWindow] rootViewController] preferredStatusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // restore app status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:savedStatusBarStyle animated:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [backButton setAction:@selector(cancel:)];

    if (url == nil) {
        url = [NSURL URLWithString:@"about:blank"];
    }
    [webView loadRequest:[NSURLRequest requestWithURL:url]];

    if (backImage != nil) {
        [[[ForgeFile alloc] initWithObject:backImage] data:^(NSData *data) {
            UIImage *icon = [[UIImage alloc] initWithData:data];
            icon = [icon imageWithWidth:0 andHeight:28 andRetina:YES];
            [backButton setImage:icon];

        } errorBlock:^(NSError *error) {
        }];
    } else {
        [backButton setTitle:backLabel];
    }
    [navigationItem setTitle:title];

    navBar.translucent = translucent;

    if (tint != nil && [navBar respondsToSelector:@selector(setBarTintColor:)]) {
        [navBar setBarTintColor:tint];
    } else if (tint != nil && [navBar respondsToSelector:@selector(setTintColor:)]) {
        [navBar setTintColor:tint];
    }

    if (titleTint != nil && [navBar respondsToSelector:@selector(setTitleTextAttributes:)]) {
        [navBar setTitleTextAttributes:@{ NSForegroundColorAttributeName:titleTint }];
    }
    
    if (buttonTint != nil && [backButton respondsToSelector:@selector(setTintColor:)]) {
        [backButton setTintColor:buttonTint];
    }

    // Workaround for buggy auto layout implementation on iOS < 11
    if (@available(iOS 11.0, *)) {
        navBarTopConstraint = [NSLayoutConstraint constraintWithItem:navBar
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.view.safeAreaLayoutGuide
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:0.0f];
    } else {
        navBarTopConstraint = [NSLayoutConstraint constraintWithItem:navBar
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.topLayoutGuide
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:ForgeConstant.statusBarHeightDynamic];
    }
    navBarTopConstraint.active = YES;

    // Disable automatic content inset adjustment
    if (@available(iOS 11.0, *)) {
        [webView.scrollView setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];
    }

    // Set content insets
    CGFloat insetHeight = ForgeConstant.statusBarHeightDynamic + ForgeConstant.navigationBarHeightStatic;
    [webView.scrollView setContentInset:UIEdgeInsetsMake(insetHeight, 0, 0, 0)];
    [webView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(insetHeight, 0, 0, 0)];

    [self createStatusBarVisualEffect:webView];
}


- (void)createStatusBarVisualEffect:(UIView*)theWebView {
    // remove existing status bar blur effect
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc]init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc]init]];
    //navigationBar.translucent = YES;

    // create a replacement blur effect that covers both the status bar and navigation bar
    blurView = [[UIView alloc] init];
    blurView.userInteractionEnabled = NO;
    blurView.backgroundColor = [UIColor clearColor];
    blurViewVisualEffect = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    blurViewVisualEffect.userInteractionEnabled = NO;
    [blurView addSubview:blurViewVisualEffect];
    [self.view insertSubview:blurView aboveSubview:theWebView];

    // layout
    blurViewBottomConstraint = [NSLayoutConstraint constraintWithItem:blurView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:navBar
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0f
                                                             constant:0.0f];
    blurViewBottomConstraint.active = YES;
    [self layoutStatusBarVisualEffect];
}


- (void)layoutStatusBarVisualEffect {
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [blurView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    blurViewBottomConstraint.constant = 0.0f;

    blurViewVisualEffect.translatesAutoresizingMaskIntoConstraints = NO;
    [blurViewVisualEffect.leadingAnchor constraintEqualToAnchor:blurView.leadingAnchor].active = YES;
    [blurViewVisualEffect.trailingAnchor constraintEqualToAnchor:blurView.trailingAnchor].active = YES;
    [blurViewVisualEffect.topAnchor constraintEqualToAnchor:blurView.topAnchor].active = YES;
    [blurViewVisualEffect.bottomAnchor constraintEqualToAnchor:blurView.bottomAnchor].active = YES;
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // refresh content insets once rotation is complete
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
        if (@available(iOS 11.0, *)) {
            insets = self.view.safeAreaInsets; // currently this only matters for the iPhone-X
        }
        NSLog(@"SIDE INSETS: %f -> %f", insets.left, insets.right);
        CGFloat insetHeight = ForgeConstant.statusBarHeightDynamic + ForgeConstant.navigationBarHeightStatic;
        [webView.scrollView setContentInset:UIEdgeInsetsMake(insetHeight, 0, 0, 0)];
        [webView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(insetHeight, 0, 0, 0)];
        webView.frame = CGRectMake(insets.left, webView.frame.origin.y, ForgeConstant.screenWidth - (insets.left + insets.right), webView.frame.size.height);
    }];
}


- (void) viewDidDisappear:(BOOL)animated {
    // Make sure the network indicator is turned off
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // release our connection delegate so it can be garbage collected
    [connectionDelegate releaseDelegate];
    connectionDelegate = nil;

    if (returnObj != nil) {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.closed", task.callid] withParam:returnObj];
    }
}


- (void)stringByEvaluatingJavaScriptFromString:(ForgeTask*)evalTask string:(NSString*)string {
    [evalTask success:[webView stringByEvaluatingJavaScriptFromString:string]];
}


- (void)cancel:(id)nothing {
    returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithBool:YES], @"userCancelled",
                 nil];

    [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:nil];
    [[[ForgeApp sharedApp] viewController] performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];
}


- (void)setUrl:(NSURL*)newUrl {
    url = newUrl;
}


- (void)setRootView:(UIViewController*)newRootView {
    rootView = newRootView;
}


- (void)setTitle:(NSString *)newTitle {
    title = newTitle;
}


- (void)setBackLabel:(NSString *)newLabel {
    backLabel = newLabel;
}


- (void)setBackImage:(NSString *)newImage {
    backImage = newImage;
}


- (void)setButtonTintColor:(UIColor *)newTint {
    buttonTint = newTint;
}


- (void)setTask:(ForgeTask *)newTask {
    task = newTask;
}


- (ForgeTask*)getTask {
    return task;
}


- (void)setReturnObj:(NSDictionary *)newReturnObj {
    returnObj = newReturnObj;
}


- (void)setPattern:(NSString *)newPattern {
    pattern = newPattern;
}


- (void)setTitleTintColor:(UIColor *)newTint {
    titleTint = newTint;
}


- (void)setTintColor:(UIColor *)newTint {
    tint = newTint;
}


- (void)setTranslucent:(bool)newTranslucent {
    translucent = newTranslucent;
}


- (void)setStatusBarStyle:(UIStatusBarStyle)newStatusBarStyle {
    statusBarStyle = newStatusBarStyle;
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


- (BOOL)webView:(UIWebView *)myWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *thisurl = [request URL];

    // handle forge:// URLs
    if ([[thisurl scheme] isEqualToString:@"forge"]) {
        if ([[thisurl absoluteString] isEqualToString:@"forge://go"]) {
            // See if URL is whitelisted - only allow forge API access on trusted pages
            BOOL safe = NO;
            for (NSString *whitelistedPattern in (NSArray*)[[[[[ForgeApp sharedApp] appConfig] objectForKey:@"core"] objectForKey:@"general"] objectForKey:@"trusted_urls"]) {
                if ([ForgeUtil url:[myWebView.request.URL absoluteString] matchesPattern:whitelistedPattern]) {
                    [ForgeLog d:[NSString stringWithFormat:@"Allowing forge JavaScript API access for whitelisted URL in tabs browser: %@", [url absoluteString]]];
                    safe = YES;
                    break;
                }
            }
            if (!safe) {
                return NO;
            }

            [myWebView stringByEvaluatingJavaScriptFromString:@"window.forge._flushingInterval && clearInterval(window.forge._flushingInterval)"];
            NSString *jsResult;
            do {
                // Get the Javascript call queue
                jsResult = [myWebView stringByEvaluatingJavaScriptFromString:@"window.forge._get()"];

                // Loop over each of the returned objects
                for (NSDictionary* object in [jsResult objectFromJSONString]) {
                    [ForgeLog d:[NSString stringWithFormat:@"Native call in modal view: %@", object]];
                    [BorderControl runTask:object forWebView:myWebView];
                }
            } while ([jsResult length] > 4);
            [myWebView stringByEvaluatingJavaScriptFromString:@"window.forge._flushing = false;"];

            // Prevent page load
            return NO;
        }

        returnObj = [NSDictionary dictionary];
        [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:nil];
        [[[ForgeApp sharedApp] viewController] performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];

        return NO;
    }

    // check return pattern
    if (pattern != nil) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        if ([regex numberOfMatchesInString:[thisurl absoluteString] options:0 range:NSMakeRange(0, [[thisurl absoluteString] length])] > 0) {
            returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                         [thisurl absoluteString],
                         @"url",
                         [NSNumber numberWithBool:NO],
                         @"userCancelled",
                         nil];
            
            [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:nil];
            [[[ForgeApp sharedApp] viewController] performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];

            return NO;
        }
    }

    // we're done if basic auth is not enabled
    if (self.enableBasicAuth == [NSNumber numberWithBool:NO]) {
        return YES;
    }

    // otherwise, delegate remaining processing for request
    if (connectionDelegate == nil) {
        connectionDelegate = [[ConnectionDelegate alloc] initWithModalView:self webView:webView pattern:pattern];
        if ([task.params objectForKey:@"basicAuthConfig"]) {
            NSDictionary *cfg = [task.params objectForKey:@"basicAuthConfig"];
            connectionDelegate->i8n.title = [cfg objectForKey:@"titleText"] ?: connectionDelegate->i8n.title;
            connectionDelegate->i8n.usernameHint = [cfg objectForKey:@"usernameHintText"] ?: connectionDelegate->i8n.usernameHint;
            connectionDelegate->i8n.passwordHint = [cfg objectForKey:@"passwordHintText"] ?: connectionDelegate->i8n.passwordHint;
            connectionDelegate->i8n.loginButton = [cfg objectForKey:@"loginButtonText"] ?: connectionDelegate->i8n.loginButton;
            connectionDelegate->i8n.cancelButton = [cfg objectForKey:@"cancelButtonText"] ?: connectionDelegate->i8n.cancelButton;
            if ([cfg objectForKey:@"closeTabOnCancel"] != nil) {
                connectionDelegate->closeTabOnCancel = [[cfg objectForKey:@"closeTabOnCancel"] boolValue];
            }
            if ([cfg objectForKey:@"useCredentialStorage"] != nil) {
                connectionDelegate->useCredentialStorage = [[cfg objectForKey:@"useCredentialStorage"] boolValue];
            }
            if ([cfg objectForKey:@"verboseLogging"] != nil) {
                connectionDelegate->verboseLogging = [[cfg objectForKey:@"verboseLogging"] boolValue];
            }
            if ([cfg objectForKey:@"retryFailedLogin"] != nil) {
                connectionDelegate->retryFailedLogin = [[cfg objectForKey:@"retryFailedLogin"] boolValue];
            }
        }
    }

    return [connectionDelegate handleRequest:request];
}


- (void)webViewDidStartLoad:(UIWebView *)_webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadStarted", task.callid] withParam:@{@"url": webView.request.URL.absoluteString}];
}


- (void)webViewDidFinishLoad:(UIWebView *)_webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadFinished", task.callid] withParam:@{@"url": webView.request.URL.absoluteString}];
}


- (void)webView:(UIWebView *)myWebView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (error.code == -1009) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error loading"
                                                        message:@"No Internet connection available."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [ForgeLog w:[NSString stringWithFormat:@"Modal webview error: %@", error]];
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadError", task.callid] withParam:@{@"url": webView.request.URL.absoluteString, @"description": error.description}];
}


-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}


-(void)close {
    returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                 webView.request.URL.absoluteString,
                 @"url",
                 [NSNumber numberWithBool:NO],
                 @"userCancelled",
                 nil
                 ];

    [[[ForgeApp sharedApp] viewController] dismissViewControllerAnimated:YES completion:nil];
    [[[ForgeApp sharedApp] viewController] performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];
}


- (BOOL)prefersStatusBarHidden {
    return [[ForgeApp sharedApp].viewController prefersStatusBarHidden];
}


-(void)addButtonWithTask:(ForgeTask*)newTask text:(NSString*)newText icon:(NSString*)newIcon position:(NSString*)newPosition style:(NSString*)newStyle tint:(UIColor*)newTint {
    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] init];

    if (newStyle != nil && [newStyle isEqualToString:@"done"]) {
        [buttonItem setStyle:UIBarButtonItemStyleDone];
    } else {
        [buttonItem setStyle:UIBarButtonItemStyleBordered];
    }

    if (newText != nil) {
        [buttonItem setTitle:newText];

    } else if (newIcon != nil) {
        [[[ForgeFile alloc] initWithObject:newIcon] data:^(NSData *data) {
            UIImage *icon = [[UIImage alloc] initWithData:data];
            icon = [icon imageWithWidth:0 andHeight:28 andRetina:YES];
            [buttonItem setImage:icon];
        } errorBlock:^(NSError *error) {
        }];

    } else {
        [task error:@"You need to specify either a 'text' or 'icon' property for your button."];
        return;
    }

    if (newTint != nil) {
        [buttonItem setTintColor:newTint];
    }

    tabs_Delegate* delegate = [[tabs_Delegate alloc] initWithId:newTask.callid];
    [buttonItem setTarget:delegate];
    [buttonItem setAction:@selector(clicked)];
    

    UINavigationItem *navItem = ((UINavigationItem*)[navBar.items objectAtIndex:0]);
    if (newPosition != nil && [newPosition isEqualToString:@"right"]) {
        [navItem setRightBarButtonItem:buttonItem];
    } else {
        [navItem setLeftBarButtonItem:buttonItem];
    }

    [newTask success:newTask.callid];
}


-(void)removeButtons:(ForgeTask*)newTask {
    UINavigationItem *navItem = ((UINavigationItem*)[navBar.items objectAtIndex:0]);

    if (navItem.leftBarButtonItem.target != nil) {
        [((tabs_Delegate*)navItem.leftBarButtonItem.target) releaseDelegate];
    }
    [navItem setLeftBarButtonItem:nil];

    if (navItem.rightBarButtonItem.target != nil) {
        [((tabs_Delegate*)navItem.rightBarButtonItem.target) releaseDelegate];
    }
    [navItem setRightBarButtonItem:nil];


    [newTask success:nil];
}

@end
