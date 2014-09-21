//
//  NRBeacon.m
//  NRBeacon
//
//  Created by Andy on 20/04/2014.
//  Copyright (c) 2014 niveurosea. All rights reserved.
//

#import "NRBeacon.h"
#import <objc/runtime.h>

@interface NRBeaconLocationManagerDelegate : NSProxy <CLLocationManagerDelegate>

@property (nonatomic, strong) id<CLLocationManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *beacons;
@property (nonatomic, assign) NSUInteger samples;

- (instancetype)init;

@end

@interface CLBeacon (ReadWrite)

@property (readwrite, nonatomic) NSInteger rssi;
@property (readwrite, nonatomic) CLProximity proximity;

@end

@implementation CLBeacon (ReadWrite)

@dynamic rssi;
@dynamic proximity;

- (void)setRssi:(NSInteger)rssi
{
    [self setValue:@(rssi) forKey:@"_rssi"];
}

- (void)setProximity:(CLProximity)proximity
{
    [self setValue:@(proximity) forKey:@"_proximity"];
}

@end

@interface NRBeacon : NSObject

@property (nonatomic, strong, readonly) CLBeacon *beacon;
@property (nonatomic, strong) NSMutableArray *rssiArray;
@property (nonatomic, strong) NSMutableArray *proximityArray;
@property (nonatomic, strong) NSDate *lastSeen;
@property (nonatomic, assign) NSUInteger samples;

- (instancetype)initWithBeacon:(CLBeacon *)beacon;
- (void)addBeacon:(CLBeacon *)beacon;

@end

@implementation NRBeacon
{
    CLBeacon *_newBeacon;
}

@synthesize beacon = _beacon;

- (instancetype)initWithBeacon:(CLBeacon *)beacon
{
    if (self = [self init])
    {
        [self addBeacon:beacon];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.rssiArray = [NSMutableArray new];
        self.proximityArray = [NSMutableArray new];
    }
    return self;
}

- (void)addBeacon:(CLBeacon *)beacon
{
    if (beacon.rssi == 0)
        return;
    if ([self.rssiArray count] > self.samples)
    {
        [self.rssiArray removeObjectAtIndex:0];
        [self.proximityArray removeObjectAtIndex:0];
    }
    _beacon = beacon;
    _newBeacon = nil;
    self.lastSeen = [NSDate new];
    [self.rssiArray addObject:@(beacon.rssi)];
    [self.proximityArray addObject:@(beacon.proximity)];
}

- (CLBeacon *)beacon
{
    if (!_beacon || [[NSDate new] timeIntervalSinceDate:self.lastSeen] > self.samples)
        return nil;
    if (_newBeacon)
        return _newBeacon;
    float rssi = 0;
    float proximity = 0;
    for (NSUInteger idx = 0; idx < [self.rssiArray count]; idx ++)
    {
        rssi += [[self.rssiArray objectAtIndex:idx] integerValue];
        proximity += [[self.proximityArray objectAtIndex:idx] integerValue];
    }
    _beacon.rssi = (NSInteger)round(rssi / [self.rssiArray count]);
    _beacon.proximity = (CLProximity)round(proximity / [self.proximityArray count]);
    _newBeacon = _beacon;
    return _newBeacon;
}

@end

@implementation NRBeaconLocationManager
{
    NRBeaconLocationManagerDelegate *_nrbDelegate;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.samples = 5;
    }
    return self;
}

- (void)setSamples:(NSUInteger)samples
{
    _samples = samples;
    if (_nrbDelegate)
        _nrbDelegate.samples = samples;
}

- (void)setDelegate:(id<CLLocationManagerDelegate>)delegate
{
    if (!_nrbDelegate)
        _nrbDelegate = [NRBeaconLocationManagerDelegate alloc];
    _nrbDelegate.delegate = delegate;
    _nrbDelegate.samples = self.samples;
    super.delegate = _nrbDelegate;
}

@end

#pragma mark - CLLocationManagerDelegate

@implementation NRBeaconLocationManagerDelegate

- (instancetype)init
{
    self.beacons = [NSMutableArray array];
    return self;
}

- (void)setSamples:(NSUInteger)samples
{
    _samples = samples;
    for (NRBeacon *beacon in self.beacons)
        beacon.samples = samples;
}

#pragma mark NSProxy

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    if (class_respondsToSelector(object_getClass(self), invocation.selector))
        [invocation invokeWithTarget:self];
    else
        [invocation invokeWithTarget:self.delegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (class_respondsToSelector(object_getClass(self), sel))
    {
        return [self methodSignatureForSelector:sel];
    }
    if ([self.delegate respondsToSelector:@selector(methodSignatureForSelector:)] && [self.delegate respondsToSelector:sel])
        return [(id)self.delegate methodSignatureForSelector:sel];
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (class_respondsToSelector(object_getClass(self), aSelector))
        return YES;
    else if ([self.delegate respondsToSelector:@selector(respondsToSelector:)])
        return [self.delegate respondsToSelector:aSelector];
    return NO;
}

- (NSMutableArray *)beacons
{
    if (!_beacons)
        _beacons = [NSMutableArray array];
    return _beacons;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSMutableArray *newBeacons = [NSMutableArray new];
    for (CLBeacon *beacon in beacons)
        [self NRBeaconForCLBeacon:beacon];
    for (NRBeacon *beacon in [self.beacons reverseObjectEnumerator])
    {
        CLBeacon *newBeacon = beacon.beacon;
        if (newBeacon)
            [newBeacons addObject:newBeacon];
        else
            [self.beacons removeObject:beacon];
    }
    [self.delegate locationManager:manager didRangeBeacons:[newBeacons copy] inRegion:region];
}

- (NRBeacon *)NRBeaconForCLBeacon:(CLBeacon *)clBeacon
{
    if (!clBeacon)
        return nil;
    NRBeacon *beacon = nil;
    for (NRBeacon *nrBeacon in self.beacons)
    {
        CLBeacon *testCLBeacon = nrBeacon.beacon;
        if (
            [testCLBeacon.major isEqualToNumber:clBeacon.major]
            && [testCLBeacon.minor isEqualToNumber:clBeacon.minor]
            )
        {
            beacon = nrBeacon;
            [beacon addBeacon:clBeacon];
        }
    }
    if (!beacon)
    {
        beacon = [[NRBeacon alloc] initWithBeacon:clBeacon];
        [self.beacons addObject:beacon];
    }
    beacon.samples = self.samples;
    return beacon;
}

@end