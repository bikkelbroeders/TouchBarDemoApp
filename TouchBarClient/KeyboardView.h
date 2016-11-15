//
//  Keyboard.h
//  TouchBarClient
//
//  Created by Andreas Verhoeven on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Keyboard.h"

@class KeyboardView;
@protocol KeyboardViewDelegate <NSObject>
@optional
- (void)keyboardViewDidLoad:(KeyboardView*)keyboardView;
- (void)keyboardView:(KeyboardView*)keyboardView keyEvent:(KeyEvent)keyEvent;
@end

@interface KeyboardView : UIView

@property (nonatomic, weak) IBOutlet id<KeyboardViewDelegate> delegate;

@property (nonatomic, copy) NSData* htmlData;
@property (nonatomic, readonly) CGSize aspectRatio;

- (void)externalKeyEvent:(KeyEvent)keyCode;

@end
