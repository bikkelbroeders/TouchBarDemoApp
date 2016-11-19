//
//  Application.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "GlobalEventApplication.h"

#import "AppDelegate.h"

@import Carbon;

typedef int CGSConnectionID;
CG_EXTERN void CGSGetKeys(KeyMap keymap);
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN void CGSGetBackgroundEventMask(CGSConnectionID cid, int *outMask);
CG_EXTERN CGError CGSSetBackgroundEventMask(CGSConnectionID cid, int mask);

@implementation GlobalEventApplication {
    int _defaultBackgroundEventMask;
    NSTimer *_ensureBackgroundEventMaskTimer;
    
    NSEventModifierFlags _modifierFlags;
    NSMutableSet *_keysDown;
    NSTimer *_detectMissingKeyUpTimer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        CGSConnectionID connectionId = CGSMainConnectionID();
        CGSGetBackgroundEventMask(connectionId, &_defaultBackgroundEventMask);
        
        _keysDown = [NSMutableSet new];
    }
    return self;
}

- (void)updateBackgroundEventMask {
    CGSConnectionID connectionId = CGSMainConnectionID();
    int mask;
    CGSGetBackgroundEventMask(connectionId, &mask);
    if (mask != (_defaultBackgroundEventMask | _globalEventMask)) {
        CGSSetBackgroundEventMask(connectionId, _defaultBackgroundEventMask | _globalEventMask);
    }
}

- (void)setGlobalEventMask:(int)globalEventMask {
    if (_globalEventMask != globalEventMask) {
        _globalEventMask = globalEventMask;
        [self updateBackgroundEventMask];

        if (_ensureBackgroundEventMaskTimer) {
            [_ensureBackgroundEventMaskTimer invalidate];
            _ensureBackgroundEventMaskTimer = nil;
        }
        _ensureBackgroundEventMaskTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateBackgroundEventMask) userInfo:nil repeats:YES];
    }
}

- (BOOL)isKeyPressed:(CGKeyCode)key inKeyMap:(KeyMap *)keymap {
    unsigned char element = key / 32;
    UInt32 mask = 1 << (key % 32);
    return ((*keymap)[element].bigEndianValue & mask) != 0;
}

- (void)detectKeyUpsWithoutEvents:(NSEvent *)event {
    switch (event.type) {
        case NSEventTypeKeyDown: {
            BOOL firstKeyDown = (_keysDown.count == 0);
            [_keysDown addObject:@(event.keyCode)];
            if (firstKeyDown && !_detectMissingKeyUpTimer && [NSTimer respondsToSelector:@selector(scheduledTimerWithTimeInterval:repeats:block:)]) {
                _detectMissingKeyUpTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer){
                    KeyMap keymap;
                    CGSGetKeys(keymap);
                    for (NSNumber *keyDown in [_keysDown copy]) {
                        CGKeyCode key = [keyDown integerValue];
                        if (![self isKeyPressed:key inKeyMap:&keymap]) {
                            NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:_modifierFlags timestamp:0 windowNumber:0 context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:key];
                            [self globalEvent:event];
                        }
                    }
                }];
            }
            break;
        }
        case NSEventTypeKeyUp: {
            [_keysDown removeObject:@(event.keyCode)];
            if (_keysDown.count == 0 && _detectMissingKeyUpTimer) {
                [_detectMissingKeyUpTimer invalidate];
                _detectMissingKeyUpTimer = nil;
            }
            break;
        }
        case NSEventTypeFlagsChanged:
            _modifierFlags = event.modifierFlags;
            break;
        default:
            break;
    }
}

- (void)globalEvent:(NSEvent *)event {
    [self detectKeyUpsWithoutEvents:event];
    if ([self.delegate respondsToSelector:@selector(globalEvent:)]) {
        [self.delegate performSelector:@selector(globalEvent:) withObject:event];
    }
}

- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag {
    NSEvent *event = [super nextEventMatchingMask:mask untilDate:expiration inMode:mode dequeue:deqFlag];
    if ((1 << event.type) & _globalEventMask) {
        [self globalEvent:event];
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
