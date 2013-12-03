//
//  tabs_modalView.h
//  ForgeModule
//
//  Created by Connor Dunn on 20/03/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface tabs_modalView : NSObject {
	tabs_modalView *me;
	ForgeTask *task;
	NSTimer *timer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSProgressIndicator *progressBar;

- (id)initWithTask:(ForgeTask*) newTask;
- (IBAction) closeClicked:(id) sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void) updateProgress;

@end
