//
//  KeyboardView.m
//  TouchBarClient
//
//  Created by Robbert Klarenbeek on 18/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "KeyboardView.h"

#import "KeyboardLayoutANSI.h"
#import "KeyboardLayoutISO.h"
#import "KeyboardLayoutJIS.h"

@import AudioToolbox;

@interface Key : NSObject 
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CATextLayer *textLayer;
@property (nonatomic, assign) KeyCode keyCode;
@property (nonatomic, assign) KeyEventModifierFlags modifierFlag;
@property (nonatomic, assign) BOOL pressed; // Only used for non modifier keys
@end

@implementation Key
@end

@implementation KeyboardView {
    NSMutableDictionary *_predefinedKeyboardLayouts;
    UIView *_keysView;
    NSArray *_keys;
    NSMutableDictionary *_keyForTouch;
    KeyEventModifierFlags _modifierFlags;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self setup];
    }
    return self;
}

- (void)registerPredefinedKeyboardLayout:(KeyboardLayout *)layout {
    _predefinedKeyboardLayouts[@(layout.type)] = layout;
}

- (void)setup {
    _preserveAspectRatio = YES;
    _borderWidth = 0.2;
    _normalKeyColor = [UIColor blackColor];
    _normalCaptionColor = [UIColor colorWithWhite:0.933 alpha:1.0];
    _normalBorderColor = [UIColor colorWithWhite:0.467 alpha:1.0];
    _activeKeyColor = [UIColor colorWithWhite:0.165 alpha:1.0];
    _activeCaptionColor = [UIColor colorWithWhite:0.933 alpha:1.0];
    _activeBorderColor = [UIColor colorWithWhite:0.467 alpha:1.0];
    
    self.multipleTouchEnabled = YES;
    self.clipsToBounds = YES;
    
    _keysView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _keysView.layer.shouldRasterize = YES;
    [self addSubview:_keysView];
    
    _keys = @[];
    _keyForTouch = [NSMutableDictionary new];
    _modifierFlags = 0;

    _predefinedKeyboardLayouts = [NSMutableDictionary new];
    [self registerPredefinedKeyboardLayout:[KeyboardLayoutANSI new]];
    [self registerPredefinedKeyboardLayout:[KeyboardLayoutISO new]];
    [self registerPredefinedKeyboardLayout:[KeyboardLayoutJIS new]];
    
    self.layoutType = KeyboardLayoutTypeANSI;
}

- (NSString *)interfaceBuilderKeyCaptionForKeyCode:(KeyCode)keyCode {
    switch (keyCode) {
        case 0x0A: return @"§"; // kVK_ISO_Section
        case 0x32: return @"`"; // kVK_ANSI_Grave
        case 0x12: return @"1"; // kVK_ANSI_1
        case 0x13: return @"2"; // kVK_ANSI_2
        case 0x14: return @"3"; // kVK_ANSI_3
        case 0x15: return @"4"; // kVK_ANSI_4
        case 0x17: return @"5"; // kVK_ANSI_5
        case 0x16: return @"6"; // kVK_ANSI_6
        case 0x1A: return @"7"; // kVK_ANSI_7
        case 0x1C: return @"8"; // kVK_ANSI_8
        case 0x19: return @"9"; // kVK_ANSI_9
        case 0x1D: return @"0"; // kVK_ANSI_0
        case 0x1B: return @"-"; // kVK_ANSI_Minus
        case 0x5D: return @"¥"; // kVK_JIS_Yen
        case 0x5E: return @""; // kVK_JIS_Underscore
        case 0x18: return _layout.type == KeyboardLayoutTypeJIS ? @"^" : @"="; // kVK_ANSI_Equal
        case 0x2A: return _layout.type == KeyboardLayoutTypeJIS ? @"]" : @"\\"; // kVK_ANSI_Backslash
        case 0x1E: return _layout.type == KeyboardLayoutTypeJIS ? @"[" : @"]"; // kVK_ANSI_RightBracket
        case 0x21: return _layout.type == KeyboardLayoutTypeJIS ? @"@" : @"["; // kVK_ANSI_LeftBracket
        case 0x23: return @"P"; // kVK_ANSI_P
        case 0x1F: return @"O"; // kVK_ANSI_O
        case 0x22: return @"I"; // kVK_ANSI_I
        case 0x20: return @"U"; // kVK_ANSI_U
        case 0x10: return @"Y"; // kVK_ANSI_Y
        case 0x11: return @"T"; // kVK_ANSI_T
        case 0x0F: return @"R"; // kVK_ANSI_R
        case 0x0E: return @"E"; // kVK_ANSI_E
        case 0x0D: return @"W"; // kVK_ANSI_W
        case 0x0C: return @"Q"; // kVK_ANSI_Q
        case 0x00: return @"A"; // kVK_ANSI_A
        case 0x01: return @"S"; // kVK_ANSI_S
        case 0x02: return @"D"; // kVK_ANSI_D
        case 0x03: return @"F"; // kVK_ANSI_F
        case 0x05: return @"G"; // kVK_ANSI_G
        case 0x04: return @"H"; // kVK_ANSI_H
        case 0x26: return @"J"; // kVK_ANSI_J
        case 0x28: return @"K"; // kVK_ANSI_K
        case 0x25: return @"L"; // kVK_ANSI_L
        case 0x29: return @";"; // kVK_ANSI_Semicolon
        case 0x27: return _layout.type == KeyboardLayoutTypeJIS ? @":" : @"\""; // kVK_ANSI_Quote
        case 0x2C: return @"/"; // kVK_ANSI_Slash
        case 0x2F: return @"."; // kVK_ANSI_Period
        case 0x2B: return @","; // kVK_ANSI_Comma
        case 0x2E: return @"M"; // kVK_ANSI_M
        case 0x2D: return @"N"; // kVK_ANSI_N
        case 0x0B: return @"B"; // kVK_ANSI_B
        case 0x09: return @"V"; // kVK_ANSI_V
        case 0x08: return @"C"; // kVK_ANSI_C
        case 0x07: return @"X"; // kVK_ANSI_X
        case 0x06: return @"Z"; // kVK_ANSI_Z
        case 0x31: return @" "; // kVK_Space
        default: return nil;
    }
}

