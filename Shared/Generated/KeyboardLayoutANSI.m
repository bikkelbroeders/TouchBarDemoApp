//
//  KeyboardLayoutANSI.m
//  TouchBar
//
//  Generated by generate_keyboard_layouts.sh.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "KeyboardLayoutANSI.h"

@implementation KeyboardLayoutANSI

/*************************************************************
 *                                                           *
 *   WARNING: this is an auto-generated file. DO NOT EDIT!   *
 *                                                           *
 *************************************************************/

- (KeyboardLayoutType)type {
    return KeyboardLayoutTypeANSI;
}

- (UInt8)macKbdType {
    return 58;
}

- (CGSize)size {
    return CGSizeMake(290, 113);
}

- (NSUInteger)numberOfKeys {
    return 65;
}

- (KeyCode)keyCodeForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
        case  0: return 0x32; // kVK_ANSI_Grave
        case  1: return 0x12; // kVK_ANSI_1
        case  2: return 0x13; // kVK_ANSI_2
        case  3: return 0x14; // kVK_ANSI_3
        case  4: return 0x15; // kVK_ANSI_4
        case  5: return 0x17; // kVK_ANSI_5
        case  6: return 0x16; // kVK_ANSI_6
        case  7: return 0x1A; // kVK_ANSI_7
        case  8: return 0x1C; // kVK_ANSI_8
        case  9: return 0x19; // kVK_ANSI_9
        case 10: return 0x1D; // kVK_ANSI_0
        case 11: return 0x1B; // kVK_ANSI_Minus
        case 12: return 0x18; // kVK_ANSI_Equal
        case 13: return 0x2A; // kVK_ANSI_Backslash
        case 14: return 0x1E; // kVK_ANSI_RightBracket
        case 15: return 0x21; // kVK_ANSI_LeftBracket
        case 16: return 0x23; // kVK_ANSI_P
        case 17: return 0x1F; // kVK_ANSI_O
        case 18: return 0x22; // kVK_ANSI_I
        case 19: return 0x20; // kVK_ANSI_U
        case 20: return 0x10; // kVK_ANSI_Y
        case 21: return 0x11; // kVK_ANSI_T
        case 22: return 0x0F; // kVK_ANSI_R
        case 23: return 0x0E; // kVK_ANSI_E
        case 24: return 0x0D; // kVK_ANSI_W
        case 25: return 0x0C; // kVK_ANSI_Q
        case 26: return 0x00; // kVK_ANSI_A
        case 27: return 0x01; // kVK_ANSI_S
        case 28: return 0x02; // kVK_ANSI_D
        case 29: return 0x03; // kVK_ANSI_F
        case 30: return 0x05; // kVK_ANSI_G
        case 31: return 0x04; // kVK_ANSI_H
        case 32: return 0x26; // kVK_ANSI_J
        case 33: return 0x28; // kVK_ANSI_K
        case 34: return 0x25; // kVK_ANSI_L
        case 35: return 0x29; // kVK_ANSI_Semicolon
        case 36: return 0x27; // kVK_ANSI_Quote
        case 37: return 0x2C; // kVK_ANSI_Slash
        case 38: return 0x2F; // kVK_ANSI_Period
        case 39: return 0x2B; // kVK_ANSI_Comma
        case 40: return 0x2E; // kVK_ANSI_M
        case 41: return 0x2D; // kVK_ANSI_N
        case 42: return 0x0B; // kVK_ANSI_B
        case 43: return 0x09; // kVK_ANSI_V
        case 44: return 0x08; // kVK_ANSI_C
        case 45: return 0x07; // kVK_ANSI_X
        case 46: return 0x06; // kVK_ANSI_Z
        case 47: return 0x3F; // kVK_Function
        case 48: return 0x3B; // kVK_Control
        case 49: return 0x3A; // kVK_Option
        case 50: return 0x3A; // kVK_Option
        case 51: return 0x37; // kVK_Command
        case 52: return 0x37; // kVK_Command
        case 53: return 0x7B; // kVK_LeftArrow
        case 54: return 0x7D; // kVK_DownArrow
        case 55: return 0x7C; // kVK_RightArrow
        case 56: return 0x7E; // kVK_UpArrow
        case 57: return 0x30; // kVK_Tab
        case 58: return 0x33; // kVK_Delete
        case 59: return 0x39; // kVK_CapsLock
        case 60: return 0x24; // kVK_Return
        case 61: return 0x38; // kVK_Shift
        case 62: return 0x38; // kVK_Shift
        case 63: return 0x31; // kVK_Space
        default: return [super keyCodeForKeyIndex:keyIndex];
    }
}

