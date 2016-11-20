#!/usr/bin/env php
<?php

$project = 'TouchBar';
$copyright = '2016 Bikkelbroeders';
$script = basename(__FILE__);

$dir = __DIR__ . "/../Shared/Generated";
$layouts = [
    'ANSI' => 58,
    'ISO' => 59,
    'JIS' => 60,
];

define('TOUCH_BAR_KEY_HEIGHT', 10);
define('TOUCH_BAR_KEY_MARGIN', 3);
define('EXTRA_TOP_SPACE', TOUCH_BAR_KEY_HEIGHT + TOUCH_BAR_KEY_MARGIN);
define('FONT_SIZE_OFFSET', -2);
define('KEY_WIDTH_INCREASE', 1);
define('KEY_HEIGHT_INCREASE', 2);
define('MARGIN_INCREASE', -0.5);
define('HORIZONTAL_MARGIN_INCREASE', MARGIN_INCREASE + KEY_WIDTH_INCREASE / 2);
define('VERTICAL_MARGIN_INCREASE', MARGIN_INCREASE + KEY_HEIGHT_INCREASE / 2);

$hidToMac = [
    0x04 => [0x00, 'kVK_ANSI_A'],
    0x05 => [0x0B, 'kVK_ANSI_B'],
    0x06 => [0x08, 'kVK_ANSI_C'],
    0x07 => [0x02, 'kVK_ANSI_D'],
    0x08 => [0x0E, 'kVK_ANSI_E'],
    0x09 => [0x03, 'kVK_ANSI_F'],
    0x0A => [0x05, 'kVK_ANSI_G'],
    0x0B => [0x04, 'kVK_ANSI_H'],
    0x0C => [0x22, 'kVK_ANSI_I'],
    0x0D => [0x26, 'kVK_ANSI_J'],
    0x0E => [0x28, 'kVK_ANSI_K'],
    0x0F => [0x25, 'kVK_ANSI_L'],
    0x10 => [0x2E, 'kVK_ANSI_M'],
    0x11 => [0x2D, 'kVK_ANSI_N'],
    0x12 => [0x1F, 'kVK_ANSI_O'],
    0x13 => [0x23, 'kVK_ANSI_P'],
    0x14 => [0x0C, 'kVK_ANSI_Q'],
    0x15 => [0x0F, 'kVK_ANSI_R'],
    0x16 => [0x01, 'kVK_ANSI_S'],
    0x17 => [0x11, 'kVK_ANSI_T'],
    0x18 => [0x20, 'kVK_ANSI_U'],
    0x19 => [0x09, 'kVK_ANSI_V'],
    0x1A => [0x0D, 'kVK_ANSI_W'],
    0x1B => [0x07, 'kVK_ANSI_X'],
    0x1C => [0x10, 'kVK_ANSI_Y'],
    0x1D => [0x06, 'kVK_ANSI_Z'],
    0x1E => [0x12, 'kVK_ANSI_1'],
    0x1F => [0x13, 'kVK_ANSI_2'],
    0x20 => [0x14, 'kVK_ANSI_3'],
    0x21 => [0x15, 'kVK_ANSI_4'],
    0x22 => [0x17, 'kVK_ANSI_5'],
    0x23 => [0x16, 'kVK_ANSI_6'],
    0x24 => [0x1A, 'kVK_ANSI_7'],
    0x25 => [0x1C, 'kVK_ANSI_8'],
    0x26 => [0x19, 'kVK_ANSI_9'],
    0x27 => [0x1D, 'kVK_ANSI_0'],
    0x28 => [0x24, 'kVK_Return'],
    0x29 => [0x35, 'kVK_Escape'],
    0x2A => [0x33, 'kVK_Delete'],
    0x2B => [0x30, 'kVK_Tab'],
    0x2C => [0x31, 'kVK_Space'],
    0x2D => [0x1B, 'kVK_ANSI_Minus'],
    0x2E => [0x18, 'kVK_ANSI_Equal'],
    0x2F => [0x21, 'kVK_ANSI_LeftBracket'],
    0x30 => [0x1E, 'kVK_ANSI_RightBracket'],
    0x31 => [0x2A, 'kVK_ANSI_Backslash'],
    0x33 => [0x29, 'kVK_ANSI_Semicolon'],
    0x34 => [0x27, 'kVK_ANSI_Quote'],
    0x35 => [0x32, 'kVK_ANSI_Grave'],
    0x36 => [0x2B, 'kVK_ANSI_Comma'],
    0x37 => [0x2F, 'kVK_ANSI_Period'],
    0x38 => [0x2C, 'kVK_ANSI_Slash'],
    0x39 => [0x39, 'kVK_CapsLock'],
    0x3A => [0x7A, 'kVK_F1'],
    0x3B => [0x78, 'kVK_F2'],
    0x3C => [0x63, 'kVK_F3'],
    0x3D => [0x76, 'kVK_F4'],
    0x3E => [0x60, 'kVK_F5'],
    0x3F => [0x61, 'kVK_F6'],
    0x40 => [0x62, 'kVK_F7'],
    0x41 => [0x64, 'kVK_F8'],
    0x42 => [0x65, 'kVK_F9'],
    0x43 => [0x6D, 'kVK_F10'],
    0x44 => [0x67, 'kVK_F11'],
    0x45 => [0x6F, 'kVK_F12'],
    0x4A => [0x73, 'kVK_Home'],
    0x4B => [0x74, 'kVK_PageUp'],
    0x4C => [0x75, 'kVK_ForwardDelete'],
    0x4D => [0x77, 'kVK_End'],
    0x4E => [0x79, 'kVK_PageDown'],
    0x4F => [0x7C, 'kVK_RightArrow'],
    0x50 => [0x7B, 'kVK_LeftArrow'],
    0x51 => [0x7D, 'kVK_DownArrow'],
    0x52 => [0x7E, 'kVK_UpArrow'],
    0x54 => [0x4B, 'kVK_ANSI_KeypadDivide'],
    0x55 => [0x43, 'kVK_ANSI_KeypadMultiply'],
    0x56 => [0x4E, 'kVK_ANSI_KeypadMinus'],
    0x57 => [0x45, 'kVK_ANSI_KeypadPlus'],
    0x58 => [0x4C, 'kVK_ANSI_KeypadEnter'],
    0x59 => [0x53, 'kVK_ANSI_Keypad1'],
    0x5A => [0x54, 'kVK_ANSI_Keypad2'],
    0x5B => [0x55, 'kVK_ANSI_Keypad3'],
    0x5C => [0x56, 'kVK_ANSI_Keypad4'],
    0x5D => [0x57, 'kVK_ANSI_Keypad5'],
    0x5E => [0x58, 'kVK_ANSI_Keypad6'],
    0x5F => [0x59, 'kVK_ANSI_Keypad7'],
    0x60 => [0x5B, 'kVK_ANSI_Keypad8'],
    0x61 => [0x5C, 'kVK_ANSI_Keypad9'],
    0x62 => [0x52, 'kVK_ANSI_Keypad0'],
    0x63 => [0x41, 'kVK_ANSI_KeypadDecimal'],
    0x64 => [0x0A, 'kVK_ISO_Section'],
    0x67 => [0x51, 'kVK_ANSI_KeypadEquals'],
    0x68 => [0x69, 'kVK_F13'],
    0x69 => [0x6B, 'kVK_F14'],
    0x6A => [0x71, 'kVK_F15'],
    0x6B => [0x6A, 'kVK_F16'],
    0x6C => [0x40, 'kVK_F17'],
    0x6D => [0x4F, 'kVK_F18'],
    0x6E => [0x50, 'kVK_F19'],
    0x6F => [0x5A, 'kVK_F20'],
    0x75 => [0x72, 'kVK_Help'],
    0x7F => [0x4A, 'kVK_Mute'],
    0x80 => [0x48, 'kVK_VolumeUp'],
    0x81 => [0x49, 'kVK_VolumeDown'],
    0x85 => [0x5F, 'kVK_JIS_KeypadComma'],
    0x87 => [0x5E, 'kVK_JIS_Underscore'],
    0x89 => [0x5D, 'kVK_JIS_Yen'],
    0x90 => [0x66, 'kVK_JIS_Eisu'],
    0x94 => [0x68, 'kVK_JIS_Kana'],
    0xD8 => [0x47, 'kVK_ANSI_KeypadClear'],
    0xE0 => [0x3B, 'kVK_Control'],
    0xE1 => [0x38, 'kVK_Shift'],
    0xE2 => [0x3A, 'kVK_Option'],
    0xE3 => [0x37, 'kVK_Command'],
    0xE4 => [0x3E, 'kVK_RightControl'],
    0xE5 => [0x3C, 'kVK_RightShift'],
    0xE6 => [0x3D, 'kVK_RightOption'],
    0xE7 => [0x36, 'kVK_RightCommand'],
    0xE8 => [0x3F, 'kVK_Function'],
];

