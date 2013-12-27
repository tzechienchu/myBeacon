//
//  iBeaconScaner.m
//  myBeacon
//
//  Created by TzeChien Chu on 2013/12/24.
//  Copyright (c) 2013年 TzeChien Chu. All rights reserved.
//

#import "iBeaconScaner.h"

@interface iBeaconScaner ()
@property (nonatomic, strong) CLLocationManager   *locationManager;
@property (nonatomic, strong) CLBeaconRegion      *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray             *detectedBeacons;

@property (nonatomic, strong) NSString *kUUID;
@property (nonatomic, strong) NSString *kIdentifier;
@property BOOL rangeOn;

@end

typedef NS_ENUM(NSUInteger, NTSectionType) {
    NTOperationsSection,
    NTDetectedBeaconsSection
};

typedef NS_ENUM(NSUInteger, NTOperationsRow) {
    NTAdvertisingRow,
    NTRangingRow
};

@implementation iBeaconScaner

- (id) initWithUUID:(NSString *)UUID
{
    if (!(self = [super init])) {
        return nil;
    }
    self.kUUID = [NSString stringWithString:UUID];
    [self changeRangingState:YES];
    return self;
}

#pragma mark - Beacon ranging
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:self.kUUID];
    //self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:self.kIdentifier];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"Test"];
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        //self.rangingSwitch.on = NO;
        self.rangeOn = NO;
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)changeRangingState:(BOOL)state
{
    self.rangeOn = state;
    if (self.rangeOn) {
        [self startRangingForBeacons];
    } else {
        [self stopRangingForBeacons];
    }
}

- (void)startRangingForBeacons
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.detectedBeacons = [NSArray array];
    
    [self turnOnRanging];
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    NSIndexSet *deletedSections = [self deletedSections];
    self.detectedBeacons = [NSArray array];
    
/*
    [self.beaconTableView beginUpdates];
    if (deletedSections) {
        [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.beaconTableView endUpdates];
*/
    NSLog(@"Turned off ranging.");
}

#pragma mark - Index path management
- (NSArray *)indexPathsOfRemovedBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (CLBeacon *existingBeacon in self.detectedBeacons) {
        BOOL stillExists = NO;
        for (CLBeacon *beacon in beacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                stillExists = YES;
                break;
            }
        }
        if (!stillExists) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
        }
        row++;
    }
    
    return indexPaths;
}

- (NSArray *)indexPathsOfInsertedBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (CLBeacon *beacon in beacons) {
        BOOL isNewBeacon = YES;
        for (CLBeacon *existingBeacon in self.detectedBeacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                isNewBeacon = NO;
                break;
            }
        }
        if (isNewBeacon) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
        }
        row++;
    }
    
    return indexPaths;
}

- (NSArray *)indexPathsForBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger row = 0; row < beacons.count; row++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
    }
    
    return indexPaths;
}

- (NSIndexSet *)insertedSections
{
    if (self.rangeOn) {
        return [NSIndexSet indexSetWithIndex:1];
    } else {
        return nil;
    }
}

- (NSIndexSet *)deletedSections
{
    if (!self.rangeOn) {
        return [NSIndexSet indexSetWithIndex:1];
    } else {
        return nil;
    }
}

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

#pragma mark - Beacon ranging delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
        self.rangeOn = NO;
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on ranging: Location services not authorised.");
        self.rangeOn = NO;
        return;
    }
    
    self.rangeOn = YES;
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found %lu %@.", (unsigned long)[filteredBeacons count],
              [filteredBeacons count] > 1 ? @"beacons" : @"beacon");
    }
    
//    NSIndexSet *insertedSections = [self insertedSections];
//    NSIndexSet *deletedSections = [self deletedSections];
//    NSArray *deletedRows = [self indexPathsOfRemovedBeacons:filteredBeacons];
//    NSArray *insertedRows = [self indexPathsOfInsertedBeacons:filteredBeacons];
//    NSArray *reloadedRows = nil;
//    if (!deletedRows && !insertedRows)
//        reloadedRows = [self indexPathsForBeacons:filteredBeacons];
    
    self.detectedBeacons = filteredBeacons;
    
}

@end
