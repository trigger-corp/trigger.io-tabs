//
//  modalWebViewController.m
//  Forge
//
//  Created by Connor Dunn on 27/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "tabs_UIWebViewController.h"
#import "tabs_ConnectionDelegate.h"

#import "tabs_Delegate.h"
#import "tabs_API.h"


@implementation tabs_UIWebViewController
@synthesize navigationItem;
@synthesize title;

static ConnectionDelegate *connectionDelegate = nil;
static NSMutableArray* toolBarItems = nil;
static UIBarButtonItem *stop = nil;
static UIBarButtonItem *reload = nil;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // save app status bar style
    savedStatusBarStyle = [[[[UIApplication sharedApplication] keyWindow] rootViewController] preferredStatusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // restore app status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:savedStatusBarStyle animated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11.0, *)) {
        [self setAdditionalSafeAreaInsets:UIEdgeInsetsMake(navigationBar.frame.size.height, 0.0, 0.0, 0.0)];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];

    [backButton setTarget:self];
    [backButton setAction:@selector(cancel:)];

    // Start URL loading
    if (url == nil) {
        url = [NSURL URLWithString:@"about:blank"];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];

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
    [navigationItem setTitle:self.title];

    if (titleTint != nil && [navigationBar respondsToSelector:@selector(setTitleTextAttributes:)]) {
        [navigationBar setTitleTextAttributes:@{ NSForegroundColorAttributeName:titleTint }];
    }
    
    if (buttonTint != nil && [backButton respondsToSelector:@selector(setTintColor:)]) {
        [backButton setTintColor:buttonTint];
    }

    // Because safeAreas don't help squat if they're broken on iOS 11 and not supported on iOS 10
    if (@available(iOS 11.0, *)) {
        [self.webView.scrollView setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];
    }

    // Blurview
    [self createStatusBarVisualEffect:self.webView];
    if (tint != nil) {
        blurView.backgroundColor = tint;
    }
    blurViewVisualEffect.hidden = opaqueTopBar;

    // Page scaling
    if (self.scalePagesToFit == [NSNumber numberWithBool:YES]) {
        self.webView.scalesPageToFit = YES;
    }

    // Navigation toolbar
    navigationToolbar = [[tabs_NavigationToolbar alloc] initForWebViewController:self];
    if (self.enableNavigationToolbar == [NSNumber numberWithBool:YES]) {
        [self setNavigationToolbarHidden:NO];
    } else {
        [self setNavigationToolbarHidden:YES];
    }
    [self.view insertSubview:navigationToolbar aboveSubview:self.webView];
    [self layoutNavigationToolbar];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return statusBarStyle;
}


- (void)setOpaqueTopBar:(bool)newOpaqueTopBar {
    opaqueTopBar = newOpaqueTopBar;
}


- (void)createStatusBarVisualEffect:(UIView*)theWebView {
    // remove existing status bar blur effect
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc]init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc]init]];

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
                                                               toItem:navigationBar
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


- (void)layoutNavigationToolbar {
    navigationToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [navigationToolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [navigationToolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    if (@available(iOS 11.0, *)) {
        [navigationToolbar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [navigationToolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
            [self setNavigationToolbarHidden:YES];
        } else {
            [self setNavigationToolbarHidden:NO];
        }
    }

    // refresh safe area insets once rotation is complete
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (@available(iOS 11.0, *)) {
            [self setAdditionalSafeAreaInsets:UIEdgeInsetsMake(navigationBar.frame.size.height, 0.0, 0.0, 0.0)];
        }
    }];
}


- (void)setNavigationToolbarHidden:(BOOL)hidden
{
    [navigationToolbar setHidden:hidden];
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
    }
}


- (void) viewDidDisappear:(BOOL)animated {
    // Make sure the network indicator is turned off
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // release our connection delegate so it can be garbage collected
    [connectionDelegate releaseDelegate];
    connectionDelegate = nil;

    if (returnObj != nil) {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.closed", task.callid] withParam:returnObj];
    } else {
        [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.closed", task.callid] withParam:@{
            @"userCancelled": [NSNumber numberWithBool:YES]
        }];
    }

    [super viewDidDisappear:animated];
}


- (void)stringByEvaluatingJavaScriptFromString:(ForgeTask*)evalTask string:(NSString*)string {
    [evalTask success:[self.webView stringByEvaluatingJavaScriptFromString:string]];
}


- (void)cancel:(id)nothing {
    returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithBool:YES], @"userCancelled",
                 nil];

    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)setUrl:(NSURL*)newUrl {
    url = newUrl;
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

- (BOOL)matchesPattern:(NSURL *)urlToCheck {
    if (pattern == nil) {
        return NO;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSString *urlStr = [urlToCheck absoluteString];

    return [regex numberOfMatchesInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])] > 0;
}

- (void)setTitleTintColor:(UIColor *)newTint {
    titleTint = newTint;
}


