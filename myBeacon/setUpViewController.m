//
//  setUpViewController.m
//  myBeacon
//
//  Created by TzeChien Chu on 2013/12/24.
//  Copyright (c) 2013年 TzeChien Chu. All rights reserved.
//

#import "setUpViewController.h"
#import "iBeaconScaner.h"

@interface setUpViewController ()
@property (nonatomic, strong) iBeaconScaner *beaconScaner;
@end

@implementation setUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.beaconScaner = [[iBeaconScaner alloc ] initWithUUID:@"5AFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btnSaveSetting:(id)sender {
}

@end
