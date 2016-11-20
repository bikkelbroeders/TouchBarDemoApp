//
//  ViewController.m
//  TouchBarClient
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "ViewController.h"

#import "KeyboardView.h"
#import "Peertalk.h"
#import "Protocol.h"

static const NSTimeInterval kAnimationDuration = 0.3;

@interface ViewTransition : NSObject
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign, readonly) BOOL fromVisibility;
@property (nonatomic, assign) BOOL toVisibility;
@property (nonatomic, strong) UIColor *toBackgroundColor;
@property (nonatomic, assign) BOOL willBeOffScreen;
@end

@implementation ViewTransition
- (instancetype)initWithView:(UIView *)view {
    self = [self init];
    if (self) {
        _view = view;
        _fromVisibility = !view.hidden && view.alpha > 0.0;
        _toVisibility = _fromVisibility;
        _toBackgroundColor = view.backgroundColor;
        _willBeOffScreen = NO;
    }
    return self;
}
@end

@interface ViewController () <PTChannelDelegate, KeyboardViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *infoLabelView;
@property (nonatomic, weak) IBOutlet UIView *panelView;
@property (nonatomic, weak) IBOutlet UIImageView *demoImageView;
@property (nonatomic, weak) IBOutlet UIView *demoImageTopMarginView;
@property (nonatomic, weak) IBOutlet UIImageView *touchBarView;
@property (nonatomic, weak) IBOutlet KeyboardView *keyboardView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *demoImageAspectRatioConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *touchBarAspectRatioConstraint;

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, assign) OperatingMode mode;
@property (nonatomic, assign) Alignment align;

@end

@implementation ViewController {
    PTChannel *_listenChannel;
    PTChannel *_peerChannel;

    NSArray *_constraints;
    NSArray *_demoParameters;
    
    NSNumber *_serverVersion;
    BOOL _touchBarReady;
    BOOL _keyboardReady;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _keyboardView.delegate = self;
    
    _demoParameters = @[
                       @{
                           @"image": [UIImage imageNamed:@"DemoImage1"],
                           @"keyboardWidth": @0.693,
                           @"keyboardCenterY": @0.495,
                           @"backgroundColor": [UIColor colorWithWhite:0.96 alpha:1.0],
                           },
                       @{
                           @"image": [UIImage imageNamed:@"DemoImage2"],
                           @"keyboardWidth": @0.701,
                           @"keyboardCenterY": @0.348,
                           @"backgroundColor": [UIColor colorWithWhite:0.96 alpha:1.0],
                           },
                       @{
                           @"image": [UIImage imageNamed:@"DemoImage3"],
                           @"keyboardWidth": @0.863,
                           @"keyboardCenterY": @0.327,
                           @"backgroundColor": [UIColor colorWithWhite:0.96 alpha:1.0],
                           },
                       @{
                           @"image": [UIImage imageNamed:@"DemoImage4"],
                           @"keyboardWidth": @0.613,
                           @"keyboardCenterY": @0.359,
                           @"backgroundColor": [UIColor colorWithWhite:0.96 alpha:1.0],
                           },
                       @{
                           @"image": [UIImage imageNamed:@"DemoImage5"],
                           @"keyboardWidth": @0.752,
                           @"keyboardCenterY": @0.341,
                           @"backgroundColor": [UIColor colorWithWhite:0.96 alpha:1.0],
                           },
                       ];

    _panelView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    _mode = OperatingModeDemo1;
    _align = AlignmentBottom;
    [self updateBackground:NO];
    [self updateViews:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopListening) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startListening) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self startListening];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self stopListening];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [super viewDidDisappear:animated];
}

- (void)startListening {
    [self stopListening];
    
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    [channel listenOnPort:kProtocolPort IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Failed to listen on localhost:%d: %@", kProtocolPort, error);
        } else {
            _listenChannel = channel;
        }
    }];
}

- (void)stopListening {
    if (_listenChannel) {
        [_listenChannel close];
        _listenChannel = nil;
    }
    
    if (_peerChannel) {
        [_peerChannel close];
        _peerChannel = nil;
    }
    
    [self resetSession];
}

- (void)resetSession {
    _peerChannel = nil;
    _serverVersion = nil;
    _touchBarReady = NO;
    _keyboardReady = NO;
}

