//
//  tabs_API.m
//  Forge
//
//  Created by Connor Dunn on 14/03/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "tabs_API.h"
#import "tabs_modalView.h"

@implementation tabs_API

+ (void)open:(ForgeTask*)task {
	if (![task.params objectForKey:@"url"]) {
		[task error:@"Missing url" type:@"BAD_INPUT" subtype:nil];
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		tabs_modalView *owner = [[tabs_modalView alloc] initWithTask:task];
		
		[NSBundle loadNibNamed:@"tabs" owner:owner];
		
		// Make the modal view nearly as big as the main window		
		[[owner window] setFrame:NSMakeRect(0, 0, [[[[ForgeApp sharedApp] appDelegate] window] frame].size.width-100, [[[[ForgeApp sharedApp] appDelegate] window] frame].size.height-50) display:NO];
		
		[NSApp beginSheet:[owner window] modalForWindow:[[[ForgeApp sharedApp] appDelegate] window] modalDelegate:owner	didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];

		[[[owner webView] mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[task.params objectForKey:@"url"]]]];
	});
}
@end
