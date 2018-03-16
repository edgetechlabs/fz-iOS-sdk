//
//  BlueTooth.h
//
//
//  Created by edgetechlabs on 16/3/18.
//  Copyright © 2018year edgetechlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const NotiValueChange = @"ValueChange";
static NSString *const WriteSuccessChange = @"WriteSuccess";
static NSString *const DisconnectEvent = @"Dev_Disconnected";

static NSString * const BLEDeviceServiceNotFound = @"EBMServiceNotFound";
static NSString * const BLEDeviceServiceFoundSuccess = @"EBMServiceFound";

static NSString * const didBatteryValue = @"didBatteryValue";
static NSString * const didManufacturerNameValue = @"didManufacturerNameValue";
static NSString * const didModelNumberValue = @"didModelNumberValue";
static NSString * const didSerialNumberValue = @"didSerialNumberValue";
static NSString * const didHardwareRevisionValue=@"didHardwareRevisionValue";

/**
 *  Scan device callback
 *
 *  @param devices Device array
 */
typedef void (^ScanDevicesCompleteBlock)(NSArray *devices);
/**
 *  Connection device callback
 *
 *  @param device equipment
 *  @param err Error message
 */
typedef void (^ConnectionDeviceBlock)(CBPeripheral *device, NSError *err);
/**
 *  Discover callbacks for services and features
 *
 *  @param serviceArray        Service array
 *  @param characteristicArray Characteristic array
 *  @param err                 Error message
 */
typedef void (^ServiceAndCharacteristicBlock)(NSArray *serviceArray, NSArray *characteristicArray, NSError *err);


@interface BlueTooth : NSObject<CBPeripheralDelegate, CBCentralManagerDelegate>
/**
 *  Manager
 */
@property (nonatomic, strong, readonly) CBCentralManager *manager;
/**
 *
 Is Bluetooth available?
 */
@property (nonatomic, assign, readonly, getter = isReady)  BOOL Ready;
/**
 *
 Is connected
 */
@property (nonatomic, assign, readonly, getter = isConnection)  BOOL Connection;
/**
 *  Singleton
 *
 *  @return
 */
+ (instancetype)sharedInstance;
/**
 *  Start scanning
 *
 *  @param timeout
 Scan timeout period
 *  @param block   Callback
 */
- (void)startScanDevicesWithInterval:(NSUInteger)timeout CompleteBlock:(ScanDevicesCompleteBlock)block;
/**
 *  Stop scanning
 */
- (void)stopScanDevices;
/**
 *  Connected equipment
 *
 *  @param device  equipment
 *  @param timeout Connection timeout period
 *  @param block   Callback
 */
- (void)connectionWithDeviceUUID:(NSString *)uuid TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block;
/**
 *  Disconnect
 */
- (void)disconnectionDevice;
/**
 *  Scanning service and features
 *
 *  @param timeout Discovered time range
 *  @param block   Callback
 */
- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block;
/**
 *
 Write data to connected devices
 *
 *  @param sUUID serviceUUID
 *  @param cUUID featureUUID
 *  @param data  data

 */
- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data;
/**
 *  Set up notifications
 *
 *  @param sUUID  serviceUUID
 *  @param cUUID  featureUUID
 *  @param enable
 */
- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable;

-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID;

- (BOOL)sendPacket:(Byte)cmd packetIndex:(int)idx data:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID;

- (BOOL)sendCommand:(Byte)cmd data:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID;

- (BOOL)sendCommand:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID;




- (void) set:(int)Strand withPixel:(int)Pixel withRed:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
- (void) set_all:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
- (void) set_across:(int)Pixel Red:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
- (void) set_subset:(int)Strand_start withPixel:(int)Pixel Red:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
- (void) clear;
- (void) setDisplay:(int)Strand withIntensity:(int)intensity withFade:(int)fade;
- (void) batteryUpdate:(BOOL)ON;

- (void) sendCommandFlush;
- (void) sendCommandClear;

- (void) readBatteryValue;
- (void) readManufacturerName;
- (void) readModelNumber;
- (void) readSerialNumber;
- (void) readHardwareRevision;

- (void) sendDFUMode;

@end