- (IBAction)recognizerFired:(UIGestureRecognizer*)recognizer {
    if (!_peerChannel || _panelView.hidden || _touchBarView.hidden) return;
    
    MouseEvent event;

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        event.type = MouseEventTypeDown;
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateEnded) {
        event.type = MouseEventTypeUp;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        event.type = MouseEventTypeDragged;
    } else {
        return;
    }

    // Hardcoded '2', because the touch bar is rendered @2x
    CGFloat scale = 2 * _touchBarView.frame.size.width / _touchBarView.image.size.width;
    CGPoint location = [recognizer locationInView:_touchBarView];

    event.x = location.x / scale;
    event.y = location.y / scale;

    NSData* data = [NSData dataWithBytes:&event length:sizeof(event)];
    CFDataRef immutableSelf = CFBridgingRetain([data copy]);
    dispatch_data_t payload = dispatch_data_create(data.bytes, data.length, dispatch_get_main_queue(), ^{
        CFRelease(immutableSelf);
    });
    
    [_peerChannel sendFrameOfType:ProtocolFrameTypeClientTouchBarMouseEvent tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to send message: %@", error);
        }
    }];
}

- (BOOL)active {
    return !!_peerChannel
        && (!_serverVersion || _serverVersion.unsignedLongLongValue == kServerVersion)
        && _touchBarReady
        && (_keyboardReady || _mode == OperatingModeTouchBarOnly);
}

- (void)setAlign:(Alignment)align {
    if (_align != align) {
        BOOL wasActive = self.active;
        _align = align;
        [self updateViews:wasActive || self.active];
    }
}

- (void)setMode:(OperatingMode)mode {
    if (_mode != mode) {
        BOOL wasActive = self.active;
        _mode = mode;
        [self updateBackground:YES];
        [self updateViews:wasActive || self.active];
    }
}

- (void)updateBackground:(BOOL)animated {
    UIColor *backgroundColor = [UIColor blackColor];
    
    switch (_mode) {
        case OperatingModeTouchBarOnly: {
            backgroundColor = [UIColor colorWithWhite:0.09 alpha:1.0];
            break;
        }
        case OperatingModeKeyboard: {
            backgroundColor = [UIColor colorWithWhite:0.09 alpha:1.0];
            break;
        }
        case OperatingModeDemo1:
        case OperatingModeDemo2:
        case OperatingModeDemo3:
        case OperatingModeDemo4:
        case OperatingModeDemo5: {
            NSDictionary *parameters = _demoParameters[_mode - OperatingModeDemo1];
            backgroundColor = parameters[@"backgroundColor"];
            break;
        }
    }
    
    const CGFloat *components = CGColorGetComponents(backgroundColor.CGColor);
    _infoLabelView.textColor = (components[0] < 0.5) ? [UIColor whiteColor] : [UIColor blackColor];
    
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.view.backgroundColor = backgroundColor;
        }];
    } else {
        self.view.backgroundColor = backgroundColor;
    }
}

