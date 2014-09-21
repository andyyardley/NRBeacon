//
//  NRBeacon.h
//  NRBeacon
//
//  Created by Andy on 20/04/2014.
//  Copyright (c) 2014 niveurosea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface NRBeaconLocationManager : CLLocationManager

@property (nonatomic, assign) NSUInteger samples;

@end
