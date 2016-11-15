//
//  KeyboardKey.h
//  TouchBarServer
//
//  Created by Andreas Verhoeven on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, KeyboardKeyModifier){
    KeyboardKeyModifierNone         = 0,
    KeyboardKeyModifierAlphaLock    = 1 << 0,
    KeyboardKeyModifierShift        = 1 << 1,
    KeyboardKeyModifierControl      = 1 << 2,
    KeyboardKeyModifierOption       = 1 << 3,
    KeyboardKeyModifierCommand      = 1 << 4,
    KeyboardKeyModifierFn           = 1 << 5,
    KeyboardKeyModifierLast         = 1 << 6, // Always keep this last
};

typedef NS_OPTIONS(NSUInteger, KeyboardKeyType) {
    KeyboardKeyTypeRegular		= 1 << 0,
    KeyboardKeyTypeModifier		= 1 << 1,
    KeyboardKeyTypeControl		= 1 << 2,
    KeyboardKeyTypeDeadKey		= 1 << 3,
};

@interface KeyboardKeyCap : NSObject <NSSecureCoding>
@property (nonatomic, copy) NSString* text;
@property (nonatomic) KeyboardKeyType type;
@end

@interface KeyboardKey : NSObject <NSSecureCoding>
@property (nonatomic, assign) CGKeyCode keyCode;
@property (nonatomic, assign) CGKeyCode macKeyCode;
@property (nonatomic, copy) NSDictionary<NSNumber*, KeyboardKeyCap*>* caps; // Modifier -> caps

@end
