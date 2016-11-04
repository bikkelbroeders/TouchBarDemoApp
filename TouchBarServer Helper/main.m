//
//  main.m
//  TouchBarServer Helper
//
//  Created by Robbert Klarenbeek on 03/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
}
