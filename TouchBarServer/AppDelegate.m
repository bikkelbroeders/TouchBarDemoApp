//
//  AppDelegate.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "AppDelegate.h"

#import "Protocol.h"

NSString *const ErrorDomain = @"com.bikkelbroeders.touchbar";
static const NSTimeInterval kReconnectDelay = 1.0;

extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler);
extern BOOL DFRSetStatus(int);
extern BOOL DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p);

@interface TouchBarView : NSView
@end

@implementation TouchBarView {
    CGDisplayStreamRef _stream;
    NSView *_displayView;
}

- (instancetype) init {
    self = [super init];
    if(self != nil) {
        _displayView = [NSView new];
        _displayView.frame = NSMakeRect(5, 5, 1085, 30);
        _displayView.wantsLayer = YES;
        [self addSubview:_displayView];
        
        _stream = SLSDFRDisplayStreamCreate(NULL, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status,
                                                                               uint64_t displayTime,
                                                                               IOSurfaceRef frameSurface,
                                                                               CGDisplayStreamUpdateRef updateRef) {
            _displayView.layer.contents = (__bridge id)(frameSurface);
        });
        
        DFRSetStatus(2);
        CGDisplayStreamStart(_stream);
    }
    
    return self;
}

- (void)commonMouseEvent:(NSEvent *)event {
    NSPoint location = [_displayView convertPoint:[event locationInWindow] fromView:nil];
    DFRFoundationPostEventWithMouseActivity(event.type, location);
}

- (void)mouseDown:(NSEvent *)event {
    [self commonMouseEvent:event];
}

- (void)mouseUp:(NSEvent *)event {
    [self commonMouseEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self commonMouseEvent:event];
}

@end

@interface NSWindow (Private)
- (void )_setPreventsActivation:(bool)preventsActivation;
@end

@interface TouchBarWindow : NSWindow
@end

@implementation TouchBarWindow

- (instancetype)init {
    self = [super init];
    if(self != nil) {
        self.styleMask = NSBorderlessWindowMask;
        self.acceptsMouseMovedEvents = YES;
        self.movableByWindowBackground = NO;
        self.level = NSPopUpMenuWindowLevel;
        self.backgroundColor = [NSColor blackColor];
        [self _setPreventsActivation:YES];
        [self setFrame:NSMakeRect(0, 0, 1085 + 10, 30 + 10) display:YES];
        
        self.contentView = [TouchBarView new];
    }
    
    return self;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

@end

@interface AppDelegate () <PTChannelDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *screenBarMenuItem;
@property (weak) IBOutlet NSMenuItem *remoteBarMenuItem;

@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    id _monitor;
    id _localMonitor;
    TouchBarWindow* _touchBarWindow;

    dispatch_queue_t _connectQueue;
    NSNumber *_connectingDeviceID;
    NSNumber *_connectedDeviceID;
    PTChannel *_connectedChannel;
    CGDisplayStreamRef _stream;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if (!NSClassFromString(@"DFRElement")) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error: could not detect Touch Bar support"];
        [alert setInformativeText:@"We need at least macOS 10.12.1 (build 16B2657)"];
        [alert addButtonWithTitle:@"Exit"];
        [alert runModal];
        
        [NSApp terminate:nil];
        return;
    }
    
    _touchBarWindow = [TouchBarWindow new];
    [_touchBarWindow setIsVisible:NO];
    
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [defaults setInitialValues:@{
                                 @"EnableScreenBar": @YES,
                                 @"EnableRemoteBar": @YES,
                                 }];

    [_screenBarMenuItem bind:@"value"
                    toObject:defaults
                 withKeyPath:@"values.EnableScreenBar"
                     options:@{@"NSContinuouslyUpdatesValue": @YES}];

    [_remoteBarMenuItem bind:@"value"
                    toObject:defaults
                 withKeyPath:@"values.EnableRemoteBar"
                     options:@{@"NSContinuouslyUpdatesValue": @YES}];

    [[defaults values] setValue:[[defaults values] valueForKey:@"EnableScreenBar"] forKey:@"EnableScreenBar"];
    [[defaults values] setValue:[[defaults values] valueForKey:@"EnableRemoteBar"] forKey:@"EnableRemoteBar"];
    
    [defaults addObserver:self forKeyPath:@"values.EnableScreenBar" options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:@"values.EnableRemoteBar" options:NSKeyValueObservingOptionNew context:NULL];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.menu = self.menu;
    _statusItem.highlightMode = YES;
    _statusItem.image = [NSImage imageNamed:@"NSSlideshowTemplate"];
    [self stopStreaming];
    
    _connectQueue = dispatch_queue_create("TouchBar.connectQueue", DISPATCH_QUEUE_SERIAL);

    [self startListeningForDevices];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSUserDefaultsController *defaults = (NSUserDefaultsController *)object;
    BOOL value = [[defaults valueForKeyPath:keyPath] boolValue];

    if ([keyPath isEqualToString:@"values.EnableScreenBar"]) {
        if (value && AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)(@{(__bridge id)kAXTrustedCheckOptionPrompt:@YES})) == NO) {
            [defaults setValue:@NO forKeyPath:keyPath];
            return;
        }
        
        if (value) {
            [_touchBarWindow setIsVisible:NO];

            [self startDetectSingleFnKeyPress:^{
                if (_touchBarWindow.visible == YES) {
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                        context.duration = 0.1;
                        [[_touchBarWindow animator] setAlphaValue:0.0];
                    } completionHandler:^{
                        if(_touchBarWindow.alphaValue == 0.0)
                            [_touchBarWindow setIsVisible:NO];
                    }];
                } else {

                    NSPoint mousePoint = [NSEvent mouseLocation];
                    NSScreen* currentScreen = [NSScreen mainScreen];
                    for(NSScreen* screen in [NSScreen screens])
                    {
                        if(NSPointInRect(mousePoint, screen.visibleFrame)) {
                            currentScreen = screen;
                            break;
                        }
                    }
                    
                    NSRect screenFrame = currentScreen.visibleFrame;
                    CGFloat screenRight = screenFrame.origin.x + screenFrame.size.width;
                    CGFloat barWidth = _touchBarWindow.frame.size.width;
                    CGFloat barHeight = _touchBarWindow.frame.size.height;
                    
                    NSPoint origin = mousePoint;
                    origin.x -= barWidth * 0.5;
                    origin.y -= barHeight;
                    
                    if(origin.x < screenFrame.origin.x)
                        origin.x = screenFrame.origin.x;
                    
                    if(origin.x + barWidth > screenRight)
                        origin.x = screenRight - barWidth;
                    
                    if(origin.y - barHeight < screenFrame.origin.y)
                        origin.y += barHeight;
                    
                    [_touchBarWindow setFrameOrigin:origin];

                    _touchBarWindow.alphaValue = 1.0;
                    [_touchBarWindow setIsVisible:YES];
                }
            }];
        } else {
            [self stopDetectingSingleFnKeyPress];
            [_touchBarWindow setIsVisible:NO];
        }
    } else if ([keyPath isEqualToString:@"values.EnableRemoteBar"]) {
        if (value) {
            if (_connectingDeviceID && !_connectedDeviceID) {
                [self enqueueConnectToUSBDevice];
            }
        } else {
            [self disconnectFromCurrentChannel];
        }
    }
}

