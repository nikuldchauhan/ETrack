//
//  NotificationController.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import "NotificationController.h"
#import "AppDelegate.h"
#import "Constant.h"
#import "ViewController.h"
#import "NotificationCustomCell.h"


@implementation NotificationController

-(void)viewDidLoad
{
    del = [[UIApplication sharedApplication] delegate];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    processAlert = [[UIAlertView alloc]initWithTitle:@"" message:@"Please wait while location data is uploding on server." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    lblTitle.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:18.0];
    lblBottomLabel.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:18.0];
    NSLog(@"Nikul");
    [myTableView setBackgroundColor:[UIColor clearColor]];
    [myTableView setBackgroundView:nil];
    myTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    myTableView.rowHeight = 95.0;
    
    if([UIScreen mainScreen].bounds.size.height<568)
    {
        [myTableView setFrame:CGRectMake(0, 54, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-108)];
        [bgImage setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [bgInnerImage setFrame:CGRectMake(0, 54, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 108)];
        [lblBottomLabel setFrame:CGRectMake(16, [UIScreen mainScreen].bounds.size.height - 40, lblBottomLabel.frame.size.width, lblBottomLabel.frame.size.height)];
    }
    
    [del saveLogs:@"Notification Controller view did load called..."];
    
    del.lblBottom = lblBottomLabel;
    
    UIAlertView * alert;
    
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        
        self.locationTracker = [[LocationTracker alloc]init];
        [self.locationTracker startLocationTracking];
        
        //Send the best location to server every 60 seconds
        //You may adjust the time interval depends on the need of your app.
        NSTimeInterval time = [[[NSUserDefaults standardUserDefaults] valueForKey:@"FREQ"] intValue]*60.0;
        
        NSLog(@"FREQ : %d",[[[NSUserDefaults standardUserDefaults] valueForKey:@"FREQ"] intValue]);
        NSLog(@"Nikul");
        NSLog(@"Time : %f",time);
        self.locationUpdateTimer =
        [NSTimer scheduledTimerWithTimeInterval:time
                                         target:self
                                       selector:@selector(updateLocation)
                                       userInfo:nil
                                        repeats:YES];
        lblBottomLabel.text = @"GPS Tracking is ON";
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSignificantTimeChange:)
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
    
    NSLog(@"View Will Appear...");
    
    [del saveLogs:@"Notification controller view will appear called..."];
    
    [self checkLocationServiceStatus];
    
    NSArray *tempArray = [[NSUserDefaults standardUserDefaults] valueForKey:@"NotificationData"];
 
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"NotificationDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    notificationData = [tempArray sortedArrayUsingDescriptors:sortDescriptors];
    
    NSLog(@"Sorted Array : %@",notificationData);
    
    if([notificationData count]>0)
    {
        [myTableView reloadData];
    }
}

-(void)checkLocalStoageData
{
    [del saveLogs:@"Check local storage data"];
    NSLog(@"22121212");
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"LocationData.plist"];
    
    arrOfflineStorage = [[NSMutableArray alloc]initWithContentsOfFile:plistPath];
    
    NSLog(@"Data Array From Controller: %@",arrOfflineStorage);
    
    if(!del.isReachable)
    {
        
    }
    else
    {
        NSLog(@"Reachable.... Else....");
        if([arrOfflineStorage count]>0)
        {
            [processAlert show];
            
            [self startUplodingProcessForCounter:uploadCounter=0 ForArray:arrOfflineStorage];
        }
    }
    [myTableView reloadData];
}

-(void)startUplodingProcessForCounter:(int)counter ForArray:(NSMutableArray *)dataArray
{
    [del saveLogs:[NSString stringWithFormat:@"Upload local data on server : Counter = %d",counter]];
    
    URLManager *manager = [[URLManager alloc]init];
    manager.delegate = self;
    manager.commandName = @"UploadProcess";
    manager.responseType = JSON_TYPE;
    [manager urlCallGetMethod:API_SEND_LOCATION_DATA withParameters:[dataArray objectAtIndex:counter]];
}

- (void)onSignificantTimeChange:(NSNotification *)notification {
    NSLog(@"Significant Time Change called...");
    
    [del saveLogs:@"Significant time change called..."];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"dd-MM-yyyy"];
    NSDate *date = [NSDate date];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    
    if(![dateString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:@"dateChange"]] && state == UIApplicationStateActive)
    {
        [del saveLogs:@"Significant time change inside if condition..."];
        NSLog(@"Nikul");
        [self btnLogoutClicked:nil];
    }
    else
    {
        [del saveLogs:@"Significant time change inside else condition..."];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:dateString forKey:@"dateChange"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)checkLocationServiceStatus
{
    [del saveLogs:@"Location service status method called..."];
    
    NSLog(@"Check Location Service Status...");
    
    if (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        NSLog(@"location services are disabled");
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        lblBottomLabel.text = @"GPS Tracking is OFF";
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        NSLog(@"location services are enabled");
        lblBottomLabel.text = @"GPS Tracking is ON";
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        NSLog(@"about to show a dialog requesting permission");
        lblBottomLabel.text = @"GPS Tracking is OFF";
    }
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(IBAction)btnLogoutClicked:(id)sender
{
    [del saveLogs:@"Logout method called..."];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"" forKey:@"USERID"];
    [defaults setValue:@"" forKey:@"FULLNAME"];
    [defaults setBool:NO forKey:@"isLoggedIn"];
    [defaults synchronize];
    
    [self.locationTracker stopLocationTracking];
    self.locationTracker = nil;
    
    [del saveLogs:@"Location stop..."];
    NSLog(@"Nikul11111111");
    ViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:controller];
    navController.navigationBar.hidden = YES;
    del.window.rootViewController = navController;
    
    [del saveLogs:@"Push the login controller..."];
}

