//
//  KeyboardLayout.h
//  Test
//
//  Created by Robbert Klarenbeek on 18/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Keyboard.h"

@import CoreGraphics;

#if TARGET_OS_IPHONE
@import UIKit;
#endif

typedef NS_ENUM(NSInteger, KeyboardLayoutType) {
    KeyboardLayoutTypeUnknown   = -1,
    KeyboardLayoutTypeANSI      = 0,
    KeyboardLayoutTypeISO       = 1,
    KeyboardLayoutTypeJIS       = 2,
};

@interface KeyboardLayout : NSObject
@property (nonatomic, readonly) KeyboardLayoutType type;
@property (nonatomic, readonly) UInt8 macKbdType;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) NSUInteger numberOfKeys;
- (KeyCode)keyCodeForKeyIndex:(NSUInteger)keyIndex;
- (KeyEventModifierFlags)modifierFlagForKeyIndex:(NSUInteger)keyIndex;
#if TARGET_OS_IPHONE
- (UIBezierPath *)bezierPathForKeyIndex:(NSUInteger)keyIndex;
#endif
- (CGPoint)textPositionForKeyIndex:(NSUInteger)keyIndex;
- (CGFloat)fontSizeForKeyIndex:(NSUInteger)keyIndex;
+ (NSString *)fixedKeyCaptionForKeyCode:(KeyCode)keyCode withFnDown:(BOOL)fnDown;
@end