- (KeyEventModifierFlags)modifierFlagForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
        case 47: return KeyEventModifierFlagFunction;
        case 48: return KeyEventModifierFlagControl;
        case 49: return KeyEventModifierFlagOption;
        case 50: return KeyEventModifierFlagOption;
        case 51: return KeyEventModifierFlagCommand;
        case 52: return KeyEventModifierFlagCommand;
        case 59: return KeyEventModifierFlagCapsLock;
        case 61: return KeyEventModifierFlagShift;
        case 62: return KeyEventModifierFlagShift;
        default: return [super modifierFlagForKeyIndex:keyIndex];
    }
}

#if TARGET_OS_IPHONE
- (UIBezierPath *)bezierPathForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
        case  0: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 13.5, 19, 19) cornerRadius:2];
        case  1: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(20.5, 13.5, 19, 19) cornerRadius:2];
        case  2: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(40.5, 13.5, 19, 19) cornerRadius:2];
        case  3: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(60.5, 13.5, 19, 19) cornerRadius:2];
        case  4: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(80.5, 13.5, 19, 19) cornerRadius:2];
        case  5: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(100.5, 13.5, 19, 19) cornerRadius:2];
        case  6: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(120.5, 13.5, 19, 19) cornerRadius:2];
        case  7: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(140.5, 13.5, 19, 19) cornerRadius:2];
        case  8: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(160.5, 13.5, 19, 19) cornerRadius:2];
        case  9: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(180.5, 13.5, 19, 19) cornerRadius:2];
        case 10: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(200.5, 13.5, 19, 19) cornerRadius:2];
        case 11: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(220.5, 13.5, 19, 19) cornerRadius:2];
        case 12: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(240.5, 13.5, 19, 19) cornerRadius:2];
        case 13: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(270.5, 33.5, 19, 19) cornerRadius:2];
        case 14: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(250.5, 33.5, 19, 19) cornerRadius:2];
        case 15: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(230.5, 33.5, 19, 19) cornerRadius:2];
        case 16: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(210.5, 33.5, 19, 19) cornerRadius:2];
        case 17: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(190.5, 33.5, 19, 19) cornerRadius:2];
        case 18: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(170.5, 33.5, 19, 19) cornerRadius:2];
        case 19: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(150.5, 33.5, 19, 19) cornerRadius:2];
        case 20: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(130.5, 33.5, 19, 19) cornerRadius:2];
        case 21: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(110.5, 33.5, 19, 19) cornerRadius:2];
        case 22: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(90.5, 33.5, 19, 19) cornerRadius:2];
        case 23: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(70.5, 33.5, 19, 19) cornerRadius:2];
        case 24: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(50.5, 33.5, 19, 19) cornerRadius:2];
        case 25: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(30.5, 33.5, 19, 19) cornerRadius:2];
        case 26: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(35.5, 53.5, 19, 19) cornerRadius:2];
        case 27: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(55.5, 53.5, 19, 19) cornerRadius:2];
        case 28: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(75.5, 53.5, 19, 19) cornerRadius:2];
        case 29: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(95.5, 53.5, 19, 19) cornerRadius:2];
        case 30: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(115.5, 53.5, 19, 19) cornerRadius:2];
        case 31: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(135.5, 53.5, 19, 19) cornerRadius:2];
        case 32: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(155.5, 53.5, 19, 19) cornerRadius:2];
        case 33: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(175.5, 53.5, 19, 19) cornerRadius:2];
        case 34: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(195.5, 53.5, 19, 19) cornerRadius:2];
        case 35: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(215.5, 53.5, 19, 19) cornerRadius:2];
        case 36: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(235.5, 53.5, 19, 19) cornerRadius:2];
        case 37: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(225.5, 73.5, 19, 19) cornerRadius:2];
        case 38: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(205.5, 73.5, 19, 19) cornerRadius:2];
        case 39: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(185.5, 73.5, 19, 19) cornerRadius:2];
        case 40: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(165.5, 73.5, 19, 19) cornerRadius:2];
        case 41: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(145.5, 73.5, 19, 19) cornerRadius:2];
        case 42: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(125.5, 73.5, 19, 19) cornerRadius:2];
        case 43: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(105.5, 73.5, 19, 19) cornerRadius:2];
        case 44: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(85.5, 73.5, 19, 19) cornerRadius:2];
        case 45: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(65.5, 73.5, 19, 19) cornerRadius:2];
        case 46: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(45.5, 73.5, 19, 19) cornerRadius:2];
        case 47: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 93.5, 19, 19) cornerRadius:2];
        case 48: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(20.5, 93.5, 19, 19) cornerRadius:2];
        case 49: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(40.5, 93.5, 19, 19) cornerRadius:2];
        case 50: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(210.5, 93.5, 19, 19) cornerRadius:2];
        case 51: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(60.5, 93.5, 24, 19) cornerRadius:2];
        case 52: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(185.5, 93.5, 24, 19) cornerRadius:2];
        case 53: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(230.5, 93.5, 19, 19) cornerRadius:2];
        case 54: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(250.5, 103, 19, 9.5) cornerRadius:2];
        case 55: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(270.5, 93.5, 19, 19) cornerRadius:2];
        case 56: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(250.5, 93.5, 19, 9.5) cornerRadius:2];
        case 57: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 33.5, 29, 19) cornerRadius:2];
        case 58: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(260.5, 13.5, 29, 19) cornerRadius:2];
        case 59: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 53.5, 34, 19) cornerRadius:2];
        case 60: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(255.5, 53.5, 34, 19) cornerRadius:2];
        case 61: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 73.5, 44, 19) cornerRadius:2];
        case 62: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(245.5, 73.5, 44, 19) cornerRadius:2];
        case 63: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(85.5, 93.5, 99, 19) cornerRadius:2];
        case 64: return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 0.5, 289, 12) cornerRadius:2];
        default: return [super bezierPathForKeyIndex:keyIndex];
    }
}
#endif

