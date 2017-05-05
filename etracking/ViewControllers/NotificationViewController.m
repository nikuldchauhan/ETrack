//
//  NotificationViewController.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import "NotificationViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
#import "Constant.h"

@implementation NotificationViewController

-(void)viewDidLoad
{
    del = [[UIApplication sharedApplication] delegate];
    
    lblTitle.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:18.0];
    lblBottomLabel.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:18.0];
    
    [myTableView setBackgroundColor:[UIColor clearColor]];
    [myTableView setBackgroundView:nil];
    myTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if([UIScreen mainScreen].bounds.size.height<568)
    {
        [myTableView setFrame:CGRectMake(0, 54, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-108)];
        [bgImage setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [bgInnerImage setFrame:CGRectMake(0, 54, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 108)];
        [lblBottomLabel setFrame:CGRectMake(16, [UIScreen mainScreen].bounds.size.height - 40, lblBottomLabel.frame.size.width, lblBottomLabel.frame.size.height)];
    }
    
    [self fetchAllNotifications];
    
    [self setGPSCalls];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkLocationServiceStatus];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"LocationData.plist"];
    
    arrOfflineStorage = [[NSMutableArray alloc]initWithContentsOfFile:plistPath];
    
    NSLog(@"Data Array : %@",arrOfflineStorage);
    
    if(!del.isReachable)
    {
        if([arrOfflineStorage count]>0)
        {
            NSDictionary *dataDic = [arrOfflineStorage objectAtIndex:0];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
            [dateFormat setDateFormat:@"dd-MM-yyyy"];
            NSDate *dt = [NSDate date];
            NSString *dateString = [dateFormat stringFromDate:dt];
            NSLog(@"DateString : %@",dateString);
            
            if(![dateString isEqualToString:[dataDic valueForKey:@"date"]])
            {
                NSMutableArray *blankArray = [arrOfflineStorage mutableCopy];
                [blankArray removeAllObjects];
                
                [blankArray writeToFile:plistPath atomically:YES];
            }
            //If date is not changed, then do nothing...
        }
    }
    else
    {
        if([arrOfflineStorage count]>0)
        {
            processAlert = [[UIAlertView alloc]initWithTitle:@"" message:@"Please wait while location data is uploding on server." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [processAlert show];
            
            [self startUplodingProcessForCounter:uploadCounter=0 ForArray:arrOfflineStorage];
        }
    }
    [myTableView reloadData];
}

-(void)fetchAllNotifications
{
    //fetch all notifications from local storage...
}

-(void)setGPSCalls
{
    NSLog(@"SetGPSCalles called...");
    
    [self startGPSTracking];
    
    [self performSelector:@selector(setGPSCalls) withObject:nil afterDelay:60.0];
}

-(void)startGPSTracking
{
    if(!self.isInBackground)
    {
        if(!self.manager)
        {
            self.manager = [[CLLocationManager alloc]init];
            self.manager.delegate = self;
            self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            self.manager.distanceFilter = 1000.0f;
            self.manager.headingFilter = 5;
           // self.manager.allowsBackgroundLocationUpdates = YES;
            self.manager.pausesLocationUpdatesAutomatically = NO;
        }
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
        {
            [self.manager requestAlwaysAuthorization];
            
            lblBottomLabel.text = @"GPS Tracking is OFF";
        }
        else
        {
            [self.manager startUpdatingLocation];
        }
    }
}

-(IBAction)btnLogoutClicked:(id)sender
{
    self.manager.delegate = nil;
    self.manager = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"" forKey:@"USERID"];
    [defaults setValue:@"" forKey:@"FULLNAME"];
    [defaults setBool:NO forKey:@"isLoggedIn"];
    [defaults synchronize];
    
    ViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    del.window.rootViewController = controller;
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

-(void)startUplodingProcessForCounter:(int)counter ForArray:(NSMutableArray *)dataArray
{
    URLManager *manager = [[URLManager alloc]init];
    manager.delegate = self;
    manager.commandName = @"UploadProcess";
    manager.responseType = JSON_TYPE;
    [manager urlCall:API_SEND_LOCATION_DATA withParameters:[dataArray objectAtIndex:counter]];
}

