//
//  KeyboardView.h
//  TouchBarClient
//
//  Created by Robbert Klarenbeek on 18/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KeyboardLayout.h"
#import "Keyboard.h"

@class KeyboardView;
@protocol KeyboardViewDelegate <NSObject>
@optional
- (void)keyboardView:(KeyboardView *)keyboardView keyEvent:(KeyEvent)keyEvent;
@end

IB_DESIGNABLE
@interface KeyboardView : UIView
@property (nonatomic, weak) id<KeyboardViewDelegate> delegate;
@property (nonatomic, readonly) CGFloat aspectRatio;
@property (nonatomic, strong) KeyboardLayout *layout;
@property (nonatomic, strong) NSDictionary *keyCaptions;
#if TARGET_INTERFACE_BUILDER
@property (nonatomic, assign) IBInspectable NSInteger layoutType;
#else
@property (nonatomic, assign) KeyboardLayoutType layoutType;
#endif
@property (nonatomic, assign) IBInspectable BOOL preserveAspectRatio;
@property (nonatomic, assign) IBInspectable CGFloat borderWidth;
@property (nonatomic, strong) IBInspectable UIColor *normalKeyColor;
@property (nonatomic, strong) IBInspectable UIColor *normalCaptionColor;
@property (nonatomic, strong) IBInspectable UIColor *normalBorderColor;
@property (nonatomic, strong) IBInspectable UIColor *activeKeyColor;
@property (nonatomic, strong) IBInspectable UIColor *activeCaptionColor;
@property (nonatomic, strong) IBInspectable UIColor *activeBorderColor;
- (void)externalKeyEvent:(KeyEvent)keyCode;
@end
