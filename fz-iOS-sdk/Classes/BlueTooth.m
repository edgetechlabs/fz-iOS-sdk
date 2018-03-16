//
//  BlueTooth.m
//
//
//  Created by edgetechlabs on 16/3/18.
//  Copyright © 2018year edgetechlabs. All rights reserved.
//

#import "BlueTooth.h"

#define COMMAND_SET         0x00
#define COMMAND_SET_ALL     0x01
#define COMMAND_SET_ACROSS  0x02
#define COMMAND_SET_SUBSET  0x03
#define COMMAND_SET_CLEAR   0x04
#define COMMAND_SET_DISPALY 0x08


#define DFU_SERVICE_UUID                    @"8f400001-f315-4f60-9fb8-838830daea51"
#define DFU_WRITE_CHARACTERISTIC_UUID       @"8ec90001-f315-4f60-9fb8-838830daea50"


#define GUITAR_SERVICE_UUID                 @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define GUITAR_WRITE_CHARACTERISTIC_UUID    @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define GUITAR_NOTIFY_CHARACTERISTIC_UUID   @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define ORG_SERVICE_DEVICE_INFORMATION  @"180A"
#define ORG_SERVICE_BATTERY_INFORMATION @"180F"
#define ORG_MANUFACTURER_NAME_STRING    @"2A29"
#define ORG_MODEL_NUMBER_STRING         @"2A24"
#define ORG_SERIAL_NUMBER_STRING        @"2A25"
#define ORG_HARDWARE_REVISION_STRING    @"2A27"
#define ORG_BBATTERY_INFORMATION        @"2A19"





int command_buffer_size = 0;
Byte sendBuffer[65535];
int sendIndex = 0;

@interface BlueTooth ()

@property (nonatomic, assign)  CBCentralManagerState state;

@property (nonatomic, strong) NSMutableArray *DeviceArray;
@property (nonatomic, strong) NSMutableArray *ServiceArray;
@property (nonatomic, strong) NSMutableArray *CharacteristicArray;

@property (nonatomic, strong) CBPeripheral *ConnectionDevice;

@property (nonatomic, copy)  ScanDevicesCompleteBlock scanBlock;
@property (nonatomic, copy)  ConnectionDeviceBlock connectionBlock;
@property (nonatomic, copy)  ServiceAndCharacteristicBlock serviceAndcharBlock;
@end


@implementation BlueTooth

#define DEBUGLOG_BLE    1


#pragma mark - Custom Method
static id _instance;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        _ServiceArray = [[NSMutableArray alloc] init];
        _CharacteristicArray = [[NSMutableArray alloc] init];
        _DeviceArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)startScanDevicesWithInterval:(NSUInteger)timeout CompleteBlock:(ScanDevicesCompleteBlock)block
{
#if DEBUGLOG_BLE
    NSLog(@"start search device ...");
#endif
    [self.DeviceArray removeAllObjects];
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    self.scanBlock = block;
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    [self performSelector:@selector(stopScanDevices) withObject:nil afterDelay:timeout];
}

- (void)stopScanDevices
{
#if DEBUGLOG_BLE
    NSLog(@"stop search device ...");
#endif
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopScanDevices) object:nil];
    [self.manager stopScan];
    if (self.scanBlock)
    {
        self.scanBlock(self.DeviceArray);
    }
    self.scanBlock = nil;
}




