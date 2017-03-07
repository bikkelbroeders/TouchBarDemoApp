//
//  TouchBarView.m
//  TouchBar
//
//  Created by Robbert Klarenbeek on 12/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "TouchBarView.h"

extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler);
extern BOOL DFRSetStatus(int);
extern BOOL DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p);

@implementation TouchBarView {
    CGDisplayStreamRef _stream;
    NSView *_displayView;
}

- (instancetype) init {
    self = [super init];
    if(self != nil) {
        _displayView = [NSView new];
        _displayView.frame = NSMakeRect(5, 5, 1085, 30);
        _displayView.wantsLayer = YES;
        [self addSubview:_displayView];
        
        _stream = SLSDFRDisplayStreamCreate(NULL, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status,
                                                                               uint64_t displayTime,
                                                                               IOSurfaceRef frameSurface,
                                                                               CGDisplayStreamUpdateRef updateRef) {
            if (status != kCGDisplayStreamFrameStatusFrameComplete) return;
            _displayView.layer.contents = (__bridge id)(frameSurface);
        });
        
        DFRSetStatus(2);
        CGDisplayStreamStart(_stream);
    }
    
    return self;
}

- (void)commonMouseEvent:(NSEvent *)event {
    NSPoint location = [_displayView convertPoint:[event locationInWindow] fromView:nil];
    DFRFoundationPostEventWithMouseActivity(event.type, location);
}

- (void)mouseDown:(NSEvent *)event {
    [self commonMouseEvent:event];
}

- (void)mouseUp:(NSEvent *)event {
    [self commonMouseEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self commonMouseEvent:event];
}

@end
