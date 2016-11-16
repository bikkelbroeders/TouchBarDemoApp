//
//  AppDelegate.m
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "AppDelegate.h"

#import "KeyboardKey.h"
#import "Keyboard.h"
#import "Protocol.h"
#import "TouchBarWindow.h"
#import "UsbDeviceController.h"

@import Carbon;

typedef int CGSConnectionID;
CG_EXTERN void CGSGetKeys(KeyMap keymap);
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN void CGSGetBackgroundEventMask(CGSConnectionID cid, CGEventFlags *outMask);
CG_EXTERN CGError CGSSetBackgroundEventMask(CGSConnectionID cid, CGEventFlags mask);

extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler);
extern BOOL DFRSetStatus(int);
extern BOOL DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p);

static NSString * const kUserDefaultsKeyScreenEnable    = @"ScreenEnable";
static NSString * const kUserDefaultsKeyScreenToggleKey = @"ScreenToggleKey";
static NSString * const kUserDefaultsKeyRemoteEnable    = @"RemoteEnable";
static NSString * const kUserDefaultsKeyRemoteMode      = @"RemoteMode";
static NSString * const kUserDefaultsKeyRemoteAlign     = @"RemoteAlign";

typedef NS_ENUM(NSInteger, ToggleKey) {
    ToggleKeyFn         = 0,
    ToggleKeyShift      = 1,
    ToggleKeyCommand    = 2,
    ToggleKeyControl    = 3,
    ToggleKeyOption     = 4,
};

@interface AppDelegate () <UsbDeviceControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *screenSubMenuItem;
@property (weak) IBOutlet NSMenuItem *remoteSubMenuItem;

// Settings
@property (nonatomic, assign) BOOL screenEnable;
@property (nonatomic, assign) ToggleKey screenToggleKey;
@property (nonatomic, assign) BOOL remoteEnable;
@property (nonatomic, assign) OperatingMode remoteMode;
@property (nonatomic, assign) Alignment remoteAlign;

@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    TouchBarWindow* _touchBarWindow;
    
    CGDisplayStreamRef _stream;
    UsbDeviceController *_usbDeviceController;
    
    NSEventModifierFlags _modifierFlags;
    BOOL _couldBeSoleToggleKeyPress;
    
    NSInteger _lastMacKeyCodeDown;
    NSMutableSet *_keysDown;
    NSTimer *_keyTimer;
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
    
    _keysDown = [NSMutableSet new];

    CGSConnectionID connectionId = CGSMainConnectionID();
    CGEventFlags backgroundEventMask;
    CGSGetBackgroundEventMask(connectionId, &backgroundEventMask);
    CGSSetBackgroundEventMask(connectionId, backgroundEventMask | NSKeyDownMask | NSKeyUpMask | NSFlagsChangedMask);
    
    _usbDeviceController = [[UsbDeviceController alloc] initWithPort:kProtocolPort];
    _usbDeviceController.delegate = self;
    
    _touchBarWindow = [TouchBarWindow new];
    [_touchBarWindow setIsVisible:NO];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              kUserDefaultsKeyScreenEnable: @YES,
                                                              kUserDefaultsKeyScreenToggleKey: @(ToggleKeyFn),
                                                              kUserDefaultsKeyRemoteEnable: @YES,
                                                              kUserDefaultsKeyRemoteMode: @(OperatingModeDemo1),
                                                              kUserDefaultsKeyRemoteAlign: @(AlignmentBottom),
                                                              }];

    _screenEnable = NO;
    self.screenEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyScreenEnable];
    
    _screenToggleKey = -1;
    self.screenToggleKey = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyScreenToggleKey];
    
    _remoteEnable = NO;
    self.remoteEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsKeyRemoteEnable];
    
    _remoteMode = -1;
    self.remoteMode = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyRemoteMode];

    _remoteAlign = -1;
    self.remoteAlign = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsKeyRemoteAlign];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.menu = self.menu;
    _statusItem.highlightMode = YES;
    _statusItem.image = [NSImage imageNamed:@"NSSlideshowTemplate"];
    [self stopStreaming];
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
    }
}

