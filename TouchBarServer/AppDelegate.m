//
//  AppDelegate.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "AppDelegate.h"

#import "GlobalEventApplication.h"
#import "Keyboard.h"
#import "ModifierKeyController.h"
#import "Protocol.h"
#import "TouchBarWindow.h"
#import "UsbDeviceController.h"

#import "KeyboardLayout.h"
#import "KeyboardLayoutANSI.h"
#import "KeyboardLayoutISO.h"
#import "KeyboardLayoutJIS.h"

@import Carbon;

extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler);
extern BOOL DFRSetStatus(int);
extern BOOL DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p);

static NSString * const kUserDefaultsKeyScreenEnable    = @"ScreenEnable";
static NSString * const kUserDefaultsKeyScreenToggleKey = @"ScreenToggleKey";
static NSString * const kUserDefaultsKeyRemoteEnable    = @"RemoteEnable";
static NSString * const kUserDefaultsKeyScreenFixedLeft    = @"ScreenFixedLeft";
static NSString * const kUserDefaultsKeyScreenFixedCenter    = @"ScreenFixedCenter";
static NSString * const kUserDefaultsKeyScreenFixedRight    = @"ScreenFixedRight";
static NSString * const kUserDefaultsKeyRemoteMode      = @"RemoteMode";
static NSString * const kUserDefaultsKeyRemoteAlign     = @"RemoteAlign";

@interface AppDelegate () <ModifierKeyControllerDelegate, UsbDeviceControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *screenSubMenuItem;
@property (weak) IBOutlet NSMenuItem *remoteSubMenuItem;

// Settings
@property (nonatomic, assign) BOOL screenEnable;
@property (nonatomic, assign) ModifierKey screenToggleKey;
@property (nonatomic, assign) BOOL remoteEnable;
@property (nonatomic, assign) BOOL ScreenFixedLeft;
@property (nonatomic, assign) BOOL ScreenFixedCenter;
@property (nonatomic, assign) BOOL ScreenFixedRight;
@property (nonatomic, assign) OperatingMode remoteMode;
@property (nonatomic, assign) Alignment remoteAlign;

@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    TouchBarWindow* _touchBarWindow;
    
    ModifierKeyController *_modifierKeyController;

    CGDisplayStreamRef _stream;
    UsbDeviceController *_usbDeviceController;

    UInt8 _keyboardType;
    KeyboardLayout *_keyboardLayout;
    
    NSEventModifierFlags _modifierFlags;
    NSInteger _lastMacKeyCodeDown;
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
    
    _keyboardType = LMGetKbdType();
    switch (KBGetLayoutType(_keyboardType)) {
        case kKeyboardISO:
            _keyboardLayout = [KeyboardLayoutISO new];
            break;
        case kKeyboardJIS:
            _keyboardLayout = [KeyboardLayoutJIS new];
            break;
        case kKeyboardANSI:
        default:
            _keyboardLayout = [KeyboardLayoutANSI new];
            break;
    }
    _keyboardType = _keyboardLayout.macKbdType;

    GlobalEventApplication *app = [NSApplication sharedApplication];
    app.globalEventMask = NSKeyDownMask | NSKeyUpMask | NSFlagsChangedMask |
        NSLeftMouseDownMask | NSLeftMouseUpMask |
        NSRightMouseDownMask | NSRightMouseUpMask |
        NSOtherMouseDownMask | NSOtherMouseUpMask;

    _modifierKeyController = [[ModifierKeyController alloc] init];
    _modifierKeyController.delegate = self;
    
    _usbDeviceController = [[UsbDeviceController alloc] initWithPort:kProtocolPort];
    _usbDeviceController.delegate = self;
    
    _touchBarWindow = [TouchBarWindow new];
    [_touchBarWindow setIsVisible:NO];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              kUserDefaultsKeyScreenEnable: @YES,
                                                              kUserDefaultsKeyScreenToggleKey: @(ModifierKeyFn),
                                                              kUserDefaultsKeyRemoteEnable: @YES,
                                                              kUserDefaultsKeyScreenFixedLeft: @YES,
                                                              kUserDefaultsKeyScreenFixedCenter: @YES,
                                                              kUserDefaultsKeyScreenFixedRight: @YES,kUserDefaultsKeyRemoteMode: @(OperatingModeDemo1),
                                                              kUserDefaultsKeyRemoteAlign: @(AlignmentBottom),
                                                              }];

    _screenEnable = NO;
    self.screenEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyScreenEnable];
    
    _screenToggleKey = -1;
    self.screenToggleKey = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyScreenToggleKey];
    
    _remoteEnable = NO;
    self.remoteEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyRemoteEnable];
    
    _ScreenFixedLeft = NO;
    self.ScreenFixedLeft = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyScreenFixedLeft];
    
    _ScreenFixedCenter = NO;
    self.ScreenFixedCenter = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyScreenFixedCenter];
    
    _ScreenFixedRight = NO;
    self.ScreenFixedRight = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyScreenFixedRight];
    
    _remoteMode = -1;
    self.remoteMode = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyRemoteMode];

    _remoteAlign = -1;
    self.remoteAlign = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyRemoteAlign];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.menu = self.menu;
    _statusItem.highlightMode = YES;
    _statusItem.image = [NSImage imageNamed:@"NSSlideshowTemplate"];
    [self stopStreaming];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeInputSource) name:(NSString *)kTISNotifySelectedKeyboardInputSourceChanged object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
}

