//
//  tabs_API.m
//  Forge
//
//  Created by Connor Dunn on 14/03/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "tabs_API.h"
#import "tabs_modalWebViewController.h"

static NSMutableDictionary* tabs_modal_map;

@implementation tabs_API

+ (void)open:(ForgeTask*)task {
	if (![task.params objectForKey:@"url"]) {
		[task error:@"Missing url" type:@"BAD_INPUT" subtype:nil];
		return;
	}
	
	tabs_modalWebViewController *modalView = [[tabs_modalWebViewController alloc] initWithNibName:@"tabs_modalWebViewController" bundle:[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"tabs" ofType:@"bundle"]]];

	[modalView setUrl:[NSURL URLWithString:[task.params objectForKey:@"url"]]];
	
	[modalView setPattern:[task.params objectForKey:@"pattern"]];
	[modalView setRootView:[[ForgeApp sharedApp] viewController]];
	if ([task.params objectForKey:@"title"] != nil) {
		[modalView setTitle:[task.params objectForKey:@"title"]];
	} else {
		[modalView setTitle:@""];
	}
	if ([task.params objectForKey:@"buttonIcon"] != nil) {
		[modalView setBackImage:[task.params objectForKey:@"buttonIcon"]];
	} else if ([task.params objectForKey:@"buttonText"] != nil) {
		[modalView setBackLabel:[task.params objectForKey:@"buttonText"]];
	} else {
		[modalView setBackLabel:@"Close"];
	}
	if ([task.params objectForKey:@"tint"] != nil) {
		NSArray* color = [task.params objectForKey:@"tint"];
		[modalView setTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255 green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255 blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255 alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
	}
    if ([task.params objectForKey:@"titleTint"] != nil) {
        NSArray* color = [task.params objectForKey:@"titleTint"];
        [modalView setTitleTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255 green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255 blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255 alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
    }
	if ([task.params objectForKey:@"buttonTint"] != nil) {
		NSArray* color = [task.params objectForKey:@"buttonTint"];
		[modalView setButtonTintColor:[UIColor colorWithRed:[(NSNumber*)[color objectAtIndex:0] floatValue]/255 green:[(NSNumber*)[color objectAtIndex:1] floatValue]/255 blue:[(NSNumber*)[color objectAtIndex:2] floatValue]/255 alpha:[(NSNumber*)[color objectAtIndex:3] floatValue]/255]];
	}
    if ([task.params objectForKey:@"translucent"] != nil) {
        [modalView setTranslucent:[[task.params objectForKey:@"translucent"] boolValue]];
    } else {
        [modalView setTranslucent:true];
    }
	
	[modalView setTask:task];
	
	[[[ForgeApp sharedApp] viewController] presentModalViewController:modalView animated:YES];
	
	[task success:task.callid];
	
	if (tabs_modal_map == nil) {
		tabs_modal_map = [[NSMutableDictionary alloc] init];
	}
	[tabs_modal_map setObject:[NSValue valueWithNonretainedObject:modalView] forKey:task.callid];
}

+ (void)executeJS:(ForgeTask*)task modal:(NSString*)modal script:(NSString*)script {
	[[((NSValue *)[tabs_modal_map objectForKey:modal]) nonretainedObjectValue] stringByEvaluatingJavaScriptFromString:task string:script];
}

+ (void)close:(ForgeTask*)task modal:(NSString*)modal {
	[[((NSValue *)[tabs_modal_map objectForKey:modal]) nonretainedObjectValue] close];
	[task success:nil];
}

@end
