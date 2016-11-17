//
//  ModifierKeyController.m
//  TouchBar
//
//  Created by Robbert Klarenbeek on 16/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "ModifierKeyController.h"

@import AppKit;
@import Carbon;

CG_EXTERN void CGSGetKeys(KeyMap keymap);

@implementation ModifierKeyController {
    BOOL _couldBeSoleModifierKeyPress;
    NSEventModifierFlags _modifierFlags;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = NO;
        _modifierKey = ModifierKeyFn;
        
        _couldBeSoleModifierKeyPress = NO;
        _modifierFlags = 0;
    }
    return self;
}

- (instancetype)initWithModifierKey:(ModifierKey)modifierKey {
    self = [self init];
    if (self) {
        _modifierKey = modifierKey;
    }
    return self;
}

- (void)setModifierKey:(ModifierKey)modifierKey {
    if (_modifierKey != modifierKey) {
        _modifierKey = modifierKey;
        _couldBeSoleModifierKeyPress = NO;
    }
}

- (CGKeyCode)modifierKeyCode {
    switch (_modifierKey) {
        case ModifierKeyFn:
            return kVK_Function;
        case ModifierKeyShift:
            return kVK_Shift;
        case ModifierKeyCommand:
            return kVK_Command;
        case ModifierKeyControl:
            return kVK_Control;
        case ModifierKeyOption:
            return kVK_Option;
    }
}

- (NSEventModifierFlags)modifierEventFlag {
    switch (_modifierKey) {
        case ModifierKeyFn:
            return NSEventModifierFlagFunction;
        case ModifierKeyShift:
            return NSEventModifierFlagShift;
        case ModifierKeyCommand:
            return NSEventModifierFlagCommand;
        case ModifierKeyControl:
            return NSEventModifierFlagControl;
        case ModifierKeyOption:
            return NSEventModifierFlagOption;
    }
}

- (void)processEvent:(NSEvent *)event {
    if (_enabled) {
        switch(event.type) {
            case NSEventTypeLeftMouseDown:
            case NSEventTypeLeftMouseUp:
            case NSEventTypeRightMouseDown:
            case NSEventTypeRightMouseUp:
            case NSEventTypeOtherMouseDown:
            case NSEventTypeOtherMouseUp:
            case NSEventTypeKeyDown:
            case NSEventTypeKeyUp:
                _couldBeSoleModifierKeyPress = NO;
                break;
                
            case NSEventTypeFlagsChanged: {
                BOOL toggleKeyWasDown = (_modifierFlags & [self modifierEventFlag]) != 0;
                BOOL toggleKeyIsDown = (event.modifierFlags & [self modifierEventFlag]) != 0;
                
                if(toggleKeyIsDown != toggleKeyWasDown) {
                    KeyMap keymap;
                    CGSGetKeys(keymap);
                    if (toggleKeyIsDown) {
                        _couldBeSoleModifierKeyPress = [self isOnlyKeyPressed:[self modifierKeyCode] inKeyMap:&keymap];
                    } else if (_couldBeSoleModifierKeyPress && [self isAnyKeyPressedInKeyMap:&keymap] == NO) {
                        if ([_delegate respondsToSelector:@selector(didPressModifierKey)]) {
                            [_delegate didPressModifierKey];
                        }
                    }
                } else {
                    _couldBeSoleModifierKeyPress = NO;
                }
            }
                
            default:
                break;
        }
    }
    
    if (event.type == NSFlagsChanged) {
        _modifierFlags = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);
    }
}

- (BOOL)isOnlyKeyPressed:(CGKeyCode)key inKeyMap:(KeyMap *)keymap {
    unsigned char element = key / 32;
    UInt32 mask = 1 << (key % 32);
    for (unsigned char i = 0; i < 4; i++) {
        if (i == element) {
            if ((*keymap)[i].bigEndianValue != mask) return NO;
        } else {
            if ((*keymap)[i].bigEndianValue != 0) return NO;
        }
    }
    
    return YES;
}

- (BOOL)isAnyKeyPressedInKeyMap:(KeyMap *)keymap {
    return !(
             (*keymap)[0].bigEndianValue == 0 &&
             (*keymap)[1].bigEndianValue == 0 &&
             (*keymap)[2].bigEndianValue == 0 &&
             (*keymap)[3].bigEndianValue == 0
             );
}

@end