- (void)didChangeInputSource {
    [self sendKeyboardLayoutToDevice:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
}

- (void)setScreenEnable:(BOOL)screenEnable {
    if (_screenEnable != screenEnable) {
        _screenEnable = screenEnable;
        [[NSUserDefaults standardUserDefaults] setObject:@(_screenEnable) forKey:kUserDefaultsKeyScreenEnable];
        [[NSUserDefaults standardUserDefaults] synchronize];

        _screenSubMenuItem.state = _screenEnable ? 1 : 0;
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenEnable:)) continue;
            menuItem.state = _screenEnable ? 1 : 0;
        }

        [_touchBarWindow setIsVisible:NO];
        _modifierKeyController.enabled = YES;
    }
}

- (void)setScreenToggleKey:(ModifierKey)screenToggleKey {
    if (_screenToggleKey != screenToggleKey) {
        _screenToggleKey = screenToggleKey;
        [[NSUserDefaults standardUserDefaults] setObject:@(_screenToggleKey) forKey:kUserDefaultsKeyScreenToggleKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenToggleKey:)) continue;
            menuItem.state = menuItem.tag == _screenToggleKey ? 1 : 0;
        }
        
        _modifierKeyController.modifierKey = _screenToggleKey;
    }
}

- (void)setRemoteEnable:(BOOL)remoteEnable {
    if (_remoteEnable != remoteEnable) {
        _remoteEnable = remoteEnable;
        [[NSUserDefaults standardUserDefaults] setObject:@(_remoteEnable) forKey:kUserDefaultsKeyRemoteEnable];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        _remoteSubMenuItem.state = _remoteEnable ? 1 : 0;
        for (NSMenuItem *menuItem in _remoteSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeRemoteEnable:)) continue;
            menuItem.state = _remoteEnable ? 1 : 0;
        }
        
        if (_remoteEnable) {
            [_usbDeviceController startConnectingToUsbDevices];
        } else {
            [_usbDeviceController stopConnectingToUsbDevices];
        }
    }
}