- (void)connectionWithDeviceUUID:(NSString *)uuid TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block
{
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    for (CBPeripheral *device in self.DeviceArray)
    {
        if ([device.identifier.UUIDString isEqualToString:uuid])
        {
            [self.manager connectPeripheral:device options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
            break;
        }
    }
}

- (void)disconnectionDevice
{
#if DEBUGLOG_BLE
    NSLog(@"device disconnect.");
#endif
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    if(self.ConnectionDevice !=nil)
        [self.manager cancelPeripheralConnection:self.ConnectionDevice];
    self.ConnectionDevice = nil;
}

- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block
{
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    self.serviceAndcharBlock = block;
    self.ConnectionDevice.delegate = self;
    
    [self.ConnectionDevice discoverServices:nil];
    
    [self performSelector:@selector(discoverServiceAndCharacteristicWithTime) withObject:nil afterDelay:time];
}

- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data
{
    for (CBService *service in self.ConnectionDevice.services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]])
        {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]])
                {
                    [self.ConnectionDevice writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}


- (BOOL)sendCommand:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID
{
    
    NSMutableData *packet;
    packet = [[NSMutableData alloc] init];
    
    if( [pktData length] > 0 )
    {
        [packet appendData:pktData];
    }
#if DEBUGLOG_BLE
    NSLog(@"BLE Send Command --> %@", packet);
#endif
    
    [self writeCharacteristicWithServiceUUID:sUUID CharacteristicUUID:cUUID data:packet];
    return true;
}

- (BOOL)sendCommand:(Byte)cmd data:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID
{
    Byte header[3];
    
    header[0] = 0;
    header[1] = cmd;
    if(pktData == nil)
        header[2] = 0;
    else
        header[2] = [pktData length];
    NSMutableData *packet;
    packet = [[NSMutableData alloc] initWithBytes:header length:3];
    
    if( [pktData length] > 0 )
    {
        [packet appendData:pktData];
    }
#if DEBUGLOG_BLE
    NSLog(@"BLE Send Command --> %@", packet);
#endif
    
    [self writeCharacteristicWithServiceUUID:sUUID CharacteristicUUID:cUUID data:packet];
    return true;
}

- (BOOL)sendPacket:(Byte)cmd packetIndex:(int)idx data:(NSData *)pktData ServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID
{
    Byte header[5];
    NSInteger pktLen;
    
    header[0] = 0;
    header[1] = cmd;
    if( pktData == nil )
        pktLen = 0;
    else
        pktLen = [pktData length] + 2;
    
    header[2] = pktLen & 0x00FF;
    header[3] = idx & 0x00FF;
    header[4] = (idx >> 8) & 0x00FF;
    
    NSMutableData *packet;
    packet = [[NSMutableData alloc] initWithBytes:header length:5];
    if( pktLen )
    {
        [packet appendData:pktData];
    }
    
#if DEBUGLOG_BLE
    NSLog(@"BLE Send Buf --> %@", packet);
#endif
    // send func
    [self writeCharacteristicWithServiceUUID:sUUID CharacteristicUUID:cUUID data:packet];
    return true;
}
- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable
{
    for (CBService *service in self.ConnectionDevice.services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]])
        {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]])
                {
                    [self.ConnectionDevice setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID{
    for (CBService *service in self.ConnectionDevice.services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]])
        {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]])
                {
                    [self.ConnectionDevice readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

#pragma mark - 私有方法

- (void)connectionTimeOut
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    if (self.connectionBlock)
    {
        self.connectionBlock(nil, [self wrapperError:@"Connection device timeout!" Code:400]);
    }
    self.connectionBlock = nil;
}

- (void)discoverServiceAndCharacteristicWithTime
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    if (self.serviceAndcharBlock)
    {
        self.serviceAndcharBlock(self.ServiceArray, self.CharacteristicArray, [self wrapperError:@"Discover services and features completed!" Code:400]);
    }
    self.connectionBlock = nil;
}

- (NSError *)wrapperError:(NSString *)msg Code:(NSInteger)code
{
    NSError *error = [NSError errorWithDomain:msg code:code userInfo:nil];
    return error;
}

#pragma mark - CBCentralManagerDelegate代理方法

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if DEBUGLOG_BLE
    NSLog(@"Current device status:%ld", (long)central.state);
#endif
    self.state = central.state;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
#if DEBUGLOG_BLE
    NSLog(@"Disconvered device : %@", peripheral);
    NSLog(@"advertisementData : %@", advertisementData);
#endif
    [self.DeviceArray addObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
#if DEBUGLOG_BLE
    NSLog(@"Device Connection succeed : %@", peripheral);
#endif
    self.ConnectionDevice = peripheral;
    self.ConnectionDevice.delegate = self;
    
    if (self.connectionBlock)
    {
        self.connectionBlock(peripheral, [self wrapperError:@"connection succeeded!" Code:401]);
    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;

{
    if (error)
    {
#if DEBUGLOG_BLE
        NSLog(@"The connection has timed out unexpectedly.:%@", error);
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:DisconnectEvent object:error];
    }
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;

{
    if (error)
    {
#if DEBUGLOG_BLE
        NSLog(@"The connection has timed out unexpectedly.:%@", error);
#endif
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DisconnectEvent object:error];
    }
}






- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Search service error, error message:%@", error);
    }
    for (CBService *service in peripheral.services)
    {
        [self.ServiceArray addObject:service];
        [self.ConnectionDevice discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Search feature error, error message:%@", error);
    }
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        [self.CharacteristicArray addObject:characteristic];
    }
}

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;
{
    NSLog(@"readValueForCharacteristic");
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
#if DEBUGLOG_BLE
        NSLog(@"didWriteValueForCharacteristicReceived data error,%@", error);
#endif
        return;
    }
