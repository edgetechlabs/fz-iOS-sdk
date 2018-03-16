# fz-iOS-sdk

[![CI Status](http://img.shields.io/travis/edgetechlabs/fz-iOS-sdk.svg?style=flat)](https://travis-ci.org/edgetechlabs/fz-iOS-sdk)
[![Version](https://img.shields.io/cocoapods/v/fz-iOS-sdk.svg?style=flat)](http://cocoapods.org/pods/fz-iOS-sdk)
[![License](https://img.shields.io/cocoapods/l/fz-iOS-sdk.svg?style=flat)](http://cocoapods.org/pods/fz-iOS-sdk)
[![Platform](https://img.shields.io/cocoapods/p/fz-iOS-sdk.svg?style=flat)](http://cocoapods.org/pods/fz-iOS-sdk)

## Requirements

## Installation

fz-iOS-sdk is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'fz-iOS-sdk'
```
Add "libfz-iOS-sdk.a" file in "Linked Frameworks and Libraries".

For Swift users:
     - Set "Defines Module" to "YES" in "Build Settings" tab after the pod install.

## Usage

While using, a library instance should be created as follows:
```
BlueTooth *mBLEComm;

@interface ViewController : UIViewController
```

The Above created instance can be instantiated in .m file in viewdidload() or wherever needed as follows:

```
mBLEComm = [BlueTooth sharedInstance];

```
There are some delegate methods which can tell us about the various fuctionality which are being performed. We need to add the notification observer for that. Below is the code:

```
- (void) loadNotification
{

[[NSNotificationCenter defaultCenter] addObserver:self
selector:@selector(disconnectedFromDevice:)
name:DisconnectEvent
object:nil];

}

#pragma mark - Notification

- (void) disconnectedFromDevice:(NSNotification*)notification
{
// Called when device gets disconnected
}
```
To scan the device, bluetooth must be switched on.


Following are the steps to initiate scanning and connecting to Fret Zealot:
```
-(void) scanDevices
{
[mBLEComm startScanDevicesWithInterval:2.5 CompleteBlock:^(NSArray *devices)
{
[deviceArray removeAllObjects];
for (CBPeripheral *per in devices)
{
if(![deviceArray containsObject:per])
{
if(per.name.length > 4 && [[per.name substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"Fret"]) // Only shows fret devices
[deviceArray addObject:per];
}
NSLog(@"address %@",[per.identifier UUIDString]);
}

if (deviceArray.count==0) {
NSLog(@"NoDeviceFound");

} else {
// You can show the list in UItable View
}
[deviceTable reloadData];
}];
}
```


And in order to connect to a device, the following method needs to be called:

```
CBPeripheral *device  = [deviceArray objectAtIndex:selectIndex]; // Select from UItableView
NSString* address = [device.identifier UUIDString];
NSString* devName = device.name;

[mBLEComm connectionWithDeviceUUID:address TimeOut:5 CompleteBlock:^(CBPeripheral *device_new, NSError *err)
{
if (device_new)
{
NSLog(@"Discovery servicess...");
[mBLEComm discoverServiceAndCharacteristicWithInterval:3 CompleteBlock:^(NSArray *serviceArray, NSArray *characteristicArray, NSError *err)
{
NSLog(@"Device Connected\n\n");
currentDevceAddress = address;
currentDevceName = devName;

}];
}
else
{
NSLog(@"Connect device failed.");
}

}];
```


Once the instance is ready, we can use the following methods of the library to send commands to Fret Zealot.
All the commands are held in a **command buffer**. This means that the commands are collected into a buffer prior to getting sent. A command buffer can hold a maximum of 5 commands. To insert a command into the buffer, various methods can be called as shown below.


Also, the parameters commonly used are:

**string** - Strings are numbered from the thinnest string (index 0) to the thickest (index 5). The tuning is read from the 5th string to the 0th string: E-A-D-G-B-E. Hence, the string indices would be as follows:
E=5, A=4, D=3, G=2, B=1, E=0

**fret** -  Frets are numbered starting at 0 for the open string. In our case "fret" param has a maximum value of 14.

**red, blue** and **green** - These are the values for the LED color. Possible values for each can be between 0 and 15.

**intensity** - The intensity(brightness) of the LED. Possible values are between 0 and 10.
**fadeMode** - The fade effect with which to light up the LED.
Possible values for **fadeMode** are between 0 and 4.

Fade effect reference chart:
```
Fade Mode Value          Description


0                 Fade not active    //Set Pixel On **Most Common**
1                 Fade in short      //Fade in Pixel over 50ms
2                 Fade in long       //Fade out Pixel over 50ms
3                 Fade out short     //Fade in Pixel over 200ms
4                 Fade out long      //fade out Pixel over 200ms

```
There are several methods for controlling LED state on the fretboard

The `set` method - This method lights up a single LED

```
[mBLEComm set:(int)fret withPixel:(int)string withRed:(int)red Green:(int)green Blue:(int)blue withIntensity:(int)intensity withFade:(int)fadeMode]
```

The `set_across` method - This method lights up all the frets in a string
```
[mBLEComm set_across:(int)string Red:(int)red Green:(int)green Blue:(int)blue withIntensity:(int)intensity withFade:(int)fadeMode];
```

The `set_all` method - This method lights up the whole fretboard with the LED color supplied as arguments.
```
- (void) set_all:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
```

The `set_subset` method - This method lights up a string from a given fret to the 14th fret. For example, if you need to turn on the LEDs from fret 8 to fret 14, this is the method for you. However, the upper limit (14) cannot be changed.
```
- (void) set_subset:(int)Strand_start withPixel:(int)Pixel Red:(int)R Green:(int)G Blue:(int)B withIntensity:(int)intensity withFade:(int)fade;
```

The `clear` method - This method sets each LED on the fretboard to **off**. This counts as one command of the 5 allowed in the **command buffer**
```
- (void) clear;
```

There exist several utility methods for inteacting with the **command buffer**. The **command buffer** holds 5 (five) serialized commands,
and mirrors the size of the Bluetooth MTU. This structure does not need to be initialized.

The `sendCommandClear` method - This method clears the buffer of any existing data, and should be invoked before each write to the fretboard.
```
- (void) sendCommandClear;
```

The `sendCommandFlush` method - This method dumps the contents (up to 5 commands) of the **command buffer** to the BLE device
```
- (void) sendCommandFlush;
```

Commands should be wrapped in these utility commands, to ensure delivery to the Fret Zealot
A typical command to set completely new pixels --  (C) major Triad in Standard Tuning
```
[mBLEComm sendCommandClear]; // Flush the buffer
[mBLEComm clear];           //Clear all displayed Pixels
[mBLEComm sendCommandFlush];  // Write commands to the Fret Zealot

[mBLEComm sendCommandClear];          // Flush the buffer

[mBLEComm set:3 withPixel:4 withRed:0 Green:0 Blue:15 withIntensity:10 withFade:0]; // Set 'C' to blue

[mBLEComm set:2 withPixel:3 withRed:0 Green:15 Blue:0 withIntensity:10 withFade:0]; // Set 'E' to green

[mBLEComm set:0 withPixel:2 withRed:0 Green:0 Blue:15 withIntensity:10 withFade:0]; // Set 'G' to blue

mLib.sendCommandFlush();                // Write commands to the Fret Zealot

```


The `isConnection` method - This method returns boolean value **true** if fretboard is connected with application and **false**
if fretboard is not connected with application.
```
mBLEComm.isConnection

```
<h2>Light Show </h2>
The `set_display` method - This method takes **strand_start**, **Intensity** and **fade_mode** as parameter
and light up on fretboard according to parameter fad value.

**strand_start** :

**intensity** : LED intensity on fretboard

**fade_mode**:
```
fade_mode                      Description

0                                    No lights
1                                    Sparkler
2                                    Bolt
3                                    Rainbow
```
```
strand_start = 4;

// fadValue can be any between 0-3

[mBLEComm sendCommandClear];
[mBLEComm setDisplay:strand_start withIntensity:10 withFade:fadValue];
[mBLEComm sendCommandFlush];
```

## Author

edgetechlabs, john@edgetechlabs.com

## License

fz-iOS-sdk is available under the MIT license. See the LICENSE file for more info.