- (void)setScreenFixedLeft:(BOOL)ScreenFixedLeft {
    if (_ScreenFixedLeft != ScreenFixedLeft) {
        _ScreenFixedLeft = ScreenFixedLeft;
        [[NSUserDefaults standardUserDefaults] setObject:@(_ScreenFixedCenter) forKey:kUserDefaultsKeyScreenFixedCenter];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //_screenSubMenuItem.state = _ScreenFixedLeft ? 1 : 0;
        //[self disableCenterTick];
        //[self disableRightTick];
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenFixedLeft:)) continue;
            menuItem.state = _ScreenFixedLeft ? 1 : 0;
        }
        
        if (_ScreenFixedLeft) {
            leftornot = YES;
        } else {
            leftornot = NO;
        }
    }
}
- (void)setScreenFixedCenter:(BOOL)ScreenFixedCenter {
    if (_ScreenFixedCenter != ScreenFixedCenter) {
        _ScreenFixedCenter = ScreenFixedCenter;
        [[NSUserDefaults standardUserDefaults] setObject:@(_ScreenFixedCenter) forKey:kUserDefaultsKeyScreenFixedCenter];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenFixedCenter:)) continue;
            menuItem.state = _ScreenFixedCenter ? 1 : 0;
        }
        
    }
}

- (void)setScreenFixedRight:(BOOL)ScreenFixedRight {
    if (_ScreenFixedRight != ScreenFixedRight) {
        _ScreenFixedRight = ScreenFixedRight;
        [[NSUserDefaults standardUserDefaults] setObject:@(_ScreenFixedRight) forKey:kUserDefaultsKeyScreenFixedRight];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //_screenSubMenuItem.state = _ScreenFixedRight ? 1 : 0;
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenFixedRight:)) continue;
            menuItem.state = _ScreenFixedRight ? 1 : 0;
        }
        
        if (_ScreenFixedRight) {
            rightornot = YES;
        } else {
            rightornot = NO;
        }
    }
}

- (void)disableRightTick:(BOOL)ScreenFixedRight {
    for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
        menuItem.state = 0;
    }
}

- (void)setRemoteMode:(OperatingMode)remoteMode {
    if (_remoteMode != remoteMode) {
        _remoteMode = remoteMode;
        [[NSUserDefaults standardUserDefaults] setObject:@(_remoteMode) forKey:kUserDefaultsKeyRemoteMode];
        [[NSUserDefaults standardUserDefaults] synchronize];

        for (NSMenuItem *menuItem in _remoteSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeRemoteMode:)) continue;
            menuItem.state = menuItem.tag == _remoteMode ? 1 : 0;
        }

        NSData* data = [NSData dataWithBytes:&_remoteMode length:sizeof(_remoteMode)];
        [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerModeChange data:data callback:^(NSDictionary *errors) {}];
    }
}

- (void)setRemoteAlign:(Alignment)remoteAlign {
    if (_remoteAlign != remoteAlign) {
        _remoteAlign = remoteAlign;
        [[NSUserDefaults standardUserDefaults] setObject:@(_remoteAlign) forKey:kUserDefaultsKeyRemoteAlign];
        [[NSUserDefaults standardUserDefaults] synchronize];

        for (NSMenuItem *menuItem in _remoteSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeRemoteAlign:)) continue;
            menuItem.state = menuItem.tag == _remoteAlign ? 1 : 0;
        }

        NSData* data = [NSData dataWithBytes:&_remoteAlign length:sizeof(_remoteAlign)];
        [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerAlignChange data:data callback:^(NSDictionary *errors) {}];
    }
}

- (IBAction)changeScreenEnable:(NSMenuItem *)sender {
    self.screenEnable = (sender.state == 0);
}

- (IBAction)changeScreenToggleKey:(NSMenuItem *)sender {
    self.screenToggleKey = (ModifierKey)sender.tag;
}

- (IBAction)changeRemoteEnable:(NSMenuItem *)sender {
    self.remoteEnable = (sender.state == 0);
}

- (IBAction)changeScreenFixedLeft:(NSMenuItem *)sender {
    self.ScreenFixedLeft = (sender.state == 0);
    //self.screenEnable = (sender.state == 0);
}

- (IBAction)changeScreenFixedCenter:(NSMenuItem *)sender {
    self.ScreenFixedCenter = (sender.state == 0);
    //self.screenEnable = (sender.state == 0);
}

- (IBAction)changeScreenFixedRight:(NSMenuItem *)sender {
    self.ScreenFixedRight = (sender.state == 0);
    //self.screenEnable = (sender.state == 0);
}

