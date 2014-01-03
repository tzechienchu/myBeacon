//
//  iBeaconActions.h
//  myBeacon
//
//  Created by TzeChien Chu on 2014/1/2.
//  Copyright (c) 2014年 TzeChien Chu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iBeaconActions : NSObject

@property (nonatomic,strong) NSString *beaconID;
@property (nonatomic,strong) NSString *beaconState;
@property (nonatomic,strong) NSString *triggerMode;
@property (nonatomic,strong) NSString *actionCommand;
@property (nonatomic,strong) NSString *actionParameters;
@property (nonatomic,strong) NSString *actionStatus;

@end
