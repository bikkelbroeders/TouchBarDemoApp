//
//  Application.h
//  TouchBarServer
//
//  Created by Robbert Klarenbeek on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GlobalEventApplication : NSApplication

@property (nonatomic, assign) int globalEventMask;

@end
