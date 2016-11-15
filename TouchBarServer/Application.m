//
//  Application.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "Application.h"

#import "AppDelegate.h"

@implementation Application

- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag {
    NSEvent *event = [super nextEventMatchingMask:mask untilDate:expiration inMode:mode dequeue:deqFlag];
    if (event.type == NSKeyDown || event.type == NSKeyUp || event.type == NSFlagsChanged) {
        AppDelegate *appDelegate = self.delegate;
        [appDelegate keyEvent:event];
    }
    return event;
}

- (void)sendEvent:(NSEvent *)event {
    if (!self.keyWindow && (event.type == NSKeyDown || event.type == NSKeyUp || event.type == NSFlagsChanged)) {
        return;
    }
    
    [super sendEvent:event];
}

@end
