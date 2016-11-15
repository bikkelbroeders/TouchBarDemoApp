//
//  Keyboard.h
//  TouchBar
//
//  Created by Robbert Klarenbeek on 10/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#ifndef Keyboard_h
#define Keyboard_h

typedef NS_ENUM(uint64_t, KeyEventType) {
    KeyEventTypeKeyDown      = 10,
    KeyEventTypeKeyUp        = 11,
    KeyEventTypeFlagsChanged = 12,
};

typedef uint16_t KeyCode;

typedef NS_OPTIONS(uint16_t, KeyEventModifierFlags) {
    KeyEventModifierFlagCapsLock    = 1 << 0,
    KeyEventModifierFlagShift       = 1 << 1,
    KeyEventModifierFlagControl     = 1 << 2,
    KeyEventModifierFlagOption      = 1 << 3,
    KeyEventModifierFlagCommand     = 1 << 4,
    KeyEventModifierFlagFunction    = 1 << 5,
};

typedef struct {
    KeyEventType type;
    uint16_t key;
    KeyEventModifierFlags modifiers;
} KeyEvent;

#endif /* Keyboard_h */
