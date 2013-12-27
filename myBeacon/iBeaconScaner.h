//
//  iBeaconScaner.h
//  myBeacon
//
//  Created by TzeChien Chu on 2013/12/24.
//  Copyright (c) 2013年 TzeChien Chu. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;
@import CoreBluetooth;

@interface iBeaconScaner : NSObject

- (id) initWithUUID:(NSString *)UUID;

@end
