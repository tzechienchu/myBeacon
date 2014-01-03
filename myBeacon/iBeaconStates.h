//
//  iBeaconStates.h
//  myBeacon
//
//  Created by TzeChien Chu on 2014/1/2.
//  Copyright (c) 2014年 TzeChien Chu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iBeaconStates : NSObject

@property (nonatomic,strong) NSMutableArray  *storage;
@property (nonatomic,strong) NSString *beaconState;

- (id)initBeaconStateWithKey:(NSString *)key andBeacon:(NSString *)beaconDistance;
-(void)insertDistanceWithKey:(NSString *)key andBeacon:(NSString *)beaconDistance;

@end
