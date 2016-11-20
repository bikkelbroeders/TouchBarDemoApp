//
//  KeyboardLayout.m
//  Test
//
//  Created by Robbert Klarenbeek on 18/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "KeyboardLayout.h"

@implementation KeyboardLayout

- (KeyboardLayoutType)type {
    return KeyboardLayoutTypeUnknown;
}

- (CGSize)size {
    return CGSizeZero;
}

- (NSUInteger)numberOfKeys {
    return 0;
}

- (KeyCode)keyCodeForKeyIndex:(NSUInteger)keyIndex {
    return 0xFF;
}

- (KeyEventModifierFlags)modifierFlagForKeyIndex:(NSUInteger)keyIndex {
    return 0;
}

#if TARGET_OS_IPHONE
- (UIBezierPath *)bezierPathForKeyIndex:(NSUInteger)keyIndex {
    return nil;
}
#endif

- (CGPoint)textPositionForKeyIndex:(NSUInteger)keyIndex {
    return CGPointZero;
}

- (CGFloat)fontSizeForKeyIndex:(NSUInteger)keyIndex {
    return 0.0;
}

+ (NSString *)fixedKeyCaptionForKeyCode:(KeyCode)keyCode withFnDown:(BOOL)fnDown {
    switch(keyCode) {
        case 0x24: return !fnDown ? @"↩\uFE0E" : @"⌤\uFE0E"; // kVK_Return
        case 0x30: return @"⇥\uFE0E"; // kVK_Tab
        case 0x33: return !fnDown ? @"⌫\uFE0E" : @"⌦\uFE0E"; // kVK_Delete
        case 0x35: return @"esc"; // kVK_Escape
        case 0x36: return @"⌘\uFE0E"; // kVK_RightCommand
        case 0x37: return @"⌘\uFE0E"; // kVK_Command
        case 0x38: return @"⇧\uFE0E"; // kVK_Shift
        case 0x39: return @"⇪\uFE0E"; // kVK_CapsLock
        case 0x3A: return @"⌥\uFE0E"; // kVK_Option
        case 0x3B: return @"⌃\uFE0E"; // kVK_Control
        case 0x3C: return @"⇧\uFE0E"; // kVK_RightShift
        case 0x3D: return @"⌥\uFE0E"; // kVK_RightOption
        case 0x3E: return @"⌃\uFE0E"; // kVK_RightControl
        case 0x3F: return @"fn"; // kVK_Function
        case 0x40: return @"F17"; // kVK_F17
        case 0x47: return @"⌧\uFE0E"; // kVK_ANSI_KeypadClear
        case 0x4C: return @"⌤\uFE0E"; // kVK_ANSI_KeypadEnter
        case 0x4F: return @"F18"; // kVK_F18
        case 0x50: return @"F19"; // kVK_F19
        case 0x5A: return @"F20"; // kVK_F20
        case 0x60: return @"F5"; // kVK_F5
        case 0x61: return @"F6"; // kVK_F6
        case 0x62: return @"F7"; // kVK_F7
        case 0x63: return @"F3"; // kVK_F3
        case 0x64: return @"F8"; // kVK_F8
        case 0x65: return @"F9"; // kVK_F9
        case 0x66: return @"英数"; // kVK_JIS_Eisu
        case 0x67: return @"F11"; // kVK_F11
        case 0x68: return @"かな"; // kVK_JIS_Kana
        case 0x69: return @"F13"; // kVK_F13
        case 0x6A: return @"F16"; // kVK_F16
        case 0x6B: return @"F14"; // kVK_F14
        case 0x6D: return @"F10"; // kVK_F10
        case 0x6F: return @"F12"; // kVK_F12
        case 0x71: return @"F15"; // kVK_F15
        case 0x72: return @"?⃝\uFE0E"; // kVK_Help
        case 0x73: return @"↖\uFE0E"; // kVK_Home
        case 0x74: return @"⇞\uFE0E"; // kVK_PageUp
        case 0x76: return @"F4"; // kVK_F4
        case 0x77: return @"↘\uFE0E"; // kVK_End
        case 0x78: return @"F2"; // kVK_F2
        case 0x79: return @"⇟\uFE0E"; // kVK_PageDown
        case 0x7A: return @"F1"; // kVK_F1
        case 0x7B: return !fnDown ? @"⇠\uFE0E" : @"↖\uFE0E"; // kVK_LeftArrow
        case 0x7C: return !fnDown ? @"⇢\uFE0E" : @"↘\uFE0E"; // kVK_RightArrow
        case 0x7D: return !fnDown ? @"⇣\uFE0E" : @"⇟\uFE0E"; // kVK_DownArrow
        case 0x7E: return !fnDown ? @"⇡\uFE0E" : @"⇞\uFE0E"; // kVK_UpArrow
        default:
            return nil;
    }
}

@end