- (void)setTintColor:(UIColor *)newTint {
    tint = newTint;
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
        [self dismissViewControllerAnimated:YES completion:nil];

        return NO;
    }

    // check return pattern
    if ([self matchesPattern:thisurl]) {
        [ForgeLog w:[NSString stringWithFormat:@"Encountered url matching pattern, closing the tab now: %@", thisurl]];
        returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                [thisurl absoluteString],
                @"url",
                [NSNumber numberWithBool:NO],
                @"userCancelled",
                        nil];

        [self dismissViewControllerAnimated:YES completion:nil];

        return NO;
    }

    // we're done if basic auth is not enabled
    if (self.enableBasicAuth == [NSNumber numberWithBool:NO]) {
        return YES;
    }

    // we're done if this is not a HTTPS site and we're not set to be insecure for testing purposes
    if (![[thisurl scheme] isEqualToString:@"https"] && self.enableInsecureBasicAuth == [NSNumber numberWithBool:NO]) {
        [ForgeLog w:@"Basic Auth is only supported for sites served over https"];
        return YES;
    }

    // otherwise, delegate remaining processing for request
    if (connectionDelegate == nil) {
        connectionDelegate = [[ConnectionDelegate alloc] initWithModalView:self webView:self.webView pattern:pattern];
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


- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (navigationToolbar != nil) {
        [navigationToolbar webViewDidStartLoad:webView];
    }
    if (self.title == nil || [self.title isEqualToString:@""]) {
        [navigationItem setTitle:@""];
    }
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadStarted", task.callid] withParam:@{@"url": self.webView.request.URL.absoluteString}];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (navigationToolbar != nil) {
        [navigationToolbar webViewDidFinishLoad:webView];
    }
    if (self.title == nil || [self.title isEqualToString:@""]) {
        NSString *documentTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [navigationItem setTitle:documentTitle];
    }
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadFinished", task.callid] withParam:@{@"url": self.webView.request.URL.absoluteString}];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (navigationToolbar != nil) {
        [navigationToolbar webView:webView didFailLoadWithError:error];
    }
    if (error.code == -1009) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error loading"
                                                        message:@"No Internet connection available."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    if (error.code == 102) { // loading interupted
        NSString *urlStr = [error.userInfo objectForKey:@"NSErrorFailingURLStringKey"];
        NSURL *failedRequestURL = [NSURL URLWithString:urlStr];

        // If we haven't done yet, we retry to load the failed url
        // Note: The 102 error can happen for various reasons, so we want to retry first to make sure we really can't open it "inline"
        if (![urlStr isEqualToString:retryUrl]) {
            retryUrl = urlStr;
            [ForgeLog w:[NSString stringWithFormat:@"Retry to load url: %@", urlStr]];
            [self.webView loadRequest:[NSURLRequest requestWithURL:failedRequestURL]];
        }
        
        // Retry failed, determine if the system can deal with the it. If so, open it with the appropriate application
        // Example: ics, vcf -> Calendar
        else if (![self matchesPattern:failedRequestURL] && [[UIApplication sharedApplication]canOpenURL:failedRequestURL]) {
           [ForgeLog w:[NSString stringWithFormat:@"Open url by external app: %@", urlStr]];
           [[UIApplication sharedApplication]openURL:failedRequestURL];
        }
    }
    [ForgeLog w:[NSString stringWithFormat:@"Modal webview error: %@", error]];
    [[ForgeApp sharedApp] event:[NSString stringWithFormat:@"tabs.%@.loadError", task.callid] withParam:@{@"url": self.webView.request.URL.absoluteString, @"description": error.description}];
}


-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}


-(void)close {
    returnObj = [NSDictionary dictionaryWithObjectsAndKeys:
                 self.webView.request.URL.absoluteString,
                 @"url",
                 [NSNumber numberWithBool:NO],
                 @"userCancelled",
                 nil
                 ];

    [self dismissViewControllerAnimated:YES completion:nil];
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
    

    UINavigationItem *navItem = ((UINavigationItem*)[navigationBar.items objectAtIndex:0]);
    if (newPosition != nil && [newPosition isEqualToString:@"right"]) {
        [navItem setRightBarButtonItem:buttonItem];
    } else {
        [navItem setLeftBarButtonItem:buttonItem];
    }

    [newTask success:newTask.callid];
}


-(void)removeButtonsWithTask:(ForgeTask*)newTask {
    UINavigationItem *navItem = ((UINavigationItem*)[navigationBar.items objectAtIndex:0]);

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


- (void)setTitleWithTask:(ForgeTask*)newTask title:(NSString*)newTitle {
    self.title = newTitle;
    [navigationItem setTitle:title];
    [newTask success:nil];
}


- (void) forceUpdateWebView {
    CGRect f = self.webView.frame;
    self.webView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width + 1, f.size.height + 1);
    self.webView.frame = f;
}

@end
