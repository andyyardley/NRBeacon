//
//  NRBViewController.m
//  NRBeacon
//
//  Created by Andy on 20/04/2014.
//  Copyright (c) 2014 niveurosea. All rights reserved.
//

#import "NRBViewController.h"
#import "NRBeacon.h"
#import <CoreLocation/CoreLocation.h>

NSString *const NRBPaymentTerminalUUID = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
NSString *const NRBBluetoothServiceIdentifier = @"NRBBeacon";
NSString *const NRBTableViewCellIdentifier = @"Cell";

@interface NRBViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) NRBeaconLocationManager *locationManager;
@property (nonatomic, strong) NSArray *beacons;

@end

@implementation NRBViewController

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
    // Do any additional setup after loading the view from its nib.
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:NRBPaymentTerminalUUID];
    
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                           identifier:NRBBluetoothServiceIdentifier];
    
    self.locationManager = [[NRBeaconLocationManager alloc] init];
    self.locationManager.samples = 3;
    self.locationManager.delegate = self;
    
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NRBTableViewCellIdentifier];
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    NSLog(@"Beacon region entered");
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    self.beacons = beacons;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NRBTableViewCellIdentifier];
    CLBeacon *beacon = self.beacons[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)beacon.rssi];
    return cell;
}

@end
