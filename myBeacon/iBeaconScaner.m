//
//  iBeaconScaner.m
//  myBeacon
//
//  Created by Nick Toumpelis on 2013-10-06.
//  Copyright (c) 2013 Nick Toumpelis.
//
//  Created by TzeChien Chu on 2013/12/24.
//  Copyright (c) 2013年 TzeChien Chu. All rights reserved.
//

#import "iBeaconScaner.h"

@interface iBeaconScaner ()
@property (nonatomic, strong) CLLocationManager   *locationManager;
@property (nonatomic, strong) CLBeaconRegion      *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

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

+ (id)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[iBeaconScaner alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Beacon ranging
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:self.kUUID];
    //self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:self.kIdentifier];
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:self.kIdentifier];
    _beaconRegion.notifyOnEntry = YES;
    _beaconRegion.notifyOnExit = YES;
    _beaconRegion.notifyEntryStateOnDisplay = YES;
    
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
    
    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
    [_locationManager startMonitoringForRegion:_beaconRegion];
    //[self.locationManager requestStateForRegion:self.beaconRegion];
    
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
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    _detectedBeaconsNow = [NSArray array];
    _detectedBeaconsPrevious = [NSArray array];
    _beaconsState = [NSMutableDictionary dictionaryWithCapacity:10];
    
    [self setUpBeaconsActions];
    
    [self turnOnRanging];
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
//    NSIndexSet *deletedSections = [self deletedSections];
//    self.detectedBeacons = [NSArray array];
//    
//
//    [self.beaconTableView beginUpdates];
//    if (deletedSections) {
//        [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
//    }
//    [self.beaconTableView endUpdates];
 
    NSLog(@"Turned off ranging.");
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

#pragma mark - Beacon Parsing

- (NSArray *)parseBeacons:(NSArray *)beacons
{
    NSMutableArray *details = [NSMutableArray arrayWithCapacity:10];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *detail = [self detailsStringForBeacon:curr];
        //NSLog(@"%@",detail);
        [details addObject:detail];
    }
    return [details copy];
}

- (NSArray *)parseBeaconsChange:(NSArray *)beaconsNow andPreviousBeacons:(NSArray *)beaconsPrevious
{
    if ([beaconsNow count] == 0) return nil;
    if ([beaconsPrevious count] == 0) return nil;
    
    NSMutableArray *details = [NSMutableArray arrayWithCapacity:10];
    for (int index = 0; index < [beaconsNow count]; index++) {
        CLBeacon *curr1 = [beaconsNow      objectAtIndex:index];
        for(int index2 = 0; index2 <[beaconsPrevious count];index2++) {
            CLBeacon *curr2 = [beaconsPrevious objectAtIndex:index2];
            if ([curr1.major isEqualToNumber:curr2.major] && [curr1.minor isEqualToNumber:curr2.minor]) {
                NSString *detail = [self changesForBeaconsNow:curr1 andBeaconsPrevious:curr2];
                NSLog(@"%@",detail);
                [details addObject:detail];
                continue;
            } else {
                //NSLog(@"%@ - %@ // %@ - %@ ",curr1.major,curr2.major,curr1.minor,curr2.minor);
            }
        }
    }
    return [details copy];
}
- (void)updateBeaconState:(NSArray *)beaconsNow
{
    for(CLBeacon *bp in beaconsNow) {
        NSString *bpdist = [self getProximityFromBeacon:bp];
        NSString *bpid = [NSString stringWithFormat:@"%@",bp.minor];
        iBeaconStates *mybps = [_beaconsState objectForKey:bpid];
        if (mybps) {
            [mybps insertDistanceWithKey:bpid andBeacon:bpdist];
            NSLog(@"%@ %@",bp.minor,mybps.beaconState);
        } else {
            iBeaconStates *bs = [[iBeaconStates alloc] init];
            bs = [bs initBeaconStateWithKey:bpid andBeacon:bpdist];
            [_beaconsState setObject:bs forKey:bpid];
        }
    }
}
- (NSString *)getProximityFromBeacon:(CLBeacon *)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"Unknown";
            break;
    }
    return [proximity copy];
}

- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
{
    NSString *proximity;
    proximity = [self getProximityFromBeacon:beacon];
    NSString *format = @"%@, %@ • %@ • %.2fm • %li";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi];
}

- (NSString *)changesForBeaconsNow:(CLBeacon *)beaconNow andBeaconsPrevious:(CLBeacon *)beaconPrevious
{
    NSString *proximityNow;
    NSString *proximityPrevious;
    proximityNow      = [self getProximityFromBeacon:beaconNow];
    proximityPrevious = [self getProximityFromBeacon:beaconPrevious];
    
    NSString *format = @"%@, %@ -> %@";
    return [NSString stringWithFormat:format, beaconNow.minor, proximityPrevious, proximityNow];
}

#pragma mark - Beacon Actions

- (void)setUpBeaconsActions
{

    iBeaconActions *myBeacon1 = [[iBeaconActions alloc] init];
    myBeacon1.beaconID = @"4098";//4102
    myBeacon1.beaconState = @"Enter";//Leave
    myBeacon1.triggerMode = @"Once";
    myBeacon1.actionCommand = @"Show URL";
    myBeacon1.actionParameters = @"www.apple.com";
    
    iBeaconActions *myBeacon2 = [[iBeaconActions alloc] init];
    myBeacon2.beaconID = @"4102";//4102
    myBeacon2.beaconState = @"Leave";//Leave
    myBeacon2.triggerMode = @"Always";
    myBeacon2.actionCommand = @"Show Image";
    myBeacon2.actionParameters = @"Pigs";

    _beaconsAction = [NSArray arrayWithObjects:myBeacon1,myBeacon2, nil];
    
}

- (iBeaconActions *)getActionWithBeaconID:(NSString *)beaconID andState:(NSString *)beaconState
{
    for(iBeaconActions *ba in _beaconsAction) {
        if ([ba.beaconID isEqualToString:beaconID] && [ba.beaconState isEqualToString:beaconState]) {
            return ba;
        }
    }
    return nil;
}

//Only State Change We will find Actions.
- (void)checkActionsWithBeacons:(NSArray *)beacons
{
    iBeaconActions *ba;
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *bpid = [NSString stringWithFormat:@"%@",curr.minor];
        iBeaconStates *bpst = [_beaconsState objectForKey:bpid];
        
        ba = [self getActionWithBeaconID:bpid andState:bpst.beaconState];
        NSLog(@"%@ %@",ba.actionCommand,ba.actionStatus);
    }
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
    
    self.detectedBeaconsPrevious = [_detectedBeaconsNow copy];
    self.detectedBeaconsNow = filteredBeacons;
    
    self.beaconsDetails = [self parseBeacons:filteredBeacons];
    [self updateBeaconState:_detectedBeaconsNow];
    [self checkActionsWithBeacons:_detectedBeaconsNow];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateBeacon" object:nil];
    

}
/*

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.userInfo = @{@"uuid": @"1234"};
        notification.alertBody = [NSString stringWithFormat:@"Smell that? Looks like you're near %@!", @"ABCD"];
        notification.soundName = @"Default";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidEnterRegion" object:self userInfo:@{@"restaurant": @"1234"}];

    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.userInfo = @{@"uuid": @"789"};
        notification.alertBody = [NSString stringWithFormat:@"Smell that? Looks like you're near %@!", @"ABCD"];
        notification.soundName = @"Default";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidEnterRegion" object:self userInfo:@{@"restaurant": @"789"}];

    }
}

//Generate Local Notification
-(void)generateNotification
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.alertBody = @"Got it";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
}
*/

@end