- (IBAction)changeRemoteMode:(NSMenuItem *)sender {
    self.remoteMode = (OperatingMode)sender.tag;
}

- (IBAction)changeRemoteAlign:(NSMenuItem *)sender {
    self.remoteAlign = (Alignment)sender.tag;
}

- (void)didPressModifierKey {
    if (self.screenEnable == YES)
        [self toggleTouchBarWindow];
}

- (NSMutableDictionary *)keyCaptionsForCurrentInputSource {
    TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
    CFDataRef ucLayoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData);
    if (!ucLayoutData) {
        CFRelease(inputSource);
        inputSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
        ucLayoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData);
    }
    const UCKeyboardLayout *ucLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(ucLayoutData);

    UInt32 ucModifierFlagsForModifierFlags[KeyEventModifierFlagFunction];
    for (KeyEventModifierFlags modifierFlags = 0; modifierFlags < KeyEventModifierFlagFunction; modifierFlags++) {
        UInt32 flags = 0;
        if (modifierFlags & KeyEventModifierFlagShift)      flags |= (shiftKey   >> 8);
        if (modifierFlags & KeyEventModifierFlagControl)    flags |= (controlKey >> 8);
        if (modifierFlags & KeyEventModifierFlagOption)     flags |= (optionKey  >> 8);
        if (modifierFlags & KeyEventModifierFlagCapsLock)   flags |= (alphaLock  >> 8);
        if (modifierFlags & KeyEventModifierFlagCommand)    flags |= (cmdKey     >> 8);
        ucModifierFlagsForModifierFlags[modifierFlags] = flags;
    }

    NSMutableDictionary *allKeyCaptions = [NSMutableDictionary dictionaryWithCapacity:_keyboardLayout.numberOfKeys];
    for (NSUInteger keyIndex = 0; keyIndex < _keyboardLayout.numberOfKeys; keyIndex++) {
        KeyCode keyCode = [_keyboardLayout keyCodeForKeyIndex:keyIndex];
        if (keyCode == 0xFF) continue;
        if (allKeyCaptions[@(keyCode)]) continue;
        if ([KeyboardLayout fixedKeyCaptionForKeyCode:keyCode withFnDown:NO] != nil) continue;
        
        NSMutableArray *keyCaptions = [NSMutableArray arrayWithCapacity:KeyEventModifierFlagFunction];
        for (KeyEventModifierFlags modifierFlags = 0; modifierFlags < KeyEventModifierFlagFunction; modifierFlags++) {
            UInt32 ucModifierFlags = ucModifierFlagsForModifierFlags[modifierFlags];
            
            UInt32 deadKeyState;
            UniChar unicodeString[4] = {0};
            UniCharCount actualStringLength = 0;

            UCKeyTranslate(ucLayout, keyCode, kUCKeyActionDisplay, ucModifierFlags, _keyboardType, 0, &deadKeyState, sizeof(unicodeString) / sizeof(UniChar), &actualStringLength, unicodeString);
            NSString *keyCaption = [[NSString alloc] initWithCharacters:unicodeString length:actualStringLength];

            if ((modifierFlags & KeyEventModifierFlagControl) && (keyCaption.length == 0 || [keyCaption characterAtIndex:0] < 0x20)) {
                ucModifierFlags &= ~(controlKey >> 8);
                UCKeyTranslate(ucLayout, keyCode, kUCKeyActionDisplay, ucModifierFlags, _keyboardType, 0, &deadKeyState, sizeof(unicodeString) / sizeof(UniChar), &actualStringLength, unicodeString);
                keyCaption = [[NSString alloc] initWithCharacters:unicodeString length:actualStringLength];
            }

            if (keyCaption.length == 0 || [keyCaption characterAtIndex:0] < 0x20) {
                keyCaption = @"";
            }
            [keyCaptions addObject:keyCaption];
        }

        allKeyCaptions[@(keyCode)] = keyCaptions;
    }
    
    CFRelease(inputSource);
    return allKeyCaptions;
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
        
        
        if (_ScreenFixedCenter == YES) {
            NSRect e = [[NSScreen mainScreen] frame];
            int width = (int)e.size.width - 1095;
            width = width/2;
            NSPoint centerBottomPoint = CGPointMake(width, 0);
            [_touchBarWindow setFrameOrigin:centerBottomPoint];
        } else {
            if (_ScreenFixedLeft == YES) {
                NSRect e = [[NSScreen mainScreen] frame];
                int width = (int)e.size.width - 10950;
                width = width/2;
                NSPoint centerBottomPoint = CGPointMake(width, 0);
                [_touchBarWindow setFrameOrigin:centerBottomPoint];
            } else {
                if (_ScreenFixedRight == YES) {
                    NSRect e = [[NSScreen mainScreen] frame];
                    int width = (int)e.size.width - 10;
                    width = width/2;
                    NSPoint centerBottomPoint = CGPointMake(width, 0);
                    [_touchBarWindow setFrameOrigin:centerBottomPoint];
                } else {
                    [_touchBarWindow setFrameOrigin:self.mouseTouchOrigin];
                }
            }
        }
        
        _touchBarWindow.alphaValue = 1.0;
        [_touchBarWindow setIsVisible:YES];
    }
}

