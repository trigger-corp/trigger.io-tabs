//
//  tabs_modalView.m
//  ForgeModule
//
//  Created by Connor Dunn on 20/03/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import "tabs_modalView.h"

@implementation tabs_modalView

- (id)initWithTask:(ForgeTask*) newTask {
    self = [super init];
    if (self) {
		task = newTask;
        me = self;
		
		timer = [NSTimer scheduledTimerWithTimeInterval:0.1
												 target:self
											   selector:@selector(updateProgress)
											   userInfo:nil
												repeats:YES];
    }
    return self;
}

- (IBAction) closeClicked:(id) sender {
	[task success:@{@"url": [[[[[[self webView] mainFrame] dataSource] request] URL] absoluteString], @"userCancelled": @YES}];
	[NSApp endSheet:[self window]];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
	me = nil;
}

- (void) updateProgress {
	if (me == nil) {
		[timer invalidate];
		return;
	}
	if ([[self webView] estimatedProgress] == 0) {
		[[self progressBar] setHidden:YES];
	} else {
		[[self progressBar] setHidden:NO];
		[[self progressBar] setDoubleValue:[[self webView] estimatedProgress]*100];
	}
}

@end
