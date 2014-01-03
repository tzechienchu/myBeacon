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

@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
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
    _beaconScaner = [iBeaconScaner sharedInstance];
    _beaconScaner.kUUID = @"5AFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF";
    _beaconScaner.kIdentifier = @"Test";

}
- (IBAction)startRange:(id)sender {
    _startBtn.enabled = NO;
    _stopBtn.enabled = YES;
    [self.beaconScaner startRangingForBeacons];
}
- (IBAction)stopRange:(id)sender {
    _startBtn.enabled = YES;
    _stopBtn.enabled = NO;
    [self.beaconScaner stopRangingForBeacons];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btnSaveSetting:(id)sender {
}

@end