-(void)updateLocation {
    NSLog(@"updateLocation");
    NSLog(@"Nikul");
    [self.locationTracker updateLocationToServer];
}

-(IBAction)sendEmail
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *txtFilePath = [documentsDirectory stringByAppendingPathComponent:@"logFile.txt"];
    NSData *noteData = [NSData dataWithContentsOfFile:txtFilePath];
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"LogFile"];
    [controller setMessageBody:@"Hello This is log attachment email." isHTML:NO];
    [controller addAttachmentData:noteData mimeType:@"text/plain" fileName:@"logFile.txt"];
    
    if (controller)
    {
        [self presentViewController:controller animated:YES completion:^{}];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

/*
-(void)startUplodingProcessForCounter:(int)counter ForArray:(NSMutableArray *)dataArray
{
    URLManager *manager = [[URLManager alloc]init];
    manager.delegate = self;
    manager.commandName = @"UploadProcess";
    manager.responseType = JSON_TYPE;
    [manager urlCall:API_SEND_LOCATION_DATA withParameters:[dataArray objectAtIndex:counter]];
}
*/
#pragma mark -
#pragma mark - URL MANAGER DELEGATE METHODS

-(void)onResult:(NSDictionary *)result
{
    NSString *commandName = [result valueForKey:@"commandName"];
    
    [del saveLogs:[NSString stringWithFormat:@"Response received : %@",result]];
    
    if([commandName isEqualToString:@"UploadProcess"])
    {
        if(uploadCounter<[arrOfflineStorage count]-1)
        {
            if(del.isReachable)
            {
                uploadCounter++;
                NSLog(@"Upload counter...%d",uploadCounter);
                [self startUplodingProcessForCounter:uploadCounter ForArray:arrOfflineStorage];
            }
            else
            {
                uploadCounter = 0;
                [processAlert dismissWithClickedButtonIndex:0 animated:YES];
            }
        }
        else
        {
            [del saveLogs:@"Location data finished to upload..."];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"LocationData.plist"];
            NSMutableArray *blankArray = [arrOfflineStorage mutableCopy];
            [blankArray removeAllObjects];
            
            [blankArray writeToFile:plistPath atomically:YES];
            
            uploadCounter = 0;
            
            [processAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
    }
}

-(void)onError:(NSError *)error
{
    NSLog(@"Error : %@",error.description);
}

#pragma mark -
#pragma mark - UITABLEVIEW DATA SOURCE METHODS

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [del saveLogs:[NSString stringWithFormat:@"numberOfSectionsInTableView method called and sections are : %lu",(unsigned long)[notificationData count]]];
    return [notificationData count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [del saveLogs:[NSString stringWithFormat:@"numberOfRowsInSection, rows are : %lu",[[[notificationData objectAtIndex:section] valueForKey:@"Data"] count]]];
    return [[[notificationData objectAtIndex:section] valueForKey:@"Data"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    [del saveLogs:@"heightForHeaderInSection : 35.0"];
    return 35.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    [del saveLogs:@"viewForHeaderInSection method called..."];
    
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 35)];
    [headerView setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:174.0/255.0 blue:239.0/255.0 alpha:1.0]];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *dt = [dateFormat dateFromString:[[notificationData objectAtIndex:section] valueForKey:@"Title"]];
    [dateFormat setDateFormat:@"dd-MM-yyyy"];
    
    NSString *dateString = [dateFormat stringFromDate:dt];
    NSLog(@"111 Date String: %@",dateString);
    
    
    UILabel *lblHeaderTitle = [[UILabel alloc]initWithFrame:headerView.frame];
    lblHeaderTitle.text = dateString;//[[notificationData objectAtIndex:section] valueForKey:@"Title"];
    lblHeaderTitle.textAlignment = NSTextAlignmentCenter;
    lblHeaderTitle.textColor = [UIColor whiteColor];
    lblHeaderTitle.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:16.0];
    [headerView addSubview:lblHeaderTitle];
    
    return headerView;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [del saveLogs:@"cellForRowAtIndexPath method called..."];
    
    static NSString *cellIdentifier = @"CellIdentifier";
    NotificationCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell==nil)
    {
        cell = (NotificationCustomCell *)[[[NSBundle mainBundle] loadNibNamed:@"NotificationCustomCell" owner:self options:nil] objectAtIndex:0];
        
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundView:nil];
    }
    
    NSString *jsonString = [[[[notificationData objectAtIndex:indexPath.section] valueForKey:@"Data"] objectAtIndex:indexPath.row] valueForKey:@"message"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSLog(@"JSON Dic : %@",dataDic);
    
    cell.lblTitle.text = [dataDic valueForKey:@"title"];
    cell.lblDescription.text = [dataDic valueForKey:@"description"];
    
    NSString *dateString = [NSString stringWithFormat:@"%@ %@",[dataDic valueForKey:@"date"],[dataDic valueForKey:@"time"]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dt = [dateFormat dateFromString:dateString];
    NSLog(@"Date: %@",dt);
    [dateFormat setDateFormat:@"dd-MM-yyyy h:mm:ss a"];
    dateString = [dateFormat stringFromDate:dt];

    
    cell.lblDate.text = dateString;
    
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