- (void)updateViews:(BOOL)animated {
    if (_constraints) {
        [self.view removeConstraints:_constraints];
        _constraints = nil;
    }

    BOOL haveKeyboard = YES;
    UIImage *demoImage = nil;
    
    if (!_peerChannel) {
        _infoLabelView.text = @"Please connect this device to your Mac and start TouchBarServer.";
    } else if (_serverVersion && _serverVersion.unsignedLongLongValue != kServerVersion) {
        if (_serverVersion.unsignedLongLongValue < kServerVersion) {
            _infoLabelView.text = @"🚫 Connected to older, incompatible TouchBarServer version!\n\nPlease build & install the latest TouchBarServer on your Mac.";
        } else {
            _infoLabelView.text = @"🚫 Connected to newer, incompatible TouchBarServer version!\n\nPlease build & install the latest TouchBarClient on this device.";
        }
    } else {
        _infoLabelView.text = @"";
    }
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    ViewTransition *panelViewTransition = [[ViewTransition alloc] initWithView:_panelView];
    ViewTransition *keyboardViewTransition = [[ViewTransition alloc] initWithView:_keyboardView];
    
    NSArray *viewTransitions = @[panelViewTransition, keyboardViewTransition];
    for (ViewTransition *transition in viewTransitions) {
        transition.toVisibility = NO;
    }
    
    switch (_align) {
        case AlignmentBottom: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_demoImageView
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
        case AlignmentMiddle: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_demoImageView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
        case AlignmentTop: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_demoImageView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
    }

    switch (_mode) {
        case OperatingModeTouchBarOnly: {
            haveKeyboard = NO;
            panelViewTransition.toBackgroundColor = [UIColor blackColor];
            panelViewTransition.toVisibility = YES;
            [constraints addObjectsFromArray:[self stickPanelToScreenConstraintsForActive:self.active]];
            panelViewTransition.willBeOffScreen = !self.active;
            break;
        }
        case OperatingModeKeyboard: {
            haveKeyboard = YES;
            panelViewTransition.toBackgroundColor = [UIColor colorWithWhite:0.63 alpha:1.0];
            panelViewTransition.toVisibility = YES;
            [constraints addObjectsFromArray:[self stickPanelToScreenConstraintsForActive:self.active]];
            panelViewTransition.willBeOffScreen = !self.active;
            break;
        }
        case OperatingModeDemo1:
        case OperatingModeDemo2:
        case OperatingModeDemo3:
        case OperatingModeDemo4:
        case OperatingModeDemo5: {
            NSDictionary *parameters = _demoParameters[_mode - OperatingModeDemo1];
            
            haveKeyboard = YES;
            panelViewTransition.toBackgroundColor = [UIColor clearColor];
            panelViewTransition.toVisibility = YES;
            demoImage = parameters[@"image"];
            
            [_demoImageView removeConstraint:_demoImageAspectRatioConstraint];
            _demoImageAspectRatioConstraint = [NSLayoutConstraint constraintWithItem:_demoImageAspectRatioConstraint.firstItem
                                                                           attribute:_demoImageAspectRatioConstraint.firstAttribute
                                                                           relatedBy:_demoImageAspectRatioConstraint.relation
                                                                              toItem:_demoImageAspectRatioConstraint.secondItem
                                                                           attribute:_demoImageAspectRatioConstraint.secondAttribute
                                                                          multiplier:demoImage.size.width / demoImage.size.height
                                                                            constant:0.0];
            [_demoImageView addConstraint:_demoImageAspectRatioConstraint];

            [constraints addObjectsFromArray:[self stickKeyboardToDemoImageConstraintsForParameters:parameters]];
            break;
        }
    }

    if (haveKeyboard) {
        keyboardViewTransition.toVisibility = YES;
        [constraints addObjectsFromArray:[self stickKeyboardToPanelConstraints]];
    } else {
        keyboardViewTransition.toVisibility = NO;
        [constraints addObjectsFromArray:[self stickTouchBarToPanelConstraints]];
    }
    
    if (!self.active) {
        for (ViewTransition *transition in viewTransitions) {
            transition.toVisibility = transition.willBeOffScreen;
        }
        
        keyboardViewTransition.toVisibility = haveKeyboard;
        demoImage = nil;
    }
    
    _constraints = constraints;
    [self.view addConstraints:constraints];
    
    if (animated) {
        for (ViewTransition *transition in viewTransitions) {
            if (transition.toVisibility != transition.fromVisibility) {
                transition.view.hidden = NO;
                transition.view.alpha = transition.toVisibility ? 0.0 : 1.0;
            }
        }

        if (_demoImageView.image != demoImage) {
            [UIView transitionWithView:_demoImageView
                              duration:kAnimationDuration
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                _demoImageView.image = demoImage;
                            } completion:nil];
        }

        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self.view layoutIfNeeded];
            for (ViewTransition *transition in viewTransitions) {
                transition.view.backgroundColor = transition.toBackgroundColor;
                if (transition.toVisibility != transition.fromVisibility) {
                    transition.view.alpha = transition.toVisibility ? 1.0 : 0.0;
                }
            }
        } completion:^(BOOL finished) {
            for (ViewTransition *transition in viewTransitions) {
                if (transition.toVisibility == NO && transition.view.alpha == 0.0) {
                    transition.view.hidden = YES;
                }
            }
        }];
    } else {
        if (_demoImageView.image != demoImage) {
            _demoImageView.image = demoImage;
        }
        for (ViewTransition *transition in viewTransitions) {
            transition.view.hidden = !transition.toVisibility;
            transition.view.alpha = transition.toVisibility ? 1.0 : 0.0;
            transition.view.backgroundColor = transition.toBackgroundColor;
        }
        
        [self.view layoutIfNeeded];
    }
}

- (NSArray *)stickTouchBarToPanelConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_touchBarView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:0.98
                                                         constant:0.0]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_touchBarView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:0.59
                                                         constant:0.0]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_touchBarView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_touchBarView
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];

    return constraints;
}

- (NSArray *)stickKeyboardToPanelConstraints {
    NSMutableArray *constraints = [NSMutableArray new];

    CGFloat margin = 1.0;
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                         constant:margin]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant:-margin]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:margin]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_panelView
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:-margin]];

    return constraints;
}

- (NSArray *)stickPanelToScreenConstraintsForActive:(BOOL)active {
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_panelView
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_panelView
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant:0.0]];

    switch (_align) {
        case AlignmentBottom: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_panelView
                                                                attribute:active ? NSLayoutAttributeBottom : NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
        case AlignmentMiddle: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_panelView
                                                                attribute:active ? NSLayoutAttributeCenterY : NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:active ? NSLayoutAttributeCenterY : NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
        case AlignmentTop: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_panelView
                                                                attribute:active ? NSLayoutAttributeTop : NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0]];
            break;
        }
    }
    
    return constraints;
}