$keyConstantToModifierFlag = [
    'kVK_CapsLock'      => 'KeyEventModifierFlagCapsLock',
    'kVK_Shift'         => 'KeyEventModifierFlagShift',
    'kVK_RightShift'    => 'KeyEventModifierFlagShift',
    'kVK_Control'       => 'KeyEventModifierFlagControl',
    'kVK_RightControl'  => 'KeyEventModifierFlagControl',
    'kVK_Option'        => 'KeyEventModifierFlagOption',
    'kVK_RightOption'   => 'KeyEventModifierFlagOption',
    'kVK_Command'       => 'KeyEventModifierFlagCommand',
    'kVK_RightCommand'  => 'KeyEventModifierFlagCommand',
    'kVK_Function'      => 'KeyEventModifierFlagFunction',
];

foreach ($layouts as $type => $id) {
    $file = "/System/Library/Input Methods/KeyboardViewer.app/Contents/Resources/KeyboardLayoutDefinition{$id}.svg";
    if (!file_exists($file)) {
        fprintf(STDERR, "Error: Layout definition SVG #{$id} ({$type}) not found!\n");
        exit(1);
    }

    $svg = new SimpleXMLElement(file_get_contents($file));

    $viewBox = (string)$svg['viewBox'];
    $viewBoxElements = explode(' ', $viewBox);
    $width = $viewBoxElements[2];
    $width += HORIZONTAL_MARGIN_INCREASE * 2;
    $height = $viewBoxElements[3];
    $height += VERTICAL_MARGIN_INCREASE * 2;
    $height += EXTRA_TOP_SPACE;
    $size = "CGSizeMake({$width}, {$height})";

    foreach ($hidToMac as $hidCode => $macCode) {
        list($keyCode, $keyConstant) = $macCode;
        if ($keyConstant == 'kVK_DownArrow') {
            $arrowDownHidCode = $hidCode;
        } elseif ($keyConstant == 'kVK_UpArrow') {
            $arrowUpHidCode = $hidCode;
        }
    }
    $svg->registerXPathNamespace('svg', 'http://www.w3.org/2000/svg');
    $arrowDownRect = $svg->xpath('//svg:g[@keyCode=' . $arrowDownHidCode . ']/svg:rect')[0];
    $arrowUpRect = $svg->xpath('//svg:g[@keyCode=' . $arrowUpHidCode . ']/svg:rect')[0];
    $arrowCenter = ((string)$arrowUpRect['y'] + (string)$arrowUpRect['height'] + (string)$arrowDownRect['y']) / 2;
    $arrowCenter = correctY($arrowCenter);

    $keyCodes = '';
    $modifierFlags = '';
    $bezierPaths = '';
    $textPositions = '';
    $fontSizes = '';

    $numberOfKeys = 0;
    foreach ($svg->g as $g) {
        $keyIndex = $numberOfKeys;

        $hidCode = (string)$g['keyCode'];
        list($keyCode, $keyConstant) = $hidToMac[(int)$hidCode];

        if ($g->text->count() != 1) continue;

        if ($g->rect->count() == 1) {
            $bezierPath = bezierPathForSvgRect($g->rect[0], $keyConstant == 'kVK_DownArrow', $keyConstant == 'kVK_UpArrow');
        } else if ($g->path->count() == 1) {
            $bezierPath = bezierPathForSvgPath($g->path[0]);
        } else {
            continue;
        }

        $text = $g->text[0];
        $x = correctX((string)$text['x']);
        $y = correctY((string)$text['y']);

        if ($keyConstant == 'kVK_DownArrow' || $keyConstant == 'kVK_UpArrow') $y += $centerOffset;

        $fontSize = (string)$text['font-size'] + FONT_SIZE_OFFSET;
        $textPosition = "CGPointMake({$x}, {$y})";

        $keyCodes       .= "        case " . pad($keyIndex) . ": return " . hex($keyCode) . "; // {$keyConstant}\n";
        $bezierPaths    .= "        case " . pad($keyIndex) . ": {$bezierPath}\n";
        $textPositions  .= "        case " . pad($keyIndex) . ": return {$textPosition};\n";
        $fontSizes      .= "        case " . pad($keyIndex) . ": return {$fontSize};\n";

        if (array_key_exists($keyConstant, $keyConstantToModifierFlag)) {
            $modifierFlags .= "        case " . pad($keyIndex) . ": return {$keyConstantToModifierFlag[$keyConstant]};\n";
        }

        $numberOfKeys++;
    }

    // Add Touch Bar "key"
    {
        $keyIndex = $numberOfKeys;
        $bezierPath = bezierPathForSvgRect([
            'x' => 1,
            'y' => 1 - TOUCH_BAR_KEY_HEIGHT - TOUCH_BAR_KEY_MARGIN,
            'width' => $viewBoxElements[2] - 2,
            'height' => TOUCH_BAR_KEY_HEIGHT,
            'rx' => 2,
            'ry' => 2,
        ]);
        $bezierPaths .= "        case {$keyIndex}: {$bezierPath}\n";
        $numberOfKeys++;
    }

    $keyCodes = rtrim($keyCodes);
    $modifierFlags = rtrim($modifierFlags);
    $bezierPaths = rtrim($bezierPaths);
    $textPositions = rtrim($textPositions);
    $fontSizes = rtrim($fontSizes);

    $header = <<<EOD
//
//  KeyboardLayout{$type}.h
//  {$project}
//
//  Generated by {$script}.
//  Copyright © {$copyright}. All rights reserved.
//

#import "KeyboardLayout.h"

@interface KeyboardLayout{$type} : KeyboardLayout

@end

EOD;

    $objc = <<<EOD
//
//  KeyboardLayout{$type}.m
//  {$project}
//
//  Generated by {$script}.
//  Copyright © {$copyright}. All rights reserved.
//

#import "KeyboardLayout{$type}.h"

@implementation KeyboardLayout{$type}

/*************************************************************
 *                                                           *
 *   WARNING: this is an auto-generated file. DO NOT EDIT!   *
 *                                                           *
 *************************************************************/

- (KeyboardLayoutType)type {
    return KeyboardLayoutType{$type};
}

- (UInt8)macKbdType {
    return {$id};
}

- (CGSize)size {
    return {$size};
}

- (NSUInteger)numberOfKeys {
    return {$numberOfKeys};
}

- (KeyCode)keyCodeForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
{$keyCodes}
        default: return [super keyCodeForKeyIndex:keyIndex];
    }
}

