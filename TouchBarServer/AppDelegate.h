//
//  AppDelegate.h
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 02/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (void)globalEvent:(NSEvent *)event;

@end