#if DEBUGLOG_BLE
    NSLog(@"didWriteValueForCharacteristicWrite value changed,%@", error);
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:WriteSuccessChange object:nil];
    
    NSMutableData *sendData;
    if(sendIndex < command_buffer_size)
    {
        if(sendIndex + 20 < command_buffer_size)
        {
            sendData = [[NSMutableData alloc] init];
            Byte temp[20];
            memcpy(temp, sendBuffer + sendIndex, 20);
            [sendData setData:[NSData dataWithBytes:temp length:20]];
            [self sendCommand:sendData ServiceUUID:GUITAR_SERVICE_UUID CharacteristicUUID:GUITAR_WRITE_CHARACTERISTIC_UUID];
            NSLog(@"sendData : %@\n", sendData);
            sendIndex+=20;
            sleep(0.05);
        }
        else
        {
            sendData = [[NSMutableData alloc] init];
            Byte temp[20];
            memcpy(temp, sendBuffer + sendIndex, command_buffer_size - sendIndex);
            [sendData setData:[NSData dataWithBytes:temp length:command_buffer_size - sendIndex]];
            [self sendCommand:sendData ServiceUUID:GUITAR_SERVICE_UUID CharacteristicUUID:GUITAR_WRITE_CHARACTERISTIC_UUID];
            sendIndex+=command_buffer_size - sendIndex;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#if DEBUGLOG_BLE
    NSLog(@"didUpdateNotificationStateForCharacteristicThe data received is%@", characteristic.UUID);
#endif
    if (error)
    {
        NSLog(@"didUpdateValueForCharacteristicReceived data error,%@", error);
        return;
    }
    NSString *uuid = [characteristic.UUID UUIDString];
    if([uuid isEqualToString:ORG_BBATTERY_INFORMATION])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:didBatteryValue object:characteristic];
    }
    else if([uuid isEqualToString:ORG_MANUFACTURER_NAME_STRING])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:didManufacturerNameValue object:characteristic];
    }
    else if([uuid isEqualToString:ORG_MODEL_NUMBER_STRING])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:didModelNumberValue object:characteristic];
    }
    else if([uuid isEqualToString:ORG_SERIAL_NUMBER_STRING])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:didSerialNumberValue object:characteristic];
    }
    else if([uuid isEqualToString:ORG_HARDWARE_REVISION_STRING])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:didHardwareRevisionValue object:characteristic];
    }
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:NotiValueChange object:characteristic.value];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if (error)
    {
        NSLog(@"didUpdateNotificationStateForCharacteristicReceived data error,%@", error);
        return;
    }
    //NSString *string=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"didUpdateNotificationStateForCharacteristicThe data received is%@", characteristic.UUID);
    
}
#pragma mark - getter
- (BOOL)isReady
{
    return self.state == CBCentralManagerStatePoweredOn ? YES : NO;
}

- (BOOL)isConnection
{
    return self.ConnectionDevice.state == CBPeripheralStateConnected ? YES : NO;
}



#pragma mark - Guitar Function


- (void) set:(int)Strand withPixel:(int)Pixel withRed:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade
{
    [self addBuffer:COMMAND_SET fade:fade strand:Strand R:R G:G B:B pixel:Pixel];
}
- (void) set_all:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade
{
    [self addBuffer:COMMAND_SET_ALL fade:fade strand:0 R:R G:G B:B pixel:0];
}
- (void) set_across:(int)Pixel Red:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade
{
    [self addBuffer:COMMAND_SET_ACROSS fade:fade strand:0 R:R G:G B:B pixel:Pixel];
}
- (void) set_subset:(int)Strand_start withPixel:(int)Pixel Red:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade
{
    [self addBuffer:COMMAND_SET_SUBSET fade:fade strand:Strand_start R:R G:G B:B pixel:Pixel];
}
- (void) clear
{
    [self addBuffer:COMMAND_SET_CLEAR fade:0 strand:0 R:0 G:0 B:0 pixel:0];
}