- (NSPoint)mouseTouchOrigin {
    NSPoint mousePoint = [NSEvent mouseLocation];
    NSScreen* currentScreen = [NSScreen mainScreen];
    for(NSScreen* screen in [NSScreen screens]) {
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

    return origin;
}

- (NSDictionary *)modifierFlagMapping {
    static NSDictionary *mapping = nil;
    if (mapping == nil) {
        mapping = @{
                    @(KeyEventModifierFlagCapsLock): @(NSEventModifierFlagCapsLock),
                    @(KeyEventModifierFlagShift):    @(NSEventModifierFlagShift),
                    @(KeyEventModifierFlagControl):  @(NSEventModifierFlagControl),
                    @(KeyEventModifierFlagOption):   @(NSEventModifierFlagOption),
                    @(KeyEventModifierFlagCommand):  @(NSEventModifierFlagCommand),
                    @(KeyEventModifierFlagFunction): @(NSEventModifierFlagFunction),
                    };
    }
    return mapping;
}

- (KeyEventModifierFlags)keyboardFlagsFromEventFlags:(NSEventModifierFlags)eventFlags {
    KeyEventModifierFlags keyboardFlags = 0;
    NSDictionary *mapping = [self modifierFlagMapping];
    for (NSNumber *keyboardFlag in mapping) {
        NSNumber *eventFlag = mapping[keyboardFlag];
        if (eventFlags & [eventFlag integerValue]) {
            keyboardFlags |= [keyboardFlag integerValue];
        }
    }
    return keyboardFlags;
}

- (NSEventModifierFlags)eventFlagsFromKeyboardFlags:(KeyEventModifierFlags)keyboardFlags {
    NSEventModifierFlags eventFlags = 0;
    NSDictionary *mapping = [self modifierFlagMapping];
    for (NSNumber *keyboardFlag in mapping) {
        NSNumber *eventFlag = mapping[keyboardFlag];
        if (keyboardFlags & [keyboardFlag integerValue]) {
            eventFlags |= [eventFlag integerValue];
        }
    }
    return eventFlags;
}

- (KeyEvent)keyEventFromEvent:(NSEvent *)event {
    KeyEvent keyEvent;
    switch (event.type) {
        case NSEventTypeKeyDown:
            keyEvent.type = KeyEventTypeKeyDown;
            break;
        case NSEventTypeKeyUp:
            keyEvent.type = KeyEventTypeKeyUp;
            break;
        case NSEventTypeFlagsChanged:
            keyEvent.type = KeyEventTypeFlagsChanged;
            break;
        default:
            return keyEvent;
            break;
    }
    
    keyEvent.key = event.keyCode;
    keyEvent.modifiers = [self keyboardFlagsFromEventFlags:event.modifierFlags];
    
    return keyEvent;
}

- (void)globalEvent:(NSEvent *)event {
    KeyEvent keyEvent = [self keyEventFromEvent:event];
    NSData* data = [NSData dataWithBytes:&keyEvent length:sizeof(keyEvent)];
    [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerSystemKeyEvent data:data callback:^(NSDictionary *errors) {}];

    [_modifierKeyController processEvent:event];

    if (event.type == NSFlagsChanged) {
        _modifierFlags = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);
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
            [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerImage data:data callback:^(NSDictionary *errors) {
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

- (void)keyRepeat {
    if (_lastMacKeyCodeDown == -1)
        return;
    
    CGEventRef eventRef = CGEventCreateKeyboardEvent(NULL, _lastMacKeyCodeDown, true);
    CGEventSetIntegerValueField(eventRef, kCGKeyboardEventAutorepeat, 1);
    CGEventPost(kCGHIDEventTap, eventRef);
    CFRelease(eventRef);

    [self performSelector:@selector(keyRepeat) withObject:nil afterDelay:[NSEvent keyRepeatInterval]];
}
    
- (void)setCapsLockKey:(BOOL)on {
    CFDictionaryRef dict = IOServiceMatching(kIOHIDSystemClass);
    if(dict != nil) {
        io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, (CFDictionaryRef) dict);
        if(service != 0) {
            io_connect_t connect = 0;
            IOServiceOpen(service, mach_task_self(), kIOHIDParamConnectType, &connect);
            if(connect != 0) {
                IOHIDSetModifierLockState(connect, kIOHIDCapsLockState, on ? true : false);
                IOServiceClose(connect);
            }
            IOObjectRelease(service);
        }
    }
}

- (NSEventModifierFlags)modifierFlagsForKeyCode:(CGKeyCode)keyCode {
    switch (keyCode) {
        case kVK_Command:
        case kVK_RightCommand:
            return NSEventModifierFlagCommand;
        case kVK_Shift:
        case kVK_RightShift:
            return NSEventModifierFlagShift;
        case kVK_CapsLock:
            return NSEventModifierFlagCapsLock;
        case kVK_Option:
        case kVK_RightOption:
            return NSEventModifierFlagOption;
        case kVK_Control:
        case kVK_RightControl:
            return NSEventModifierFlagControl;
        case kVK_Function:
            return NSEventModifierFlagFunction;
            
        case kVK_PageDown:
        case kVK_PageUp:
        case kVK_Home:
        case kVK_End:
        case kVK_ForwardDelete:
            return NSEventModifierFlagFunction;
            
        case kVK_LeftArrow:
        case kVK_RightArrow:
        case kVK_DownArrow:
        case kVK_UpArrow:
            return NSEventModifierFlagNumericPad | NSEventModifierFlagFunction;
        default:
            return 0;
    }
}

- (CGKeyCode)keyCodeForModifierFlag:(NSEventModifierFlags)modifierFlag {
    switch(modifierFlag) {
        case NSEventModifierFlagCommand:
            return kVK_Command;
        case NSEventModifierFlagShift:
            return kVK_Shift;
        case NSEventModifierFlagCapsLock:
            return kVK_CapsLock;
        case NSEventModifierFlagOption:
            return kVK_Option;
        case NSEventModifierFlagControl:
            return kVK_Control;
        case NSEventModifierFlagFunction:
        default:
            return kVK_Function;
    }
}

- (void)simulateKeyEvent:(KeyEvent)keyEvent {
    if (keyEvent.type == KeyEventTypeFlagsChanged) {
        NSDictionary *mapping = [self modifierFlagMapping];
        for (NSNumber *keyboardFlag in mapping) {
            NSNumber *eventFlag = mapping[keyboardFlag];

            BOOL wasActive = (_modifierFlags & [eventFlag integerValue]) != 0;
            BOOL isActive = (keyEvent.modifiers & [keyboardFlag integerValue]) != 0;
            if (wasActive != isActive) {
                if ([eventFlag integerValue] == NSEventModifierFlagCapsLock) {
                    [self setCapsLockKey:isActive];
                } else {
                    KeyEvent modifierKeyEvent;
                    modifierKeyEvent.type = isActive ? KeyEventTypeKeyDown : KeyEventTypeKeyUp;
                    modifierKeyEvent.key = [self keyCodeForModifierFlag:[eventFlag integerValue]];
                    [self simulateKeyEvent:modifierKeyEvent];
                }
            }
        }
        
        return;
    }
    
    BOOL isDown;
    switch (keyEvent.type) {
        case KeyEventTypeKeyDown:
            isDown = YES;
            break;
        case KeyEventTypeKeyUp:
            isDown = NO;
            break;
        default:
            return;
    }
    
    CGEventRef eventRef = CGEventCreateKeyboardEvent(NULL, keyEvent.key, isDown ? true : false);
    CGEventFlags flags = CGEventGetFlags(eventRef);
    flags &= ~NSEventModifierFlagDeviceIndependentFlagsMask;
    NSEventModifierFlags modifiersForKey = [self modifierFlagsForKeyCode:keyEvent.key];
    flags |= isDown ? (_modifierFlags | modifiersForKey) : (_modifierFlags & ~modifiersForKey);
    CGEventSetFlags(eventRef, flags);
    CGEventPost(kCGHIDEventTap, eventRef);
    CFRelease(eventRef);
    
    // Skip modifiers for key repeat
    if (keyEvent.key >= kVK_RightCommand && keyEvent.key <= kVK_Function) return;
    
    // Interrupt previous key repeat
    if (isDown || _lastMacKeyCodeDown == keyEvent.key) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(keyRepeat) object:nil];
        }];
        _lastMacKeyCodeDown = -1;
    }
    
    // Start a new key repeat
    if (isDown) {
        _lastMacKeyCodeDown = keyEvent.key;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self performSelector:@selector(keyRepeat) withObject:nil afterDelay:[NSEvent keyRepeatDelay]];
        }];
    }
}