- (void)setScreenToggleKey:(ToggleKey)screenToggleKey {
    if (_screenToggleKey != screenToggleKey) {
        _screenToggleKey = screenToggleKey;
        [[NSUserDefaults standardUserDefaults] setObject:@(_screenToggleKey) forKey:kUserDefaultsKeyScreenToggleKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        for (NSMenuItem *menuItem in _screenSubMenuItem.submenu.itemArray) {
            if (menuItem.action != @selector(changeScreenToggleKey:)) continue;
            menuItem.state = menuItem.tag == _screenToggleKey ? 1 : 0;
        }
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
    self.screenToggleKey = (ToggleKey)sender.tag;
}

- (IBAction)changeRemoteEnable:(NSMenuItem *)sender {
    self.remoteEnable = (sender.state == 0);
}

- (IBAction)changeRemoteMode:(NSMenuItem *)sender {
    self.remoteMode = (OperatingMode)sender.tag;
}

- (IBAction)changeRemoteAlign:(NSMenuItem *)sender {
    self.remoteAlign = (Alignment)sender.tag;
}

- (NSArray<KeyboardKey*>*)createKeyboardKeys {
    NSDictionary* usbToMac = @{@(10): @(5),
                               @(100): @(10),
                               @(103): @(81),
                               @(104): @(105),
                               @(105): @(107),
                               @(106): @(113),
                               @(107): @(106),
                               @(108): @(64),
                               @(109): @(79),
                               @(11): @(4),
                               @(110): @(80),
                               @(111): @(90),
                               @(117): @(114),
                               @(12): @(34),
                               @(127): @(74),
                               @(128): @(72),
                               @(129): @(73),
                               @(13): @(38),
                               @(133): @(95),
                               @(135): @(94),
                               @(137): @(93),
                               @(14): @(40),
                               @(144): @(102),
                               @(148): @(104),
                               @(15): @(37),
                               @(16): @(46),
                               @(17): @(45),
                               @(18): @(31),
                               @(19): @(35),
                               @(20): @(12),
                               @(21): @(15),
                               @(216): @(71),
                               @(22): @(1),
                               @(224): @(59),
                               @(225): @(56),
                               @(226): @(58),
                               @(227): @(55),
                               @(228): @(62),
                               @(229): @(60),
                               @(23): @(17),
                               @(230): @(61),
                               @(232): @(63),
                               @(24): @(32),
                               @(25): @(9),
                               @(26): @(13),
                               @(27): @(7),
                               @(28): @(16),
                               @(29): @(6),
                               @(30): @(18),
                               @(31): @(19),
                               @(32): @(20),
                               @(33): @(21),
                               @(34): @(23),
                               @(35): @(22),
                               @(36): @(26),
                               @(37): @(28),
                               @(38): @(25),
                               @(39): @(29),
                               @(4): @(0),
                               @(40): @(36),
                               @(41): @(53),
                               @(42): @(51),
                               @(43): @(48),
                               @(44): @(49),
                               @(45): @(27),
                               @(46): @(24),
                               @(47): @(33),
                               @(48): @(30),
                               @(49): @(42),
                               @(5): @(11),
                               @(51): @(41),
                               @(52): @(39),
                               @(53): @(50),
                               @(54): @(43),
                               @(55): @(47),
                               @(56): @(44),
                               @(57): @(57),
                               @(58): @(122),
                               @(59): @(120),
                               @(6): @(8),
                               @(60): @(99),
                               @(61): @(118),
                               @(62): @(96),
                               @(63): @(97),
                               @(64): @(98),
                               @(65): @(100),
                               @(66): @(101),
                               @(67): @(109),
                               @(68): @(103),
                               @(69): @(111),
                               @(7): @(2),
                               @(74): @(115),
                               @(75): @(116),
                               @(76): @(117),
                               @(77): @(119),
                               @(78): @(121),
                               @(79): @(124),
                               @(8): @(14),
                               @(80): @(123),
                               @(81): @(125),
                               @(82): @(126),
                               @(84): @(75),
                               @(85): @(67),
                               @(86): @(78),
                               @(87): @(69),
                               @(88): @(76),
                               @(89): @(83),
                               @(9): @(3),
                               @(90): @(84),
                               @(91): @(85),
                               @(92): @(86),
                               @(93): @(87),
                               @(94): @(88),
                               @(95): @(89),
                               @(96): @(91),
                               @(97): @(92),
                               @(98): @(82),
                               @(99): @(65),
                               };
    
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);

    if (!layoutData) {
        CFRelease(currentKeyboard);
        currentKeyboard = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
        layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    }

    const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    
    UInt8 keyboardType = LMGetKbdType();
    UInt32 ucModifiers[32] = {0};
    for(KeyboardKeyModifier modifier = 0; modifier < KeyboardKeyModifierLast; modifier++) {
        UInt32 ucModifier = 0;
        if(modifier & KeyboardKeyModifierCommand) ucModifier |= (cmdKey >> 8);
        if(modifier & KeyboardKeyModifierShift) ucModifier |= (shiftKey >> 8);
        if(modifier & KeyboardKeyModifierControl) ucModifier |= (controlKey >> 8);
        if(modifier & KeyboardKeyModifierOption) ucModifier |= (optionKey >> 8);
        if(modifier & KeyboardKeyModifierAlphaLock) ucModifier |= (alphaLock >> 8);
        ucModifiers[modifier] = ucModifier;
    }
    NSMutableArray<KeyboardKey *>* keys  = [NSMutableArray new];
    for(NSNumber* usbKeyCode in usbToMac.allKeys) {
        CGKeyCode macKeyCode = [usbToMac[usbKeyCode] integerValue];
        
        KeyboardKey* key = [KeyboardKey new];
        [keys addObject:key];
        
        key.keyCode = usbKeyCode.integerValue;
        key.macKeyCode = macKeyCode;
        
        NSMutableDictionary<NSNumber*, KeyboardKeyCap*>* caps = [NSMutableDictionary new];
        for(KeyboardKeyModifier modifiers = 0; modifiers < KeyboardKeyModifierLast; modifiers++) {
            KeyboardKeyCap* keyCap = [KeyboardKeyCap new];
            
            if(macKeyCode >= 0x38 && macKeyCode <= 0x3F)
                keyCap.type = keyCap.type | KeyboardKeyTypeModifier;
            
            NSString* string = [self fixedKeyCapForMacCode:macKeyCode modifiers:modifiers];
            if(nil == string)
            {
                UInt32 keysDown = 0;
                UniChar chars[4] = {0};
                UniCharCount realLength = 0;
                
                KeyboardKeyModifier fixedModifiers = (modifiers & ~KeyboardKeyModifierFn);
                UInt32 ucModifier = ucModifiers[fixedModifiers];
                UCKeyTranslate(keyboardLayout, macKeyCode, kUCKeyActionDisplay, ucModifier, keyboardType, 0, &keysDown, sizeof(chars) / sizeof(chars[0]), &realLength, chars);
                string = [[NSString alloc] initWithCharacters:chars length:1];
                
                if((modifiers & KeyboardKeyModifierControl) != 0 && [string characterAtIndex:0] < 0x20) {
                    keyCap.type = keyCap.type | KeyboardKeyTypeControl;
                    UCKeyTranslate(keyboardLayout, macKeyCode, kUCKeyActionDisplay, ucModifier & (~(controlKey >> 8)), keyboardType, 0, &keysDown, sizeof(chars) / sizeof(chars[0]), &realLength, chars);
                    string = [NSString stringWithCharacters:chars length:realLength];
                }
            }
            keyCap.text = string;
            
            caps[@(modifiers)] = keyCap;
        }
        key.caps = caps;
    }
    
    CFRelease(currentKeyboard);
    
    return keys;
}

- (NSString*)fixedKeyCapForMacCode:(CGKeyCode)code modifiers:(KeyboardKeyModifier)modifiers {
    if(modifiers == KeyboardKeyModifierFn) {
        CGKeyCode fixedCode = code;
        if(code <= 0x7a) {
            fixedCode = 0x34;
            if(code != 0x24) {
                if(code == 0x33) {
                    fixedCode = 0x75;
                } else {
                    fixedCode = code;
                }
            }
        } else {
            fixedCode = code -123;
            if(fixedCode > 3) {
                fixedCode = code;
            } else {
                switch(fixedCode) {
                    case 0: fixedCode = 0x73; break;
                    case 1: fixedCode = 0x77; break;
                    case 2: fixedCode = 0x79; break;
                    case 3: fixedCode = 0x74; break;
                    default: break;
                }
            }
        }
        
        code = fixedCode;
    }
    
    static NSDictionary* mapping = nil;
    if(mapping == nil)
    {
        mapping = @{    @(111): @"\uf861F12",
                        @(71): @"\u2327",
                        @(102): @"\u82f1\u6570",
                        @(53): @"esc",
                        @(124): @"\u21e2",
                        @(115): @"\u2196",
                        @(106): @"\uf861F16",
                        @(97): @"\uf860F6",
                        @(57): @"\u21ea",
                        @(48): @"\u21e5",
                        @(119): @"\u2198",
                        @(79): @"\uf861F18",
                        @(101): @"\uf860F9",
                        @(61): @"\u2325",
                        @(52): @"\u2324",
                        @(123): @"\u21e0",
                        @(114): @"?\u20dd",
                        @(105): @"\uf861F13",
                        @(96): @"\uf860F5",
                        @(56): @"\u21e7",
                        @(118): @"\uf860F4",
                        @(109): @"\uf861F10",
                        @(100): @"\uf860F8",
                        @(60): @"\u21e7",
                        @(51): @"\u232b",
                        @(122): @"\uf860F1",
                        @(113): @"\uf861F15",
                        @(104): @"\u304b\u306a",
                        @(64): @"\uf861F17",
                        @(55): @"\u2318",
                        @(126): @"\u21e1",
                        @(117): @"\u2326",
                        @(99): @"\uf860F3",
                        @(59): @"\u2303",
                        @(90): @"F20",
                        @(121): @"\u21df",
                        @(103): @"\uf861F11",
                        @(63): @"fn",
                        @(125): @"\u21e3",
                        @(116): @"\u21de",
                        @(76): @"\u2324",
                        @(36): @"\u21a9",
                        @(107): @"\uf861F14",
                        @(98): @"\uf860F7",
                        @(58): @"\u2325",
                        @(120): @"\uf860F2",
                        @(80): @"\uf861F19",
                        };
    }
    
    return mapping[@(code)];
}

- (NSString *)keyboardHTML {
    UInt8 keyboardType = LMGetKbdType();
    switch (KBGetLayoutType(keyboardType)) {
        case kKeyboardISO:
            keyboardType = 59;
            break;
            
        case kKeyboardJIS:
            keyboardType = 60;
            break;
            
        case kKeyboardANSI:
        default:
            keyboardType = 58;
            break;
    }
    
    NSString* folder = @"/System/Library/Input Methods/KeyboardViewer.app/Contents/Resources";
    NSString* file = [NSString stringWithFormat:@"KeyboardLayoutDefinition%@.svg", @(keyboardType)];
    NSString* path = [folder stringByAppendingPathComponent:file];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    NSString* svg = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    svg = [svg stringByReplacingOccurrencesOfString:@"<?xml version=\"1.0\" standalone=\"no\"?>" withString:@""];
    svg = [svg stringByReplacingOccurrencesOfString:@"onmousedown" withString:@"ontouchstart"];
    svg = [svg stringByReplacingOccurrencesOfString:@"onmouseup" withString:@"ontouchend"];
    
    NSMutableDictionary* allKeys = [NSMutableDictionary new];
    for(KeyboardKey* key in [self createKeyboardKeys]) {
        NSMutableDictionary* keyDict = [NSMutableDictionary new];
        keyDict[@"k"] = @(key.macKeyCode);
        
        NSMutableDictionary* defaultCapDict = [NSMutableDictionary new];
        defaultCapDict[@"x"] = key.caps[@0].text;
        if (key.caps[@0].type != 0) defaultCapDict[@"t"] = @(key.caps[@0].type);
        keyDict[@"d"] = defaultCapDict;
        
        NSMutableDictionary *capsDict = [NSMutableDictionary new];
        for(NSNumber* modifiers in [key.caps.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
            KeyboardKeyCap* cap = key.caps[modifiers];
            NSMutableDictionary* capDict = [NSMutableDictionary new];
            capDict[@"x"] = cap.text;
            if (cap.type != 0)
                capDict[@"t"] = @(cap.type);
            
            if (![capDict isEqual:defaultCapDict])
                capsDict[[modifiers stringValue]] = capDict;
        }
        keyDict[@"c"] = capsDict;
        allKeys[[@(key.keyCode) description]] = keyDict;
    }
    
    NSData* json = [NSJSONSerialization dataWithJSONObject:allKeys options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\"([a-z0-9]+)\":" withString:@"$1:" options:NSRegularExpressionSearch range:NSMakeRange(0, jsonString.length)];
    
    NSString *html = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Keyboard" withExtension:@"html"] encoding:NSUTF8StringEncoding error:nil];
    
    html = [html stringByReplacingOccurrencesOfString:@"{/*KEYDATA*/}" withString:jsonString];
    html = [html stringByReplacingOccurrencesOfString:@"%SVGELEMENT%" withString:svg];

    // Poor man's minify
    // DISCLAIMER: _will_ break HTML/JS/CSS other than the one we're using, DO NOT REUSE!
    html = [html stringByReplacingOccurrencesOfString:@"//.*\n" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    html = [html stringByReplacingOccurrencesOfString:@"/\\*.*\\*/" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    html = [html stringByReplacingOccurrencesOfString:@"\\s" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    html = [html stringByReplacingOccurrencesOfString:@"  +" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    html = [html stringByReplacingOccurrencesOfString:@" ?([-:(){}<>,;+*/=]) ?" withString:@"$1" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    
    return html;
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
        [_touchBarWindow setFrameOrigin:self.mouseTouchOrigin];
        
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

- (BOOL)isKeyPressed:(CGKeyCode)key inKeyMap:(KeyMap *)keymap {
    unsigned char element = key / 32;
    UInt32 mask = 1 << (key % 32);
    return ((*keymap)[element].bigEndianValue & mask) != 0;
}

- (BOOL)isOnlyKeyPressed:(CGKeyCode)key inKeyMap:(KeyMap *)keymap {
    unsigned char element = key / 32;
    UInt32 mask = 1 << (key % 32);
    for (unsigned char i = 0; i < 4; i++) {
        if (i == element) {
            if ((*keymap)[i].bigEndianValue != mask) return NO;
        } else {
            if ((*keymap)[i].bigEndianValue != 0) return NO;
        }
    }
    
    return YES;
}

- (BOOL)isAnyKeyPressedInKeyMap:(KeyMap *)keymap {
    return !(
             (*keymap)[0].bigEndianValue == 0 &&
             (*keymap)[1].bigEndianValue == 0 &&
             (*keymap)[2].bigEndianValue == 0 &&
             (*keymap)[3].bigEndianValue == 0
             );
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

- (CGKeyCode)toggleKeyKeyCode {
    switch (_screenToggleKey) {
        case ToggleKeyFn:
            return kVK_Function;
        case ToggleKeyShift:
            return kVK_Shift;
        case ToggleKeyCommand:
            return kVK_Command;
        case ToggleKeyControl:
            return kVK_Control;
        case ToggleKeyOption:
            return kVK_Option;
    }
}

- (NSEventModifierFlags)toggleKeyModifierFlag {
    switch (_screenToggleKey) {
        case ToggleKeyFn:
            return NSEventModifierFlagFunction;
        case ToggleKeyShift:
            return NSEventModifierFlagShift;
        case ToggleKeyCommand:
            return NSEventModifierFlagCommand;
        case ToggleKeyControl:
            return NSEventModifierFlagControl;
        case ToggleKeyOption:
            return NSEventModifierFlagOption;
    }
}

- (void)keyEvent:(NSEvent *)event {
    KeyEvent keyEvent = [self keyEventFromEvent:event];
    NSData* data = [NSData dataWithBytes:&keyEvent length:sizeof(keyEvent)];
    [_usbDeviceController broadcastMessageOfType:ProtocolFrameTypeServerSystemKeyEvent data:data callback:^(NSDictionary *errors) {}];
    
    switch (event.type) {
        case NSEventTypeKeyDown: {
            BOOL firstKeyDown = (_keysDown.count == 0);
            [_keysDown addObject:@(event.keyCode)];
            if (firstKeyDown && !_keyTimer && [NSTimer respondsToSelector:@selector(scheduledTimerWithTimeInterval:repeats:block:)]) {
                _keyTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer){
                    KeyMap keymap;
                    CGSGetKeys(keymap);
                    for (NSNumber *keyDown in [_keysDown copy]) {
                        CGKeyCode key = [keyDown integerValue];
                        if (![self isKeyPressed:key inKeyMap:&keymap]) {
                            NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:_modifierFlags timestamp:0 windowNumber:0 context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:key];
                            [self keyEvent:event];
                        }
                    }
                }];
            }
            break;
        }
        case NSEventTypeKeyUp: {
            [_keysDown removeObject:@(event.keyCode)];
            if (_keysDown.count == 0 && _keyTimer) {
                [_keyTimer invalidate];
                _keyTimer = nil;
            }
            break;
        }
        default:
            break;
    }
    
    if (_screenEnable) {
        switch(event.type) {
            case NSEventTypeKeyDown:
                _couldBeSoleToggleKeyPress = NO;
                break;
                
            case NSEventTypeKeyUp:
                _couldBeSoleToggleKeyPress = NO;
                break;
                
            case NSEventTypeFlagsChanged: {
                BOOL toggleKeyWasDown = (_modifierFlags & [self toggleKeyModifierFlag]) != 0;
                BOOL toggleKeyIsDown = (event.modifierFlags & [self toggleKeyModifierFlag]) != 0;
                
                if(toggleKeyIsDown != toggleKeyWasDown) {
                    KeyMap keymap;
                    CGSGetKeys(keymap);
                    if (toggleKeyIsDown) {
                        _couldBeSoleToggleKeyPress = [self isOnlyKeyPressed:[self toggleKeyKeyCode] inKeyMap:&keymap];
                    } else if (_couldBeSoleToggleKeyPress && [self isAnyKeyPressedInKeyMap:&keymap] == NO) {
                        [self toggleTouchBarWindow];
                    }
                } else {
                    _couldBeSoleToggleKeyPress = NO;
                }
            }
                
            default:
                break;
        }
    }
    
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
    flags |= isDown ? (_modifierFlags | modifiersForKey) : _modifierFlags & ~modifiersForKey;
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

#pragma mark - UsbDeviceControllerDelegate

- (void)deviceDidConnect:(NSNumber *)deviceId {
    NSData* versionData = [NSData dataWithBytes:&kServerVersion length:sizeof(kServerVersion)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerVersion data:versionData callback:^(NSError *error){}];

    NSData* modeChangeData = [NSData dataWithBytes:&_remoteMode length:sizeof(_remoteMode)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerModeChange data:modeChangeData callback:^(NSError *error){}];

    NSData* alignChangeData = [NSData dataWithBytes:&_remoteAlign length:sizeof(_remoteAlign)];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerAlignChange data:alignChangeData callback:^(NSError *error){}];

    NSData *keyboardLayoutData = [[self keyboardHTML] dataUsingEncoding:NSUTF8StringEncoding];
    [_usbDeviceController sendMessageToDevice:deviceId type:ProtocolFrameTypeServerKeyboardLayout data:keyboardLayoutData callback:^(NSError *error){}];
    
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