- (CGPoint)textPositionForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
        case  0: return CGPointMake(10, 22.5);
        case  1: return CGPointMake(30, 21.5);
        case  2: return CGPointMake(50, 21.5);
        case  3: return CGPointMake(70, 21.5);
        case  4: return CGPointMake(90, 21.5);
        case  5: return CGPointMake(110, 21.5);
        case  6: return CGPointMake(130, 21.5);
        case  7: return CGPointMake(150, 21.5);
        case  8: return CGPointMake(170, 21.5);
        case  9: return CGPointMake(190, 21.5);
        case 10: return CGPointMake(210, 21.5);
        case 11: return CGPointMake(230, 21.5);
        case 12: return CGPointMake(250, 21.5);
        case 13: return CGPointMake(280, 41.5);
        case 14: return CGPointMake(260, 41.5);
        case 15: return CGPointMake(240, 41.5);
        case 16: return CGPointMake(220, 41.5);
        case 17: return CGPointMake(200, 41.5);
        case 18: return CGPointMake(180, 41.5);
        case 19: return CGPointMake(160, 41.5);
        case 20: return CGPointMake(140, 41.5);
        case 21: return CGPointMake(120, 41.5);
        case 22: return CGPointMake(100, 41.5);
        case 23: return CGPointMake(80, 41.5);
        case 24: return CGPointMake(60, 41.5);
        case 25: return CGPointMake(40, 41.5);
        case 26: return CGPointMake(45, 61.5);
        case 27: return CGPointMake(65, 61.5);
        case 28: return CGPointMake(85, 61.5);
        case 29: return CGPointMake(105, 61.5);
        case 30: return CGPointMake(125, 61.5);
        case 31: return CGPointMake(145, 61.5);
        case 32: return CGPointMake(165, 61.5);
        case 33: return CGPointMake(185, 61.5);
        case 34: return CGPointMake(205, 61.5);
        case 35: return CGPointMake(225, 61.5);
        case 36: return CGPointMake(245, 61.5);
        case 37: return CGPointMake(235, 81.5);
        case 38: return CGPointMake(215, 81.5);
        case 39: return CGPointMake(195, 81.5);
        case 40: return CGPointMake(175, 81.5);
        case 41: return CGPointMake(155, 81.5);
        case 42: return CGPointMake(135, 81.5);
        case 43: return CGPointMake(115, 81.5);
        case 44: return CGPointMake(95, 81.5);
        case 45: return CGPointMake(75, 81.5);
        case 46: return CGPointMake(55, 81.5);
        case 47: return CGPointMake(10, 102.5);
        case 48: return CGPointMake(30, 102.5);
        case 49: return CGPointMake(50, 102.5);
        case 50: return CGPointMake(220, 102.5);
        case 51: return CGPointMake(72, 102.5);
        case 52: return CGPointMake(198, 102.5);
        case 53: return CGPointMake(240, 102.5);
        case 54: return CGPointMake(260, 107.75);
        case 55: return CGPointMake(280, 102.5);
        case 56: return CGPointMake(260, 97.25);
        case 57: return CGPointMake(15, 42.5);
        case 58: return CGPointMake(275, 22.5);
        case 59: return CGPointMake(18, 62.5);
        case 60: return CGPointMake(272, 62.5);
        case 61: return CGPointMake(22, 82.5);
        case 62: return CGPointMake(268, 82.5);
        case 63: return CGPointMake(135, 102.5);
        default: return [super textPositionForKeyIndex:keyIndex];
    }
}

