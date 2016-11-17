//
//  Application.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "GlobalEventApplication.h"

#import "AppDelegate.h"

typedef int CGSConnectionID;
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN void CGSGetBackgroundEventMask(CGSConnectionID cid, CGEventFlags *outMask);
CG_EXTERN CGError CGSSetBackgroundEventMask(CGSConnectionID cid, CGEventFlags mask);

@implementation GlobalEventApplication {
    CGEventFlags _defaultBackgroundEventMask;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        CGSConnectionID connectionId = CGSMainConnectionID();
        CGSGetBackgroundEventMask(connectionId, &_defaultBackgroundEventMask);
    }
    return self;
}

- (void)setGlobalEventMask:(NSEventMask)globalEventMask {
    if (_globalEventMask != globalEventMask) {
        _globalEventMask = globalEventMask;
        CGSConnectionID connectionId = CGSMainConnectionID();
        CGSSetBackgroundEventMask(connectionId, _defaultBackgroundEventMask | _globalEventMask);
    }
}

- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag {
    NSEvent *event = [super nextEventMatchingMask:mask untilDate:expiration inMode:mode dequeue:deqFlag];
    if ((1 << event.type) & _globalEventMask) {
        if ([self.delegate respondsToSelector:@selector(globalEvent:)]) {
            [self.delegate performSelector:@selector(globalEvent:) withObject:event];
        }
    }
    return event;
}

- (void)sendEvent:(NSEvent *)event {
    if (!event.window && ((1 << event.type) & _globalEventMask)) {
        return;
    }
    
    [super sendEvent:event];
}

@end
