//
//  TouchBarWindow.m
//  TouchBar
//
//  Created by Robbert Klarenbeek on 12/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "TouchBarWindow.h"

#import "TouchBarView.h"

@interface NSWindow (Private)
- (void )_setPreventsActivation:(bool)preventsActivation;
@end

@implementation TouchBarWindow

- (instancetype)init {
    self = [super init];
    if(self != nil) {
        self.styleMask = NSTitledWindowMask | NSFullSizeContentViewWindowMask;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        [self standardWindowButton:NSWindowCloseButton].hidden = YES;
        [self standardWindowButton:NSWindowFullScreenButton].hidden = YES;
        [self standardWindowButton:NSWindowZoomButton].hidden = YES;
        [self standardWindowButton:NSWindowMiniaturizeButton].hidden = YES;
        
        self.movable = NO;
        self.acceptsMouseMovedEvents = YES;
        self.movableByWindowBackground = NO;
        self.level = CGWindowLevelForKey(kCGAssistiveTechHighWindowLevelKey);
        self.collectionBehavior = (NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorFullScreenDisallowsTiling);
        self.backgroundColor = [NSColor blackColor];
        [self _setPreventsActivation:YES];
        [self setFrame:NSMakeRect(0, 0, 1085 + 10, 30 + 10) display:YES];
        
        self.contentView = [TouchBarView new];
    }
    
    return self;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

@end
