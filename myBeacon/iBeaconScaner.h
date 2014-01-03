//
//  iBeaconScaner.h
//  myBeacon
//
//  Created by TzeChien Chu on 2013/12/24.
//  Copyright (c) 2013年 TzeChien Chu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iBeaconActions.h"
#import "iBeaconStates.h"

@import CoreLocation;
@import CoreBluetooth;

@interface iBeaconScaner : NSObject <CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, strong) NSString *kUUID;
@property (nonatomic, strong) NSString *kIdentifier;

@property (nonatomic, strong) NSArray             *detectedBeaconsNow;
@property (nonatomic, strong) NSArray             *detectedBeaconsPrevious;
@property (nonatomic, strong) NSArray             *beaconsDetails;
@property (nonatomic, strong) NSArray             *beaconsAction;
@property (nonatomic, strong) NSMutableDictionary *beaconsState;

@property BOOL rangeOn;

+ (id)sharedInstance;
- (void)stopRangingForBeacons;
- (void)startRangingForBeacons;
@end
