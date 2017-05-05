//
//  LocationTracker.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import "LocationTracker.h"
#import <UIKit/UIKit.h>
#import "Constant.h"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@implementation LocationTracker

+ (CLLocationManager *)sharedLocationManager {
	static CLLocationManager *_locationManager;

	@synchronized(self) {
        
		if (_locationManager == nil) {
			_locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
			_locationManager.allowsBackgroundLocationUpdates = YES;
			_locationManager.pausesLocationUpdatesAutomatically = NO;
            _locationManager.distanceFilter = 1000.0f;
            _locationManager.headingFilter = 5;
		}
	}
	return _locationManager;
}

- (id)init {
	if (self==[super init]) {
        
        if(!del)
            del = [[UIApplication sharedApplication] delegate];
        
        //Get the share model and also initialize myLocationArray
        self.shareModel = [LocationShareModel sharedModel];
        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}

-(void)applicationEnterBackground{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
}

- (void) restartLocationUpdates
{
    NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}


- (void)startLocationTracking {
    NSLog(@"startLocationTracking");

	if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
//		UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//		[servicesDisabledAlert show];
	} else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if(IS_OS_8_OR_LATER) {
              [locationManager requestAlwaysAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
	}
}

- (void)stopLocationTracking {
    NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
	CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
	[locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    NSLog(@"locationManager didUpdateLocations");
    del.lblBottom.text = @"GPS Tracking is ON";
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldSendFirstLocation"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldSendFirstLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        prevLocation = [locations lastObject];
        
        [self sendFirstLocationOnServer:[locations lastObject]];
    }
    else
    {
        //for(int i=0;i<locations.count;i++){
            CLLocation * newLocation = [locations lastObject];
            CLLocationCoordinate2D theLocation = newLocation.coordinate;
            CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
            
            NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
            
//            if (locationAge > 30.0)
//            {
//                continue;
//            }
        
            //Select only valid location and also location with good accuracy
//            if(newLocation!=nil&&theAccuracy>0
//               &&theAccuracy<2000
//               &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0)))
            {
                
                self.myLastLocation = theLocation;
                self.myLastLocationAccuracy= theAccuracy;
                
                NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
                [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
                [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
                [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
                [dict setObject:newLocation forKey:@"Location"];
                
                //Add the vallid location with good accuracy into an array
                //Every 1 minute, I will select the best location based on accuracy and send to server
                [self.shareModel.myLocationArray addObject:dict];
            }
        //}
        
        
        
        //If the timer still valid, return it (Will not run the code below)
        if (self.shareModel.timer) {
            return;
        }
        
        self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
        [self.shareModel.bgTask beginNewBackgroundTask];
        
        //Restart the locationMaanger after 1 minute
        int time = [[[NSUserDefaults standardUserDefaults] valueForKey:@"FREQ"] intValue]*60;
        NSLog(@"Time : %d",time);
        self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:time target:self
                                                               selector:@selector(restartLocationUpdates)
                                                               userInfo:nil
                                                                repeats:NO];
        
        //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
        //The location manager will only operate for 10 seconds to save battery
        if (self.shareModel.delay10Seconds) {
            [self.shareModel.delay10Seconds invalidate];
            self.shareModel.delay10Seconds = nil;
        }
        
    //    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    //    [locationManager stopUpdatingLocation];
        
        self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                        selector:@selector(stopLocationDelayBy10Seconds)
                                                        userInfo:nil
                                                         repeats:NO];
    }
}

-(void)sendFirstLocationOnServer:(CLLocation *)location
{
    [del saveLogs:@"Fist location sent on server..."];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    NSDate *dt = [NSDate date];
    NSString *dateString = [dateFormat stringFromDate:dt];
    NSLog(@"DateString : %@",dateString);
    
    NSDictionary *dataDic = @{@"longitude":[NSString stringWithFormat:@"%f",location.coordinate.longitude],@"latitude":[NSString stringWithFormat:@"%f",location.coordinate.latitude],@"DISTANCE":@"0.0",@"ACCURACY":[NSString stringWithFormat:@"%.2f",self.myLocationAccuracy],@"PK_USER_ID":[[NSUserDefaults standardUserDefaults] valueForKey:@"USERID"],@"extrainfo":@"",@"USERNAME":[[NSUserDefaults standardUserDefaults] valueForKey:@"FULLNAME"],@"cdate":[[dateString componentsSeparatedByString:@" "] objectAtIndex:0],@"ctime":[[dateString componentsSeparatedByString:@" "] objectAtIndex:1],@"DIRECTION":@"0",@"PHONENUMBER":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"eventtype":@"ios",@"SESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"speed":@"0",@"LOCATIONMETHOD":@"GPS",@"REGID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"LOGINSESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"LOGINSESSIONID"],@"APPNAME":@"eTrack_Ios"};
    [self sendTrackingDataToServer:dataDic];
}

-(void)writeDataToPlistFile:(NSDictionary *)data
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"LocationData.plist"];
    
    NSMutableArray *dataArray = [[NSMutableArray alloc]initWithContentsOfFile:plistPath];
    
    NSLog(@"Data Array : %@",dataArray);
    
    if(!dataArray)
    {
        dataArray = [[NSMutableArray alloc]init];
    }
    [dataArray addObject:data];
    
    [dataArray writeToFile:plistPath atomically:YES];
}

-(void)sendTrackingDataToServer:(NSDictionary *)dataDic
{
    [del saveLogs:@"Tracking data API called..."];
    
    NSLog(@"Tracking Data : %@",dataDic);
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    URLManager *manager = [[URLManager alloc]init];
    manager.delegate = self;
    manager.commandName = @"UploadData";
    manager.responseType = JSON_TYPE;
//    [manager urlCallGetMethod:API_SEND_LOCATION_DATA withParameters:(NSMutableDictionary *)dataDic];
    [manager urlCall:API_SEND_LOCATION_DATA withJSONString:jsonString];
}

#pragma mark -
#pragma mark - URLMANAGER DELEGATE METHODS

-(void)onResult:(NSDictionary *)result
{
    NSLog(@"Response: %@",result);
    [del saveLogs:[NSString stringWithFormat:@"API Response Received, Response: %@",result]];
}

-(void)onError:(NSError *)error
{
    NSLog(@"Error : %@",error.description);
}

//Stop the locationManager
-(void)stopLocationDelayBy10Seconds{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    NSLog(@"locationManager stop Updating after 10 seconds");
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    del.lblBottom.text = @"GPS Tracking is OFF";
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}

//Send the location to Server
- (void)updateLocationToServer {
    
    NSLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
//    for(int i=0;i<self.shareModel.myLocationArray.count;i++){
//        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
//        
//        if(i==0)
//            myBestLocation = currentLocation;
//        else{
//            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
//                myBestLocation = currentLocation;
//            }
//        }
//    }
    
    myBestLocation = [self.shareModel.myLocationArray lastObject];
    
    NSLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if(self.shareModel.myLocationArray.count==0)
    {
        NSLog(@"Unable to get location, use the last known location");

        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
        
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    if(!prevLocation)
    {
        prevLocation = [myBestLocation valueForKey:@"Location"];
    }
    else
    {
        CLLocation *curLocation = [myBestLocation valueForKey:@"Location"];
        float dis = [prevLocation distanceFromLocation:curLocation];
        NSLog(@"Distance : %f",dis);
        NSLog(@"PrevLocation: %@ --- Current Location:%@",prevLocation,curLocation);
        if(dis>=1000)
        {
            [del saveLogs:[NSString stringWithFormat:@"Distance parameter satisfied... Distance : %.2f",dis]];
            
            prevLocation = curLocation;
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
            NSDate *dt = [NSDate date];
            NSString *dateString = [dateFormat stringFromDate:dt];
            NSLog(@"DateString : %@",dateString);
            
            if(!del.isReachable)
            {
                [del saveLogs:@"Location data saved on disk..."];
                
                NSDictionary *dataDic = @{@"longitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.longitude],@"latitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.latitude],@"DISTANCE":[NSString stringWithFormat:@"%.2f",dis/1000.0],@"ACCURACY":[NSString stringWithFormat:@"%.2f",self.myLocationAccuracy],@"PK_USER_ID":[[NSUserDefaults standardUserDefaults] valueForKey:@"USERID"],@"extrainfo":@"",@"USERNAME":[[NSUserDefaults standardUserDefaults] valueForKey:@"FULLNAME"],@"cdate":[[dateString componentsSeparatedByString:@" "] objectAtIndex:0],@"ctime":[[dateString componentsSeparatedByString:@" "] objectAtIndex:1],@"DIRECTION":@"0",@"PHONENUMBER":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"eventtype":@"ios",@"SESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"speed":@"0",@"LOCATIONMETHOD":@"GPS",@"REGID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"LOGINSESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"LOGINSESSIONID"],@"APPNAME":@"eTrack_Ios"};
                [self writeDataToPlistFile:dataDic];
            }
            else
            {
                [del saveLogs:@"Location data sent on server..."];
                
                NSDictionary *dataDic = @{@"longitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.longitude],@"latitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.latitude],@"DISTANCE":[NSString stringWithFormat:@"%.2f",dis/1000.0],@"ACCURACY":[NSString stringWithFormat:@"%.2f",self.myLocationAccuracy],@"PK_USER_ID":[[NSUserDefaults standardUserDefaults] valueForKey:@"USERID"],@"extrainfo":@"",@"USERNAME":[[NSUserDefaults standardUserDefaults] valueForKey:@"FULLNAME"],@"cdate":[[dateString componentsSeparatedByString:@" "] objectAtIndex:0],@"ctime":[[dateString componentsSeparatedByString:@" "] objectAtIndex:1],@"DIRECTION":@"0",@"PHONENUMBER":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"eventtype":@"ios",@"SESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"speed":@"0",@"LOCATIONMETHOD":@"GPS",@"REGID":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"LOGINSESSIONID":[[NSUserDefaults standardUserDefaults] valueForKey:@"LOGINSESSIONID"],@"APPNAME":@"eTrack_Ios"};
                [self sendTrackingDataToServer:dataDic];
            }
        }
        else
        {
            [del saveLogs:[NSString stringWithFormat:@"Distance parameter is not satisfied... Distance : %.2f",dis]];
        }
    }
    
    NSLog(@"Send to Server: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
    
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
}

@end
