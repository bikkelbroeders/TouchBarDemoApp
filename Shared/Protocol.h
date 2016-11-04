//
//  Protocol.h
//  TouchBar
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#ifndef Protocol_h
#define Protocol_h

#import "Peertalk.h"

static const int kProtocolPort = 1337;

typedef NS_ENUM(NSInteger, ProtocolFrameType) {
    ProtocolFrameTypeImage = 100,
    ProtocolFrameTypeMouseEvent = 101,
};

typedef NS_ENUM(NSInteger, MouseEventType) {
    MouseEventTypeDown = 1,
    MouseEventTypeUp = 2,
    MouseEventTypeDragged = 6,
};

typedef struct {
    uint64_t type;
    double x;
    double y;
} MouseEvent;

#endif /* Protocol_h */