- (void)startDetectSingleFnKeyPress:(void (^)(void))handler
{
    if(_monitor != nil)
        return;
    
    NSMutableSet<NSNumber*>* pressedKeySet = [NSMutableSet new];
    __block BOOL fnKeyIsDown = NO;
    __block BOOL couldBeSoleFnKeyPress = YES;
    __block NSEventModifierFlags otherModifiersBesideFn = 0;
    NSEvent* (^monitorHandler)(NSEvent*) = ^(NSEvent* event) {
        
        switch(event.type) {
            case NSKeyDown:
                [pressedKeySet addObject:@(event.keyCode)];
                couldBeSoleFnKeyPress = NO;
                break;
                
            case NSKeyUp:
                [pressedKeySet removeObject:@(event.keyCode)];
                couldBeSoleFnKeyPress = NO;
                break;
                
            case NSFlagsChanged: {
                NSEventModifierFlags modifierFlags = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);
                otherModifiersBesideFn = (modifierFlags & ~NSFunctionKeyMask);
                BOOL newFnKeyIsDown = (modifierFlags & NSFunctionKeyMask) != 0;
                
                if(newFnKeyIsDown != fnKeyIsDown) {
                    fnKeyIsDown = newFnKeyIsDown;
                    if(otherModifiersBesideFn == 0 && pressedKeySet.count == 0) {
                        if(fnKeyIsDown == YES){
                            couldBeSoleFnKeyPress = YES;
                        } else if(couldBeSoleFnKeyPress == YES) {
                            if(handler != nil)
                                handler();
                        }
                    }
                }
                
                if(otherModifiersBesideFn != 0 || pressedKeySet.count > 0)
                    couldBeSoleFnKeyPress = NO;
            }
                break;
                
            default:
                break;
        }
        
        return event;
    };
    _monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask handler:^(NSEvent* event){
        monitorHandler(event);
    }];
    _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask handler:monitorHandler];
}

- (void)stopDetectingSingleFnKeyPress
{
    if(_monitor != nil)
    {
        [NSEvent removeMonitor:_monitor];
        _monitor = nil;
    }
    
    if (_localMonitor) {
        [NSEvent removeMonitor:_localMonitor];
        _localMonitor = nil;
    }
}

