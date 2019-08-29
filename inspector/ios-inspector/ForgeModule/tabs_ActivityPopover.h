//
//  tabs_Activities.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2017/11/22.
//  Copyright © 2017 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "tabs_WKWebViewController.h"


@interface tabs_ActivityPopover : UIActivityViewController <UIPopoverPresentationControllerDelegate>
+ (void) presentWithViewController:(tabs_WKWebViewController * _Nonnull)viewController
                     barButtonItem:(UIBarButtonItem * _Nonnull)barButtonItem
                        completion:(UIActivityViewControllerCompletionWithItemsHandler)completion;
@end


@interface tabs_SafariActivity : UIActivity {
    NSURL *url;
}
@end


@interface tabs_ChromeActivity : UIActivity {
    NSURL *url;
}
@end