- (void)prepareForInterfaceBuilder {
    for (Key *key in _keys) {
        if (key.textLayer.string && ![key.textLayer.string isEqualToString:@""]) continue;
        key.textLayer.string = [self interfaceBuilderKeyCaptionForKeyCode:key.keyCode];
    }
}

- (CGFloat)aspectRatio {
    return _layout ? _layout.size.width / _layout.size.height : 1.0;
}

- (KeyboardLayoutType)layoutType {
    return _layout ? _layout.type : KeyboardLayoutTypeUnknown;
}

#if TARGET_INTERFACE_BUILDER
- (void)setLayoutType:(NSInteger)layoutType
#else
- (void)setLayoutType:(KeyboardLayoutType)layoutType
#endif
{
    self.layout = _predefinedKeyboardLayouts[@(layoutType)];
}

- (void)setLayout:(KeyboardLayout *)layout {
    if (_layout == layout) return;
    _layout = layout;
    
    for (Key *key in _keys) {
        [key.textLayer removeFromSuperlayer];
        [key.shapeLayer removeFromSuperlayer];
    }

    _keys = @[];
    
    if (_layout) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat longEdge = MAX(screenSize.width, screenSize.height);
        _keysView.layer.rasterizationScale = longEdge * [UIScreen mainScreen].scale / _layout.size.width;

        NSMutableArray *keys = [NSMutableArray new];
        for (NSUInteger keyIndex = 0; keyIndex < _layout.numberOfKeys; keyIndex++) {
            UIBezierPath *path = [_layout bezierPathForKeyIndex:keyIndex];
            if (!path) continue;
            CGPoint textPosition = [_layout textPositionForKeyIndex:keyIndex];
            CGFloat fontSize = [_layout fontSizeForKeyIndex:keyIndex];

            Key *key = [Key new];
            [keys addObject:key];
            
            key.shapeLayer = [CAShapeLayer layer];
            key.shapeLayer.path = path.CGPath;
            [_keysView.layer addSublayer:key.shapeLayer];
            
            UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightLight];
            
            key.textLayer = [CATextLayer layer];
            key.textLayer.frame = CGRectMake(textPosition.x - font.lineHeight, textPosition.y - font.lineHeight - font.descender + font.xHeight, 2 * font.lineHeight, font.lineHeight);
            key.textLayer.font = (__bridge CFTypeRef)font;
            key.textLayer.fontSize = fontSize;
            key.textLayer.alignmentMode = kCAAlignmentCenter;
            key.textLayer.contentsScale = _keysView.layer.rasterizationScale;
            [_keysView.layer addSublayer:key.textLayer];
            
            key.keyCode = [_layout keyCodeForKeyIndex:keyIndex];
            key.modifierFlag = [_layout modifierFlagForKeyIndex:keyIndex];
            
            [self updateKeyPropertiesForKey:key animated:NO];
        }
        _keys = keys;

        [self updateKeyCaptions];
    }
}