- (void)startStreaming {
    if (_stream) return;
    
    _stream = SLSDFRDisplayStreamCreate(NULL, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status,
                                                                                             uint64_t displayTime,
                                                                                             IOSurfaceRef frameSurface,
                                                                                             CGDisplayStreamUpdateRef updateRef) {
        if (_connectedChannel == nil) {
            [self stopStreaming];
            return;
        }
        
        CIImage *image = [CIImage imageWithIOSurface:frameSurface];
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCIImage:image];
        NSData* data = [rep representationUsingType:NSPNGFileType properties:@{}];
        
        CFDataRef immutableSelf = CFBridgingRetain([data copy]);
        dispatch_data_t payload = dispatch_data_create(data.bytes, data.length, dispatch_get_main_queue(), ^{
            CFRelease(immutableSelf);
        });
        
        [_connectedChannel sendFrameOfType:ProtocolFrameTypeImage tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
            if (error) {
                NSLog(@"Failed to send message: %@", error);
            }
        }];
    });
    
    DFRSetStatus(2);
    CGDisplayStreamStart(_stream);
}

- (void)stopStreaming {
    if (_stream) {
        CGDisplayStreamStop(_stream);
        _stream = nil;
    }
}

#pragma mark - Connection stuff

- (void)startListeningForDevices {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = note.userInfo[@"DeviceID"];
//        NSLog(@"PTUSBDeviceDidAttachNotification: %@", deviceID);
        
        if (_connectedDeviceID) {
            return;
        }
        
        dispatch_async(_connectQueue, ^{
            if (!_connectingDeviceID || ![deviceID isEqualToNumber:_connectingDeviceID]) {
                [self disconnectFromCurrentChannel];
                _connectingDeviceID = deviceID;
                
                NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
                if ([[[defaults values] valueForKey:@"EnableRemoteBar"] boolValue]) {
                    [self enqueueConnectToUSBDevice];
                }
            }
        });
    }];

    [nc addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = note.userInfo[@"DeviceID"];
//        NSLog(@"PTUSBDeviceDidDetachNotification: %@", deviceID);
        
        if ([_connectingDeviceID isEqualToNumber:deviceID]) {
            _connectingDeviceID = nil;
            [_connectedChannel close];
            _connectedChannel = nil;
            [self stopStreaming];
        }
    }];
}

- (void)enqueueConnectToUSBDevice {
    dispatch_async(_connectQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self connectToUSBDevice];
        });
    });
}


- (void)connectToUSBDevice {
    if (_connectedDeviceID) {
        return;
    }

    PTChannel *channel = [PTChannel channelWithDelegate:self];
    channel.userInfo = _connectingDeviceID;

    [channel connectToPort:kProtocolPort overUSBHub:PTUSBHub.sharedHub deviceID:_connectingDeviceID callback:^(NSError *error) {
        if (error) {
            if (error.domain == PTUSBHubErrorDomain && error.code == PTUSBHubErrorConnectionRefused) {
//                NSLog(@"Failed to connect to device %@: %@", channel.userInfo, error);
            } else {
                NSLog(@"Failed to connect to device %@: %@", channel.userInfo, error);
            }
            if (channel.userInfo == _connectingDeviceID) {
                [self performSelector:@selector(enqueueConnectToUSBDevice) withObject:nil afterDelay:kReconnectDelay];
            }
        } else {
            _connectedDeviceID = _connectingDeviceID;
            _connectedChannel = channel;
            [self startStreaming];
            NSLog(@"Connected to device %@", _connectedDeviceID);
        }
    }];
}

- (void)disconnectFromCurrentChannel {
    if (_connectedDeviceID && _connectedChannel) {
        [_connectedChannel close];
        _connectedChannel = nil;
        [self stopStreaming];
    }
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    switch (type) {
        case ProtocolFrameTypeMouseEvent:
            return YES;
        default:
            NSLog(@"Unexpected frame of type %u", type);
            [channel close];
            return NO;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    switch (type) {
        case ProtocolFrameTypeMouseEvent: {
            if (payload.data == nil) break;
            MouseEvent *event = (MouseEvent *)payload.data;
            NSPoint location = NSMakePoint(event->x, event->y);
            NSEventType eventType = NSEventTypeLeftMouseDown;
            switch(event->type) {
                case MouseEventTypeDown:
                    eventType = NSEventTypeLeftMouseDown;
                    break;
                case MouseEventTypeUp:
                    eventType = NSEventTypeLeftMouseUp;
                    break;
                case MouseEventTypeDragged:
                    eventType = NSEventTypeLeftMouseDragged;
                    break;
            }
            
            DFRFoundationPostEventWithMouseActivity(eventType, location);
            break;
        }
        default:
            break;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    if (_connectedDeviceID && [_connectedDeviceID isEqualToNumber:channel.userInfo]) {
        _connectedDeviceID = nil;
    }
    
    if (_connectedChannel == channel) {
        _connectedChannel = nil;
        [self stopStreaming];
        NSLog(@"Disconnected from %@", channel.userInfo);
    }
}

@end