- (void) setDisplay:(int)Strand withIntensity:(int)intensity withFade:(int)fade
{
    [self addBuffer:COMMAND_SET_DISPALY fade:fade strand:Strand R:0 G:0 B:0 pixel:0];
}

-(void) addBuffer:(Byte)cmd fade:(Byte)fade strand:(Byte)strand R:(Byte)R G:(Byte)G B:(Byte)B pixel:(Byte)pixel
{
    Byte d1 = (Byte)((cmd<<4)|(fade & 0x0F));
    Byte d2 = (Byte)((strand <<4) | (R & 0xF));
    Byte d3 = (Byte)(((G&0xF)<<4) | (B & 0xF));
    Byte d4 = (Byte)(1<<(pixel+1));
    
    sendBuffer[command_buffer_size++] = d1;
    sendBuffer[command_buffer_size++] = d2;
    sendBuffer[command_buffer_size++] = d3;
    sendBuffer[command_buffer_size++] = d4;
}




-(void) sendCommandFlush
{
    NSMutableData *sendData;
    if(20 < command_buffer_size)
    {
        sendData = [[NSMutableData alloc] init];
        Byte temp[20];
        memcpy(temp, sendBuffer + sendIndex, 20);
        [sendData setData:[NSData dataWithBytes:temp length:20]];
        [self sendCommand:sendData ServiceUUID:GUITAR_SERVICE_UUID CharacteristicUUID:GUITAR_WRITE_CHARACTERISTIC_UUID];
        NSLog(@"sendData : %@\n", sendData);
        sendIndex+=20;
    }
    else
    {
        sendData = [[NSMutableData alloc] init];
        Byte temp[20];
        memcpy(temp, sendBuffer + sendIndex, command_buffer_size - sendIndex);
        [sendData setData:[NSData dataWithBytes:temp length:command_buffer_size - sendIndex]];
        [self sendCommand:sendData ServiceUUID:GUITAR_SERVICE_UUID CharacteristicUUID:GUITAR_WRITE_CHARACTERISTIC_UUID];
        sendIndex+=command_buffer_size - sendIndex;
    }
}


-(void) sendCommandClear
{
    command_buffer_size = 0;
    memset(sendBuffer, 0, 65535);
    sendIndex = 0;
}

-(void) sendDFUMode
{
    Byte tempBuf[] = {0x01};
    NSMutableData *sendData;
    sendData = [[NSMutableData alloc] init];
    [sendData setData:[NSData dataWithBytes:tempBuf length:1]];
    NSLog(@" sendDFUMode \n");
    
    [self setNotificationForCharacteristicWithServiceUUID:DFU_SERVICE_UUID CharacteristicUUID:DFU_SERVICE_UUID enable:true];
    sleep(1.5);
    [self sendCommand:sendData ServiceUUID:DFU_SERVICE_UUID CharacteristicUUID:DFU_SERVICE_UUID];
}


-(void) readBatteryValue
{
    NSLog(@"\nreadBatteryValue");
    [self readCharacteristicWithServiceUUID:ORG_SERVICE_BATTERY_INFORMATION CharacteristicUUID:ORG_BBATTERY_INFORMATION];
}

-(void) readManufacturerName
{
    NSLog(@"\nreadManufacturerName");
    [self readCharacteristicWithServiceUUID:ORG_SERVICE_DEVICE_INFORMATION CharacteristicUUID:ORG_MANUFACTURER_NAME_STRING];
}

-(void) readModelNumber
{
    NSLog(@"\nreadModelNumber");
    [self readCharacteristicWithServiceUUID:ORG_SERVICE_DEVICE_INFORMATION CharacteristicUUID:ORG_MODEL_NUMBER_STRING];
}

-(void) readSerialNumber
{
    NSLog(@"\nreadSerialNumber");
    [self readCharacteristicWithServiceUUID:ORG_SERVICE_DEVICE_INFORMATION CharacteristicUUID:ORG_SERIAL_NUMBER_STRING];
}

-(void) readHardwareRevision
{
    NSLog(@"\nreadHardwareRevision");
    [self readCharacteristicWithServiceUUID:ORG_SERVICE_DEVICE_INFORMATION CharacteristicUUID:ORG_HARDWARE_REVISION_STRING];
}

@end
