//
//  UsbDeviceController.m
//  TouchBar
//
//  Created by Robbert Klarenbeek on 06/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "UsbDeviceController.h"

#import "Peertalk.h"

NSErrorDomain const UsbDeviceControllerErrorDomain = @"com.bikkelbroeders.usbdevicecontroller";

@interface NSData (DispatchData)
@property (nonatomic, readonly) dispatch_data_t dispatchData;
@end

@implementation NSData (DispatchData)
- (dispatch_data_t)dispatchData {
    NSData* immutableSelf = [self copy];
    CFDataRef immutableSelfRef = CFBridgingRetain(immutableSelf);
    return dispatch_data_create(immutableSelf.bytes, immutableSelf.length, dispatch_get_main_queue(), ^{
        CFRelease(immutableSelfRef);
    });
}
@end

typedef NS_ENUM(NSUInteger, ConnectionState) {
    ConnectionStateNotConnected,
    ConnectionStateConnecting,
    ConnectionStateConnected,
};

@interface AttachedDevice : NSObject
@property (nonatomic, strong) NSNumber *deviceId;
@property (nonatomic, assign) ConnectionState connectionState;
@property (nonatomic, strong) PTChannel *channel;
@end

@implementation AttachedDevice
- (instancetype)initWithDeviceId:(NSNumber *)deviceId {
    self = [self init];
    if (self) {
        _deviceId = deviceId;
        _connectionState = ConnectionStateNotConnected;
        _channel = nil;
    }
    return self;
}
@end

@interface UsbDeviceController () <PTChannelDelegate>
@end

@implementation UsbDeviceController {
    BOOL _isConnecting;
    NSMutableDictionary *_attachedDevices;
    NSTimer *_connectTimer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _port = 0;
        _retryInterval = 1.0;
        _isConnecting = NO;
        _attachedDevices = [NSMutableDictionary new];
        _connectTimer = nil;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
            NSNumber *deviceId = note.userInfo[@"DeviceID"];
            if (!_attachedDevices[deviceId]) {
                _attachedDevices[deviceId] = [[AttachedDevice alloc] initWithDeviceId:deviceId];
            }
            [self restartConnectTimer];
        }];
        [notificationCenter addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
            NSNumber *deviceId = note.userInfo[@"DeviceID"];
            AttachedDevice *device = _attachedDevices[deviceId];
            if (device) {
                if (device.connectionState == ConnectionStateConnected && device.channel) {
                    [device.channel close];
                }
                [_attachedDevices removeObjectForKey:deviceId];
            }
        }];
    }
    return self;
}

- (instancetype)initWithPort:(int)port {
    self = [self init];
    if (self) {
        _port = port;
    }
    return self;
}

- (void)setRetryInterval:(NSTimeInterval)retryInterval {
    _retryInterval = retryInterval;
    [self restartConnectTimer];
}

- (void)startConnectingToUsbDevices {
    if (_isConnecting) return;
    [self startConnectTimer];
    _isConnecting = YES;
}

- (void)stopConnectingToUsbDevices {
    if (!_isConnecting) return;
    [self stopConnectTimer];
    _isConnecting = NO;

    for (NSNumber *deviceId in _attachedDevices) {
        AttachedDevice *device = _attachedDevices[deviceId];
        if (device.connectionState == ConnectionStateConnected && device.channel) {
            [device.channel close];
        }
        device.connectionState = ConnectionStateNotConnected;
    }
}

- (NSArray *)connectedDeviceIds {
    NSSet *deviceIds = [_attachedDevices keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [obj connectionState] == ConnectionStateConnected;
    }];
    return [deviceIds allObjects];
}

- (void)sendMessageToDevice:(NSNumber *)deviceId type:(uint32_t)type data:(NSData *)data callback:(void(^)(NSError *error))callback {
    AttachedDevice *device = _attachedDevices[deviceId];
    [self sendToDevice:device type:type payload:[data dispatchData] callback:callback];
}