- (KeyEventModifierFlags)modifierFlagForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
{$modifierFlags}
        default: return [super modifierFlagForKeyIndex:keyIndex];
    }
}

#if TARGET_OS_IPHONE
- (UIBezierPath *)bezierPathForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
{$bezierPaths}
        default: return [super bezierPathForKeyIndex:keyIndex];
    }
}
#endif

- (CGPoint)textPositionForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
{$textPositions}
        default: return [super textPositionForKeyIndex:keyIndex];
    }
}

- (CGFloat)fontSizeForKeyIndex:(NSUInteger)keyIndex {
    switch (keyIndex) {
{$fontSizes}
        default: return [super fontSizeForKeyIndex:keyIndex];
    }
}

@end

EOD;

    file_put_contents("{$dir}/KeyboardLayout{$type}.h", $header);
    file_put_contents("{$dir}/KeyboardLayout{$type}.m", $objc);
}

function correctX($x) {
    return $x + HORIZONTAL_MARGIN_INCREASE;
}

function correctY($y) {
    return $y + VERTICAL_MARGIN_INCREASE + EXTRA_TOP_SPACE;
}

function bezierPathForSvgRect($rect, $isArrowDown = false, $isArrowUp = false) {
    global $arrowCenter;
    global $centerOffset;

    // Simplification assumptions:
    //   rx == ry

    $x = correctX((string)$rect['x']);
    $x -= KEY_WIDTH_INCREASE / 2;
    $y = correctY((string)$rect['y']);
    $y -= KEY_HEIGHT_INCREASE / 2;
    $w = (string)$rect['width'] + KEY_WIDTH_INCREASE;
    $h = (string)$rect['height'] + KEY_HEIGHT_INCREASE;
    $r = (string)$rect['rx'];

    $centerOffset = 0;
    if ($isArrowDown) {
        $d = $arrowCenter - $y;
        if ($d > 0) {
            $centerOffset = $d / 2;
            $h -= $d;
            $y = $arrowCenter;
        }
    } elseif ($isArrowUp) {
        $d = $y + $h - $arrowCenter;
        if ($d > 0) {
            $centerOffset = -$d / 2;
            $h -= $d;
        }
    }

    return "return [UIBezierPath bezierPathWithRoundedRect:CGRectMake({$x}, {$y}, {$w}, {$h}) cornerRadius:{$r}];";
}