-(void)sendTrackingDataToServer:(NSDictionary *)dataDic
{
    NSLog(@"Tracking Data : %@",dataDic);
    URLManager *manager = [[URLManager alloc]init];
    manager.delegate = self;
    manager.commandName = @"UploadProcess";
    manager.responseType = JSON_TYPE;
    [manager urlCall:API_SEND_LOCATION_DATA withParameters:(NSMutableDictionary *)dataDic];
}

-(void)checkLocationServiceStatus
{
    if (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        NSLog(@"location services are disabled");
        [self showAlertWithTitle:@"" andMessage:@"Location Services are disabled or blocked. Kindly turn on location services."];
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        NSLog(@"location services are enabled");
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        NSLog(@"about to show a dialog requesting permission");
    }
    
    lblBottomLabel.text = @"GPS Tracking is OFF";
}

#pragma mark -
#pragma mark - URL MANAGER DELEGATE METHODS

-(void)onResult:(NSDictionary *)result
{
    NSString *commandName = [result valueForKey:@"commandName"];
    if([commandName isEqualToString:@"UploadProcess"])
    {
        if(uploadCounter<[arrOfflineStorage count]-1)
        {
            uploadCounter++;
            NSLog(@"Upload counter...%d",uploadCounter);
            [self startUplodingProcessForCounter:uploadCounter ForArray:arrOfflineStorage];
        }
        else
        {
            [processAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
    }
}

-(void)onError:(NSError *)error
{
    NSLog(@"Error : %@",error.description);
}

#pragma mark -
#pragma mark - CLLOCATION MANAGER DELEGATE METHODS

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    lblBottomLabel.text = @"GPS Tracking is ON";
    
    NSLog(@"Locations : %@",locations);
    if(self.isInBackground)
        NSLog(@"App is in background...");
    
    if(!prevLocation)
    {
        prevLocation = [locations lastObject];
    }
    else
    {
        CLLocation *curLocation = [locations lastObject];
        float dis = [prevLocation distanceFromLocation:curLocation];
        NSLog(@"Distance : %f",dis);
        if(dis>=1)
        {
            prevLocation = [locations lastObject];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
            [dateFormat setDateFormat:@"dd-MM-yyyy"];
            NSDate *dt = [NSDate date];
            NSString *dateString = [dateFormat stringFromDate:dt];
            NSLog(@"DateString : %@",dateString);
            
            if(!del.isReachable)
            {
                NSDictionary *dataDic = @{@"longitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.longitude],@"latitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.latitude],@"distance":[NSString stringWithFormat:@"%.2f",dis],@"accuracy":@"10",@"PK_USER_ID":[[NSUserDefaults standardUserDefaults] valueForKey:@"USERID"],@"extrainfo":@"",@"username":[[NSUserDefaults standardUserDefaults] valueForKey:@"FULLNAME"],@"date":dateString,@"direction":@"0",@"phonenumber":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"eventtype":@"ios",@"sessionid":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"speed":@" ",@"locationmethod":@"GPS"};
                [self writeDataToPlistFile:dataDic];
            }
            else
            {
                NSDictionary *dataDic = @{@"longitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.longitude],@"latitude":[NSString stringWithFormat:@"%f",curLocation.coordinate.latitude],@"distance":[NSString stringWithFormat:@"%.2f",dis],@"accuracy":@"10",@"PK_USER_ID":[[NSUserDefaults standardUserDefaults] valueForKey:@"USERID"],@"extrainfo":@"",@"username":[[NSUserDefaults standardUserDefaults] valueForKey:@"FULLNAME"],@"date":dateString,@"direction":@"0",@"phonenumber":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"eventtype":@"ios",@"sessionid":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"],@"speed":@" ",@"locationmethod":@"GPS"};
                [self sendTrackingDataToServer:dataDic];
            }
        }
    }
    [self.manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager did fail with error: %@", error.localizedFailureReason);
    
   // [self checkLocationServiceStatus];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark -
#pragma mark - UITABLEVIEW DATA SOURCE METHODS

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arrOfflineStorage count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell==nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.text = [NSString stringWithFormat:@"Distance:%@, Lat:%f, Lng:%f",[[arrOfflineStorage objectAtIndex:indexPath.row] valueForKey:@"distance"],[[[arrOfflineStorage objectAtIndex:indexPath.row] valueForKey:@"latitude"] floatValue],[[[arrOfflineStorage objectAtIndex:indexPath.row] valueForKey:@"longitude"] floatValue]];
        cell.detailTextLabel.text = @"Notification detail text";
        
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundView:nil];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