- (NSArray *)stickKeyboardToDemoImageConstraintsForParameters:(NSDictionary *)parameters {
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_demoImageView
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:[parameters[@"keyboardWidth"] doubleValue]
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_demoImageView
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_demoImageTopMarginView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_demoImageView
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:[parameters[@"keyboardCenterY"] doubleValue]
                                                         constant:0.0]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_keyboardView
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_demoImageTopMarginView
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:0.0]];

    return constraints;
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    if (_serverVersion && _serverVersion.unsignedLongLongValue != kServerVersion) {
        // Ignore messages from incompatible server
        return NO;
    }

    return type >= kProtocolFrameTypeServerMin && type <= kProtocolFrameTypeServerMax;
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    if (payload.data == nil) return;

    switch (type) {
        case ProtocolFrameTypeServerVersion: {
            if (!_serverVersion) {
                Version *version = (Version *)payload.data;
                _serverVersion = @(*version);
                [self updateViews:self.active];
            }
        }
            
        case ProtocolFrameTypeServerImage: {
            UIImage *image = [UIImage imageWithData:[NSData dataWithBytes:payload.data length:payload.length]];
            if (image == nil) break;
            
            _touchBarView.image = image;

            if (!_touchBarReady) {
                [_touchBarView removeConstraint:_touchBarAspectRatioConstraint];
                _touchBarAspectRatioConstraint = [NSLayoutConstraint constraintWithItem:_touchBarAspectRatioConstraint.firstItem
                                                                              attribute:_touchBarAspectRatioConstraint.firstAttribute
                                                                              relatedBy:_touchBarAspectRatioConstraint.relation
                                                                                 toItem:_touchBarAspectRatioConstraint.secondItem
                                                                              attribute:_touchBarAspectRatioConstraint.secondAttribute
                                                                             multiplier:image.size.width / image.size.height
                                                                               constant:0.0];
                [_touchBarView addConstraint:_touchBarAspectRatioConstraint];

                BOOL wasActive = self.active;
                _touchBarReady = YES;
                [self updateViews:wasActive || self.active];
            }
            
            break;
        }
        case ProtocolFrameTypeServerKeyboardLayout: {
            NSData *data = [NSData dataWithBytes:payload.data length:payload.length];
            NSDictionary *layoutInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            _keyboardView.layoutType = [layoutInfo[@"type"] integerValue];
            _keyboardView.keyCaptions = layoutInfo[@"captions"];
            if (!_keyboardReady) {
                BOOL wasActive = self.active;
                _keyboardReady = YES;
                [self updateViews:wasActive || self.active];
            }
            break;
        }
        case ProtocolFrameTypeServerSystemKeyEvent: {
            KeyEvent *keyEvent = (KeyEvent *)payload.data;
            [_keyboardView externalKeyEvent:*keyEvent];
            break;
        }
        case ProtocolFrameTypeServerModeChange: {
            OperatingMode *mode = (OperatingMode *)payload.data;
            self.mode = *mode;
            break;
        }
        case ProtocolFrameTypeServerAlignChange: {
            Alignment *align = (Alignment *)payload.data;
            self.align = *align;
            break;
        }
        default:
            break;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    if (channel == _listenChannel && error) {
        [self startListening];
    }
    
    if (channel == _peerChannel) {
        BOOL wasActive = self.active;

        [self resetSession];

        [self updateViews:wasActive || self.active];
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address {
    if (_peerChannel) {
        [_peerChannel close];
        _peerChannel = nil;
    }

    BOOL wasActive = self.active;

    [self resetSession];
    _peerChannel = otherChannel;
    _peerChannel.userInfo = address;

    [self updateViews:wasActive || self.active];
}

#pragma mark - KeyboardViewDelegate

- (void)keyboardView:(KeyboardView*)keyboardView keyEvent:(KeyEvent)keyEvent {
    if (!_peerChannel || _panelView.hidden || _keyboardView.hidden) return;

    NSData* data = [NSData dataWithBytes:&keyEvent length:sizeof(keyEvent)];
    CFDataRef immutableSelf = CFBridgingRetain([data copy]);
    dispatch_data_t payload = dispatch_data_create(data.bytes, data.length, dispatch_get_main_queue(), ^{
        CFRelease(immutableSelf);
    });
    
    [_peerChannel sendFrameOfType:ProtocolFrameTypeClientKeyboardKeyEvent tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to send message: %@", error);
        }
    }];
}

@end