function boundariesForSvgPathDescriptor($descriptor) {
    $minX =  99999;
    $minY =  99999;
    $maxX = -99999;
    $maxY = -99999;
    while (!empty($descriptor)) {
        $x = null;
        $y = null;
        $command = array_shift($descriptor);
        switch ($command) {
            case 'A':
                array_shift($descriptor);
                array_shift($descriptor);
                array_shift($descriptor);
                array_shift($descriptor);
                array_shift($descriptor);
                $x = array_shift($descriptor);
                $y = array_shift($descriptor);
                break;
            case 'L':
                $x = array_shift($descriptor);
                $y = array_shift($descriptor);
                break;
            case 'M':
                $x = array_shift($descriptor);
                $y = array_shift($descriptor);
                break;
            default:
                break;
        }
        if ($x !== null) {
            $minX = min($minX, $x);
            $minY = min($minY, $y);
            $maxX = max($maxX, $x);
            $maxY = max($maxY, $y);
        }
    }
    return [$minX, $minY, $maxX, $maxY];
}

function stretchX($x, $minX, $maxX) {
    $dx = ($x - $minX) / ($maxX - $minX);
    return $x + KEY_WIDTH_INCREASE / 2 * ($dx < 0.5 ? -1 : 1);
}

function stretchY($y, $minY, $maxY) {
    $dy = ($y - $minY) / ($maxY - $minY);
    return $y + KEY_HEIGHT_INCREASE / 2 * ($dy < 0.25 ? -1 : 1);
}

