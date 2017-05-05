//
//  LocationTracker.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationShareModel.h"
#import "AppDelegate.h"
#import "URLManager.h"

@interface LocationTracker : NSObject <CLLocationManagerDelegate,URLManagerDelegate>
{
    AppDelegate *del;
    
    CLLocation *prevLocation;
}
@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

+ (CLLocationManager *)sharedLocationManager;

- (void)startLocationTracking;
- (void)stopLocationTracking;
- (void)updateLocationToServer;


@end
