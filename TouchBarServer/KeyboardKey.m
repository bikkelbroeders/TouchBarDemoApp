//
//  KeyboardKey.m
//  TouchBarServer
//
//  Created by Andreas Verhoeven on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "KeyboardKey.h"

#pragma mark -

@implementation KeyboardKeyCap

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self != nil) {
        _text = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"text"];
        _type = [aDecoder decodeIntegerForKey:@"type"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_text forKey:@"text"];
    [aCoder encodeInteger:_type forKey:@"type"];
}

@end

@implementation KeyboardKey

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self != nil) {
        _keyCode = [aDecoder decodeIntegerForKey:@"keyCode"];
        _macKeyCode = [aDecoder decodeIntegerForKey:@"macKeyCode"];
        _caps = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"caps"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_keyCode forKey:@"keyCode"];
    [aCoder encodeInteger:_macKeyCode forKey:@"macKeyCode"];
    [aCoder encodeObject:_caps forKey:@"caps"];
}

@end