function bezierPathForSvgPath($path) {
    $i = "            ";
    $p  = "{\n";
    $p .= "{$i}UIBezierPath *path = [UIBezierPath new];\n";

    $descriptor = trim((string)$path['d']);
    $descriptor = str_replace(',', ' ', $descriptor);
    $descriptor = preg_replace('/\s\s+/', ' ', $descriptor);
    $descriptor = explode(' ', $descriptor);

    list($minX, $minY, $maxX, $maxY) = boundariesForSvgPathDescriptor($descriptor);

    while (!empty($descriptor)) {
        $command = array_shift($descriptor);
        switch ($command) {
            case 'A':
                // Simplification assumptions:
                //   rx == ry
                //   phi == 0
                //   largeArcFlag == false

                $rx = array_shift($descriptor);
                $ry = array_shift($descriptor); // Ignored, assumed equal to $rx
                $phi = array_shift($descriptor); // Ignored, assumed 0
                $largeArcFlag = array_shift($descriptor) != 0; // Ignored, assumed false
                $sweepFlag = array_shift($descriptor) != 0;
                $x = correctX(stretchX(array_shift($descriptor), $minX, $maxX));
                $y = correctY(stretchY(array_shift($descriptor), $minY, $maxY));

                $x1p = ($lastX - $x) / 2;
                $y1p = ($lastY - $y) / 2;

                $rx_2 = $rx * $rx;
                $xp_2 = $x1p * $x1p;
                $yp_2 = $y1p * $y1p;

                $delta = ($xp_2 + $yp_2) / $rx_2;

                if ($delta > 1.0) {
                    $rx *= sqrt($delta);
                    $rx_2 = $rx * $rx;
                }

                $numerator = $rx_2 * ($rx_2 -  $yp_2 - $xp_2);
                $denom = $rx_2 * ($xp_2 + $yp_2);
                $numerator = max(0, $numerator);
                $lhs = sqrt($numerator / $denom) * ($sweepFlag ? 1 : -1);

                $cx = $lhs *  $y1p + ($lastX + $x) / 2;
                $cy = $lhs * -$x1p + ($lastY + $y) / 2;

                $startAngle = atan2($lastY - $cy, $lastX - $cx);
                $endAngle = atan2($y - $cy, $x - $cx);

                $clockWise = $sweepFlag ? 'YES' : 'NO';
                $p .= "{$i}[path addArcWithCenter:CGPointMake({$cx}, {$cy}) radius:{$rx} startAngle:${startAngle} endAngle:${endAngle} clockwise:{$clockWise}];\n";
                break;

            case 'L':
                $x = correctX(stretchX(array_shift($descriptor), $minX, $maxX));
                $y = correctY(stretchY(array_shift($descriptor), $minY, $maxY));
                $p .= "{$i}[path addLineToPoint:CGPointMake({$x}, {$y})];\n";
                break;
            case 'M':
                $x = correctX(stretchX(array_shift($descriptor), $minX, $maxX));
                $y = correctY(stretchY(array_shift($descriptor), $minY, $maxY));
                $p .= "{$i}[path moveToPoint:CGPointMake({$x}, {$y})];\n";
                break;
            case 'Z':
            case 'z':
                $p .= "{$i}[path closePath];\n";
                break;
        }
        $lastX = $x;
        $lastY = $y;
    }

    $p .= "{$i}return path;\n";
    $p .= "        }";
    return $p;
}

function pad($x) {
    return str_pad($x, 2, ' ', STR_PAD_LEFT);
}

function hex($x) {
    return '0x' . str_pad(strtoupper(dechex($x)), 2, '0', STR_PAD_LEFT);
}
