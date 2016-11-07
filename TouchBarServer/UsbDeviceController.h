//
//  UsbDeviceController.h
//  TouchBar
//
//  Created by Robbert Klarenbeek on 06/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const UsbDeviceControllerErrorDomain;
enum {
    UsbDeviceControllerDeviceNotAttachedError,
    UsbDeviceControllerNotConnectedError,
};

@protocol UsbDeviceControllerDelegate <NSObject>
@optional
- (void)deviceDidConnect:(NSNumber *)deviceId ;
- (void)deviceDidDisconnect:(NSNumber *)deviceId;
- (void)device:(NSNumber *)deviceId didReceiveMessageOfType:(uint32_t)type data:(NSData*)data;
@end

@interface UsbDeviceController : NSObject
@property (nonatomic, assign) int port;
@property (nonatomic, assign) NSTimeInterval retryInterval;
@property (nonatomic, weak) id <UsbDeviceControllerDelegate> delegate;
@property (nonatomic, readonly) NSArray *connectedDeviceIds;
- (instancetype)init;
- (instancetype)initWithPort:(int)port;
- (void)startConnectingToUsbDevices;
- (void)stopConnectingToUsbDevices;
- (void)sendMessageToDevice:(NSNumber *)deviceId type:(uint32_t)type data:(NSData *)payload callback:(void(^)(NSError *error))callback;
- (void)broadcaseMessageOfType:(uint32_t)type data:(NSData *)data callback:(void(^)(NSDictionary *errors))callback;
@end
