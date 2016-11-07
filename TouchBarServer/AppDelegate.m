//
//  AppDelegate.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "AppDelegate.h"

#import "Protocol.h"
#import "UsbDeviceController.h"

@import Carbon;

typedef int CGSConnectionID;
CG_EXTERN void CGSGetKeys(KeyMap k);
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN void CGSGetBackgroundEventMask(CGSConnectionID cid, int *outMask);
CG_EXTERN CGError CGSSetBackgroundEventMask(CGSConnectionID cid, int mask);

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
            if (status != kCGDisplayStreamFrameStatusFrameComplete) return;
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

@interface AppDelegate () <UsbDeviceControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *screenBarMenuItem;
@property (weak) IBOutlet NSMenuItem *remoteBarMenuItem;

@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    TouchBarWindow* _touchBarWindow;
    
    CGDisplayStreamRef _stream;
    UsbDeviceController *_usbDeviceController;
    
    BOOL _fnKeyIsDown;
    BOOL _couldBeSoleFnKeyPress;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if (!NSClassFromString(@"DFRElement")) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error: could not detect Touch Bar support"];
        [alert setInformativeText:[NSString stringWithFormat:@"We need at least macOS 10.12.1 (Build 16B2657).\n\nYou have: %@.\n", [NSProcessInfo processInfo].operatingSystemVersionString]];
        [alert addButtonWithTitle:@"Exit"];
        [alert addButtonWithTitle:@"Get macOS Update"];
        NSModalResponse response = [alert runModal];
        if(response == NSAlertSecondButtonReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.apple.com/kb/dl1897"]];
        }
        
        [NSApp terminate:nil];
        return;
    }
    
    _usbDeviceController = [[UsbDeviceController alloc] initWithPort:kProtocolPort];
    _usbDeviceController.delegate = self;
    
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
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSUserDefaultsController *defaults = (NSUserDefaultsController *)object;
    BOOL value = [[defaults valueForKeyPath:keyPath] boolValue];

    if ([keyPath isEqualToString:@"values.EnableScreenBar"]) {
        CGSConnectionID connectionId = CGSMainConnectionID();
        int backgroundEventMask;
        int keyEventMask = NSKeyDownMask | NSKeyUpMask | NSFlagsChangedMask;
        CGSGetBackgroundEventMask(connectionId, &backgroundEventMask);
        if (value) {
            [_touchBarWindow setIsVisible:NO];
            CGSSetBackgroundEventMask(connectionId, backgroundEventMask | keyEventMask);
        } else {
            CGSSetBackgroundEventMask(connectionId, backgroundEventMask & ~keyEventMask);
            [_touchBarWindow setIsVisible:NO];
        }
    } else if ([keyPath isEqualToString:@"values.EnableRemoteBar"]) {
        if (value) {
            [_usbDeviceController startConnectingToUsbDevices];
        } else {
            [_usbDeviceController stopConnectingToUsbDevices];
        }
    }
}

- (void)toggleTouchBarWindow {
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
}

- (void)keyEvent:(NSEvent *)event {
    if (![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"EnableScreenBar"] boolValue]) return;

    switch(event.type) {
        case NSKeyDown:
            _couldBeSoleFnKeyPress = NO;
            break;
            
        case NSKeyUp:
            _couldBeSoleFnKeyPress = NO;
            break;
            
        case NSFlagsChanged: {
            NSEventModifierFlags modifierFlags = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);
            BOOL newFnKeyIsDown = (modifierFlags & NSFunctionKeyMask) != 0;
            
            if(newFnKeyIsDown != _fnKeyIsDown) {
                _fnKeyIsDown = newFnKeyIsDown;
                
                KeyMap keymap;
                CGSGetKeys(keymap);
                
                if (keymap[0].bigEndianValue == 0 && keymap[2].bigEndianValue == 0 && keymap[3].bigEndianValue == 0) {
                    if (_fnKeyIsDown) {
                        _couldBeSoleFnKeyPress = keymap[1].bigEndianValue == 1 << 31;
                    } else if (_couldBeSoleFnKeyPress && keymap[1].bigEndianValue == 0) {
                        [self toggleTouchBarWindow];
                    }
                } else {
                    _couldBeSoleFnKeyPress = NO;
                }
                
            } else {
                _couldBeSoleFnKeyPress = NO;
            }
        }
            
        default:
            break;
    }
}

- (void)startStreaming {
    if (_stream) return;
    
    _stream = SLSDFRDisplayStreamCreate(NULL, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CGDisplayStreamFrameStatus status,
                                                                                             uint64_t displayTime,
                                                                                             IOSurfaceRef frameSurface,
                                                                                             CGDisplayStreamUpdateRef updateRef) {
        if (status != kCGDisplayStreamFrameStatusFrameComplete) return;
        
        IOSurfaceLock(frameSurface, kIOSurfaceLockReadOnly, nil);
        CIImage *image = [CIImage imageWithIOSurface:frameSurface];
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCIImage:image];
        NSData* data = [rep representationUsingType:NSPNGFileType properties:@{}];
        IOSurfaceUnlock(frameSurface, kIOSurfaceLockReadOnly, nil);
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [_usbDeviceController broadcaseMessageOfType:ProtocolFrameTypeImage data:data callback:^(NSDictionary *errors) {
                dispatch_semaphore_signal(sema);
                if (errors) {
                    for (NSNumber *deviceId in errors) {
                        NSError *error = errors[deviceId];
                        NSLog(@"Failed to send message to device %@: %@", deviceId, error);
                    }
                }
            }];
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
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

#pragma mark - UsbDeviceControllerDelegate

- (void)deviceDidConnect:(NSNumber *)deviceId {
    // Always start a new stream so the new device gets an initial frame
    [self stopStreaming];
    [self startStreaming];
}

- (void)deviceDidDisconnect:(NSNumber *)deviceId {
    if ([[_usbDeviceController connectedDeviceIds] count] == 0) {
        [self stopStreaming];
    }
}

- (void)device:(NSNumber *)deviceId didReceiveMessageOfType:(uint32_t)type data:(NSData *)data {
    switch (type) {
        case ProtocolFrameTypeMouseEvent: {
            MouseEvent *event = (MouseEvent *)data.bytes;
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

@end