- (void)broadcaseMessageOfType:(uint32_t)type data:(NSData *)data callback:(void(^)(NSDictionary *errors))callback {
    dispatch_data_t payload = [data dispatchData];

    NSArray *connectedDeviceIds = self.connectedDeviceIds;
    if (connectedDeviceIds.count > 0) {
        NSMutableDictionary *results = [NSMutableDictionary new];
        for (NSNumber *deviceId in connectedDeviceIds) {
            AttachedDevice *device = _attachedDevices[deviceId];
            [self sendToDevice:device type:type payload:payload callback:^(NSError *error) {
                results[device.deviceId] = error ? error : [NSNull null];
                if (results.count == connectedDeviceIds.count && callback) {
                    NSSet *nullResults = [results keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        return [obj isEqual:[NSNull null]];
                    }];
                    [results removeObjectsForKeys:[nullResults allObjects]];
                    callback(results.count > 0 ? results : nil);
                }
            }];
        }
    } else {
        callback(nil);
    }
}

#pragma mark - private

- (void)sendToDevice:(AttachedDevice *)device type:(uint32_t)type payload:(dispatch_data_t)payload callback:(void(^)(NSError *error))callback {
    if (!device) {
        if (callback) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Device is not attached" };
            callback([NSError errorWithDomain:UsbDeviceControllerErrorDomain code:UsbDeviceControllerDeviceNotAttachedError userInfo:userInfo]);
        }
        return;
    }
    
    if (device.connectionState != ConnectionStateConnected || !device.channel) {
        if (callback) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Device is not connected" };
            callback([NSError errorWithDomain:UsbDeviceControllerErrorDomain code:UsbDeviceControllerNotConnectedError userInfo:userInfo]);
        }
        return;
    }
    
    [device.channel sendFrameOfType:type tag:PTFrameNoTag withPayload:payload callback:callback];
}

- (void)startConnectTimer {
    if (!_connectTimer) {
        SEL selector = @selector(connectDevices);
        _connectTimer = [NSTimer scheduledTimerWithTimeInterval:_retryInterval target:self selector:selector userInfo:nil repeats:YES];
        [self performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
    }
}

- (void)stopConnectTimer {
    if (_connectTimer) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
}

- (void)restartConnectTimer {
    // Only restart if we were already running
    if (_connectTimer) {
        [self stopConnectTimer];
        [self startConnectTimer];
    }
}

- (void)connectDevices {
    for (NSNumber *deviceId in _attachedDevices) {
        AttachedDevice *device = _attachedDevices[deviceId];
        if (device.connectionState == ConnectionStateNotConnected) {
            device.connectionState = ConnectionStateConnecting;
            PTChannel *channel = [PTChannel channelWithDelegate:self];
            channel.userInfo = device;
            [channel connectToPort:_port overUSBHub:PTUSBHub.sharedHub deviceID:device.deviceId callback:^(NSError *error) {
                if (device.connectionState != ConnectionStateConnecting) return;
                
                if (error) {
                    if (error.domain != PTUSBHubErrorDomain || error.code != PTUSBHubErrorConnectionRefused) {
                        NSLog(@"Failed to connect to device %@: %@", device.deviceId, error);
                    }
                    device.connectionState = ConnectionStateNotConnected;
                    return;
                }
                device.channel = channel;
                device.connectionState = ConnectionStateConnected;
                
                if([self.delegate respondsToSelector:@selector(deviceDidConnect:)]) {
                    [self.delegate deviceDidConnect:device.deviceId];
                }
            }];
        }
    }
}

#pragma mark - PTChannelDelegate

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    AttachedDevice *device = channel.userInfo;
    if([self.delegate respondsToSelector:@selector(device:didReceiveMessageOfType:data:)]) {
        [self.delegate device:device.deviceId didReceiveMessageOfType:type data:[NSData dataWithBytes:payload.data length:payload.length]];
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    AttachedDevice *device = channel.userInfo;
    device.connectionState = ConnectionStateNotConnected;
    device.channel = nil;
    
    if([self.delegate respondsToSelector:@selector(deviceDidDisconnect:)]) {
        [self.delegate deviceDidDisconnect:device.deviceId];
    }
}

@end