- (void)sendKeyboardLayoutToDevice:(NSNumber *)deviceId {
    NSDictionary *layoutInfo = @{
                                 @"type": @(_keyboardLayout.type),
                                 @"captions": [self keyCaptionsForCurrentInputSource],
                                 };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:layoutInfo];
    
    if (deviceId) {
        [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerKeyboardLayout data:data callback:^(NSError *error){}];
    } else {
        // Broadcase when no deviceId is given
        [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerKeyboardLayout data:data callback:^(NSDictionary *errors) {}];
    }
}

#pragma mark - UsbDeviceControllerDelegate

- (void)deviceDidConnect:(NSNumber *)deviceId {
    NSData* versionData = [NSData dataWithBytes:&kServerVersion length:sizeof(kServerVersion)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerVersion data:versionData callback:^(NSError *error){}];

    NSData* modeChangeData = [NSData dataWithBytes:&_remoteMode length:sizeof(_remoteMode)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerModeChange data:modeChangeData callback:^(NSError *error){}];

    NSData* alignChangeData = [NSData dataWithBytes:&_remoteAlign length:sizeof(_remoteAlign)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerAlignChange data:alignChangeData callback:^(NSError *error){}];

    [self sendKeyboardLayoutToDevice:deviceId];
    
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
    if (type < kProtocolFrameTypeClientMin || type > kProtocolFrameTypeClientMax) return;
    
    switch (type) {
        case ProtocolFrameTypeClientTouchBarMouseEvent: {
            MouseEvent *event = (MouseEvent *)data.bytes;
            NSPoint location = NSMakePoint(event->x, event->y);
            NSEventType eventType = NSEventTypeLeftMouseDown;
            switch (event->type) {
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
        case ProtocolFrameTypeClientKeyboardKeyEvent: {
            KeyEvent *event = (KeyEvent *)data.bytes;
            [self simulateKeyEvent:*event];
            break;
        }
        default:
            break;
    }
}

@end
