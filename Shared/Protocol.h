//
//  Protocol.h
//  TouchBar
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#ifndef Protocol_h
#define Protocol_h

static const int kProtocolPort = 1337;

typedef uint64_t Version;

// Up this every time you want the iOS client require updated code
// (so basically every versioned release or in case of protocol changes)
static const Version kServerVersion = 1;

static const uint32_t kProtocolFrameTypeServerMin = 1000;
static const uint32_t kProtocolFrameTypeServerMax = 1999;
static const uint32_t kProtocolFrameTypeClientMin = 2000;
static const uint32_t kProtocolFrameTypeClientMax = 2999;

typedef NS_ENUM(uint32_t, ProtocolFrameType) {
    ProtocolFrameTypeServerVersion              = 1000,
    ProtocolFrameTypeServerImage                = 1001,
    ProtocolFrameTypeServerKeyboardLayout       = 1002,
    ProtocolFrameTypeServerSystemKeyEvent       = 1003,
    ProtocolFrameTypeServerModeChange           = 1004,
    ProtocolFrameTypeServerAlignChange          = 1005,

    ProtocolFrameTypeClientTouchBarMouseEvent   = 2000,
    ProtocolFrameTypeClientKeyboardKeyEvent     = 2001,
};

typedef NS_ENUM(uint64_t, MouseEventType) {
    MouseEventTypeDown      = 1,
    MouseEventTypeUp        = 2,
    MouseEventTypeDragged   = 6,
};

#include "Keyboard.h"

typedef struct {
    MouseEventType type;
    double x;
    double y;
} MouseEvent;

typedef NS_ENUM(uint64_t, OperatingMode) {
    OperatingModeTouchBarOnly,
    OperatingModeKeyboard,
    OperatingModeDemo1,
    OperatingModeDemo2,
    OperatingModeDemo3,
    OperatingModeDemo4,
    OperatingModeDemo5,
};

typedef NS_ENUM(uint64_t, Alignment) {
    AlignmentBottom,
    AlignmentMiddle,
    AlignmentTop,
};

#endif /* Protocol_h */