- (void)setKeyCaptions:(NSDictionary *)keyCaptions {
    if (_keyCaptions != keyCaptions) {
        _keyCaptions = keyCaptions;
        [self updateKeyCaptions];
    }
}

- (void)setPreserveAspectRatio:(BOOL)preserveAspectRatio {
    if (_preserveAspectRatio != preserveAspectRatio) {
        _preserveAspectRatio = preserveAspectRatio;
        [self setNeedsLayout];
    }
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    if (_borderWidth != borderWidth) {
        _borderWidth = borderWidth;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setNormalKeyColor:(UIColor *)normalKeyColor {
    if (_normalKeyColor != normalKeyColor) {
        _normalKeyColor = normalKeyColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setNormalCaptionColor:(UIColor *)normalCaptionColor {
    if (_normalCaptionColor != normalCaptionColor) {
        _normalCaptionColor = normalCaptionColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setNormalBorderColor:(UIColor *)normalBorderColor {
    if (_normalBorderColor != normalBorderColor) {
        _normalBorderColor = normalBorderColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setActiveKeyColor:(UIColor *)activeKeyColor {
    if (_activeKeyColor != activeKeyColor) {
        _activeKeyColor = activeKeyColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setActiveCaptionColor:(UIColor *)activeCaptionColor {
    if (_activeCaptionColor != activeCaptionColor) {
        _activeCaptionColor = activeCaptionColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)setActiveBorderColor:(UIColor *)activeBorderColor {
    if (_activeBorderColor != activeBorderColor) {
        _activeBorderColor = activeBorderColor;
        [self updateKeyPropertiesAnimated:YES];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_layout) {
        if (_preserveAspectRatio) {
            CGFloat scale = self.bounds.size.width / _layout.size.width;
            _keysView.transform = CGAffineTransformMakeScale(scale, scale);
        } else {
            CGFloat scaleX = self.bounds.size.width / _layout.size.width;
            CGFloat scaleY = self.bounds.size.height / _layout.size.height;
            _keysView.transform = CGAffineTransformMakeScale(scaleX, scaleY);
        }
    } else {
        _keysView.transform = CGAffineTransformIdentity;
    }
}

- (BOOL)isKeyActive:(Key *)key {
    return key.pressed || (_modifierFlags & key.modifierFlag);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGAffineTransform transform = CGAffineTransformInvert(_keysView.transform);

    Key *clickSoundKey = nil;

    for (UITouch *touch in touches) {
        NSValue *touchValue = [NSValue valueWithNonretainedObject:touch];
        CGPoint touchPoint = [touch locationInView:self];
        for (Key *key in _keys) {
            if (key.keyCode == 0xFF) continue;
            if (CGPathContainsPoint(key.shapeLayer.path, &transform, touchPoint, false)) {
                clickSoundKey = key;
                [_keyForTouch setObject:key forKey:touchValue];
                [self internalKeyPress:key isDown:YES];
                break;
            }
        }
    }
    
    if (clickSoundKey) {
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 0, .patchVersion = 0}]) {
            if (clickSoundKey.modifierFlag) {
                AudioServicesPlaySystemSound(1156);
            } else {
                switch (clickSoundKey.keyCode) {
                    case 0x33: // kVK_Delete
                        AudioServicesPlaySystemSound(1155);
                        break;
                    case 0x24: // kVK_Return
                    case 0x30: // kVK_Tab
                    case 0x35: // kVK_Escape
                    case 0x47: // kVK_ANSI_KeypadClear
                    case 0x4C: // kVK_ANSI_KeypadEnter
                    case 0x66: // kVK_JIS_Eisu
                    case 0x68: // kVK_JIS_Kana
                    case 0x72: // kVK_Help
                    case 0x73: // kVK_Home
                    case 0x74: // kVK_PageUp
                    case 0x77: // kVK_End
                    case 0x79: // kVK_PageDown
                    case 0x7B: // kVK_LeftArrow
                    case 0x7C: // kVK_RightArrow
                    case 0x7D: // kVK_DownArrow
                    case 0x7E: // kVK_UpArrow
                        AudioServicesPlaySystemSound(1156);
                        break;
                    default:
                        AudioServicesPlaySystemSound(1123);
                }
            }
        } else {
            AudioServicesPlaySystemSound(1104);
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        NSValue *touchValue = [NSValue valueWithNonretainedObject:touch];
        Key *key = _keyForTouch[touchValue];
        if (key) {
            [_keyForTouch removeObjectForKey:touchValue];
            [self internalKeyPress:key isDown:NO];
        }
    }
}

- (void)internalKeyPress:(Key *)key isDown:(BOOL)isDown {
    KeyEvent keyEvent;
    keyEvent.type = isDown ? KeyEventTypeKeyDown : KeyEventTypeKeyUp;
    keyEvent.key = key.keyCode;
    keyEvent.modifiers = _modifierFlags;
    
    if (key.modifierFlag > 0) {
        KeyEventModifierFlags newModifierFlags = _modifierFlags;
        if (key.modifierFlag == KeyEventModifierFlagCapsLock) {
            if (isDown) newModifierFlags ^= key.modifierFlag;
        } else {
            if (isDown) {
                newModifierFlags |= key.modifierFlag;
            } else {
                newModifierFlags &= (~key.modifierFlag);
            }
        }
        if (newModifierFlags == _modifierFlags) return;
        
        keyEvent.type = KeyEventTypeFlagsChanged;
        keyEvent.modifiers = newModifierFlags;
        
        [self updateModifierFlags:newModifierFlags];
    } else {
        key.pressed = isDown;
        [self updateKeyPropertiesForKey:key animated:!key.pressed];
    }

    if ([_delegate respondsToSelector:@selector(keyboardView:keyEvent:)]) {
        [_delegate keyboardView:self keyEvent:keyEvent];
    }
}

- (void)externalKeyEvent:(KeyEvent)keyEvent {
    switch (keyEvent.type) {
        case KeyEventTypeKeyDown:
        case KeyEventTypeKeyUp: {
            for (Key *key in _keys) {
                if (key.keyCode == keyEvent.key) {
                    BOOL wasActive = [self isKeyActive:key];
                    key.pressed = (keyEvent.type == KeyEventTypeKeyDown);
                    BOOL isActive = [self isKeyActive:key];
                    if (wasActive != isActive) {
                        [self updateKeyPropertiesForKey:key animated:wasActive];
                    }
                }
            }
            break;
        }
        case KeyEventTypeFlagsChanged: {
            [self updateModifierFlags:keyEvent.modifiers];
            break;
        }
    }
}
    
- (void)updateKeyPropertiesForKey:(Key *)key animated:(BOOL)animated {
    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    key.shapeLayer.lineWidth = _borderWidth;
    if ([self isKeyActive:key]) {
        key.shapeLayer.fillColor = _activeKeyColor.CGColor;
        key.shapeLayer.strokeColor = _activeBorderColor.CGColor;
        key.textLayer.foregroundColor = _activeCaptionColor.CGColor;
    } else {
        key.shapeLayer.fillColor = _normalKeyColor.CGColor;
        key.shapeLayer.strokeColor = _normalBorderColor.CGColor;
        key.textLayer.foregroundColor = _normalCaptionColor.CGColor;
    }
    
    if (!animated) {
        [CATransaction commit];
    }
}

- (void)updateKeyPropertiesAnimated:(BOOL)animated {
    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    for (Key *key in _keys) {
        // Sending animated==YES so no CATransaction is started, we already did that here
        [self updateKeyPropertiesForKey:key animated:YES];
    }
    
    if (!animated) {
        [CATransaction commit];
    }
}

- (void)updateKeyCaptions {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (Key *key in _keys) {
        NSString *caption = [KeyboardLayout fixedKeyCaptionForKeyCode:key.keyCode withFnDown:(_modifierFlags & KeyEventModifierFlagFunction)];
        if (caption == nil) caption = _keyCaptions[@(key.keyCode)][_modifierFlags & ~KeyEventModifierFlagFunction];
        if ([key.textLayer.string isEqualToString:caption]) continue;
        key.textLayer.string = caption;
    }
    [CATransaction commit];
}

- (void)updateModifierFlags:(KeyEventModifierFlags)newModifierFlags {
    if (_modifierFlags == newModifierFlags) return;

    NSMutableDictionary *modifierKeysCurrentMode = [NSMutableDictionary new];
    for (Key *key in _keys) {
        if (key.modifierFlag == 0) continue;
        modifierKeysCurrentMode[[NSValue valueWithNonretainedObject:key]] = @([self isKeyActive:key]);
    }
    _modifierFlags = newModifierFlags;
    [self updateKeyCaptions];
    for (NSValue *keyValue in modifierKeysCurrentMode) {
        Key *key = [keyValue nonretainedObjectValue];
        BOOL wasActive = [modifierKeysCurrentMode[keyValue] boolValue];
        BOOL isActive = [self isKeyActive:key];
        if (wasActive != isActive) {
            [self updateKeyPropertiesForKey:key animated:wasActive];
        }
    }
}

@end
