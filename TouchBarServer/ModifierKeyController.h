//
//  ModifierKeyController.h
//  TouchBar
//
//  Created by Robbert Klarenbeek on 16/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AppKit;

typedef NS_ENUM(NSInteger, ModifierKey) {
    ModifierKeyFn         = 0,
    ModifierKeyShift      = 1,
    ModifierKeyCommand    = 2,
    ModifierKeyControl    = 3,
    ModifierKeyOption     = 4,
};

@protocol ModifierKeyControllerDelegate <NSObject>
- (void)didPressModifierKey;
@end

@interface ModifierKeyController : NSObject
@property (nonatomic, weak) id <ModifierKeyControllerDelegate> delegate;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) ModifierKey modifierKey;
- (instancetype)init;
- (instancetype)initWithModifierKey:(ModifierKey)modifierKey;
- (void)processEvent:(NSEvent *)event;
@end
