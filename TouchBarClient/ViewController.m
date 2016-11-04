//
//  ViewController.m
//  TouchBarClient
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "ViewController.h"

#import "Peertalk.h"
#import "Protocol.h"

static const NSTimeInterval kAnimationDuration = 0.5;

@interface ViewController () <PTChannelDelegate>

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;

@end

@implementation ViewController {
    PTChannel *_channel;
    BOOL _active;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    PTChannel* channel = [PTChannel channelWithDelegate:self];
    [channel listenOnPort:kProtocolPort IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Failed to listen on localhost:%d: %@", kProtocolPort, error);
        } else {
            NSLog(@"Listening on localhost:%d", kProtocolPort);
        }
    }];
    
    [self deactivateTouchBar:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [super viewDidDisappear:animated];
}

- (IBAction)recognizerFired:(UIGestureRecognizer*)recognizer {
    if (!_channel || !_active) return;
    
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

    // XXX hardcoded 2, because the touch bar is rendered @2x
    CGFloat scale = 2 * _imageView.frame.size.width / _imageView.image.size.width;
    CGPoint location = [recognizer locationInView:_imageView];

    event.x = location.x / scale;
    event.y = location.y / scale;

    NSData* data = [NSData dataWithBytes:&event length:sizeof(event)];
    CFDataRef immutableSelf = CFBridgingRetain([data copy]);
    dispatch_data_t payload = dispatch_data_create(data.bytes, data.length, dispatch_get_main_queue(), ^{
        CFRelease(immutableSelf);
    });
    
    [_channel sendFrameOfType:ProtocolFrameTypeMouseEvent tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to send message: %@", error);
        }
    }];
}

- (void)activateTouchBar:(BOOL)animated {
    [self.view layoutIfNeeded];
    _bottomConstraint.constant = 0;
    _active = YES;

    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            _instructionLabel.alpha = 0;
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)deactivateTouchBar:(BOOL)animated {
    [self.view layoutIfNeeded];
    _bottomConstraint.constant = -_backgroundView.frame.size.height;
    _active = NO;

    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            _instructionLabel.alpha = 1;
            [self.view layoutIfNeeded];
        }];
    }
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    if (channel != _channel) {
        return NO;
    }
    
    switch (type) {
        case ProtocolFrameTypeImage:
            return YES;
        default:
            NSLog(@"Unexpected frame of type %u", type);
            [channel close];
            [self deactivateTouchBar:YES];
            return NO;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    switch (type) {
        case ProtocolFrameTypeImage: {
            if (payload.data == nil) break;
            UIImage *image = [UIImage imageWithData:[NSData dataWithBytes:payload.data length:payload.length]];
            //UIImageView *imageView = (UIImageView *)self.view;
            _imageView.image = image;
            
            [_imageView removeConstraint:_aspectRatioConstraint];
            _aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:_aspectRatioConstraint.firstItem
                                                                  attribute:_aspectRatioConstraint.firstAttribute
                                                                  relatedBy:_aspectRatioConstraint.relation
                                                                     toItem:_aspectRatioConstraint.secondItem
                                                                  attribute:_aspectRatioConstraint.secondAttribute
                                                                 multiplier:image.size.width / image.size.height
                                                                   constant:0.0];
            [_imageView addConstraint:_aspectRatioConstraint];
            break;
        }
        default:
            break;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    if (error) {
        NSLog(@"%@ ended with error: %@", channel, error);
    } else {
        NSLog(@"Disconnected from %@", channel.userInfo);
    }
    [self deactivateTouchBar:YES];
}

- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address {
    if (_channel) {
        [_channel cancel];
    }
    
    _channel = otherChannel;
    _channel.userInfo = address;
    NSLog(@"Connected to %@", address);
    [self activateTouchBar:YES];
}

@end
