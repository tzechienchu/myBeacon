//
//  iBeaconStates.m
//  myBeacon
//
//  Created by TzeChien Chu on 2014/1/2.
//  Copyright (c) 2014年 TzeChien Chu. All rights reserved.
//

#import "iBeaconStates.h"
#define kQUEUSIZE 4
#define kSTATELEN 4

@interface iBeaconStates()
@property (nonatomic,strong) NSString *keyID;
//@property (nonatomic,strong) NSMutableArray  *storage;
@end

@implementation iBeaconStates

- (id)initBeaconStateWithKey:(NSString *)key andBeacon:(NSString *)beaconDistance
{
    if (self = [super init]) {
        _keyID = [NSString stringWithString:key];
        _storage = [NSMutableArray arrayWithCapacity:4];
    
        [_storage addObject:beaconDistance];
    }
    return self;
}

-(NSString *)updateBeaconState
{
    NSString *pre = [_beaconState copy];
    BOOL stateChange = NO;
    NSString *st0,*st1,*st2,*st3;
    if ([_storage count] >= kSTATELEN) {
        st0 = [_storage objectAtIndex:0];
        st1 = [_storage objectAtIndex:1];
        st2 = [_storage objectAtIndex:2];
        st3 = [_storage objectAtIndex:3];
        if ([st0 isEqualToString: st1] && [st2 isEqualToString:st3] && ![st1 isEqualToString:st2]) {
            stateChange = YES;
        }
        if (stateChange) {
            if ([st2 isEqualToString:@"Immediate"]) return @"Enter";
            if ([st2 isEqualToString:@"Near"] && ![pre isEqualToString:@"In"]) return @"Enter";
            if ([st2 isEqualToString:@"Far"])  return @"Leave";
        }
        if ([st2 isEqualToString:st3] && [st1 isEqualToString:st2]) {
            if ([st3 isEqualToString:@"Immediate"]) return @"In";
            if ([st3 isEqualToString:@"Near"]) return @"In";
            if ([st3 isEqualToString:@"Far"])  return @"Out";
        }

    }
    if ([pre isEqualToString:@"Enter"]) return @"In";
    if ([pre isEqualToString:@"Leave"]) return @"Out";
    return [pre copy];
}
-(void)insertDistanceWithKey:(NSString *)key andBeacon:(NSString *)beaconDistance
{
    if ([_keyID isEqualToString:key]) {
        if ([beaconDistance isEqualToString:@"Unknown"]) {
           [_storage addObject:[_storage lastObject]];
        } else {
           [_storage addObject:beaconDistance];
        }
    }
    if ([_storage count] > kQUEUSIZE) {
        [_storage removeObjectAtIndex:0];
    }
    if ([_storage count] >= kQUEUSIZE) {
        _beaconState = [self updateBeaconState];
    }
}
@end

/*
 //Test
 iBeaconStates *bs = [[iBeaconStates alloc] init];
 [bs initBeaconStateWithKey:@123 andBeacon:@"Far"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Far"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Far"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Near"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Near"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Far"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Unknown"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Unknown"];
 [bs insertDistanceWithKey:@123 andBeacon:@"Near"];
*/