- (CGFloat)fontSizeForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
        case  0: return 9;
        case  1: return 8;
        case  2: return 8;
        case  3: return 8;
        case  4: return 8;
        case  5: return 8;
        case  6: return 8;
        case  7: return 8;
        case  8: return 8;
        case  9: return 8;
        case 10: return 8;
        case 11: return 8;
        case 12: return 8;
        case 13: return 8;
        case 14: return 8;
        case 15: return 8;
        case 16: return 9;
        case 17: return 9;
        case 18: return 9;
        case 19: return 9;
        case 20: return 9;
        case 21: return 9;
        case 22: return 9;
        case 23: return 9;
        case 24: return 9;
        case 25: return 9;
        case 26: return 9;
        case 27: return 9;
        case 28: return 9;
        case 29: return 9;
        case 30: return 9;
        case 31: return 9;
        case 32: return 9;
        case 33: return 9;
        case 34: return 9;
        case 35: return 8;
        case 36: return 8;
        case 37: return 8;
        case 38: return 8;
        case 39: return 9;
        case 40: return 9;
        case 41: return 9;
        case 42: return 9;
        case 43: return 9;
        case 44: return 9;
        case 45: return 9;
        case 46: return 9;
        case 47: return 8;
        case 48: return 8;
        case 49: return 8;
        case 50: return 8;
        case 51: return 8;
        case 52: return 8;
        case 53: return 5;
        case 54: return 5;
        case 55: return 5;
        case 56: return 5;
        case 57: return 8;
        case 58: return 8;
        case 59: return 8;
        case 60: return 8;
        case 61: return 8;
        case 62: return 8;
        case 63: return 8;
        default: return [super fontSizeForKeyIndex:keyIndex];
    }
}

@end
