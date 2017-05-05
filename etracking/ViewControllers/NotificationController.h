//
//  NotificationController.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "URLManager.h"
#import "LocationTracker.h"
#import <MessageUI/MessageUI.h>

@class AppDelegate;

@interface NotificationController : UIViewController<URLManagerDelegate,UITableViewDelegate,UITableViewDataSource,MFMailComposeViewControllerDelegate>
{
    IBOutlet UITableView *myTableView;
    
    IBOutlet UILabel *lblTitle;
    IBOutlet UILabel *lblBottomLabel;
    
    IBOutlet UIImageView *bgImage;
    IBOutlet UIImageView *bgInnerImage;
    
    UIAlertView *processAlert;
    
    AppDelegate *del;
    
    int uploadCounter;
    
    NSMutableArray *arrOfflineStorage;
    NSArray *notificationData;
}

@property LocationTracker * locationTracker;
@property (nonatomic) NSTimer* locationUpdateTimer;

-(void)checkLocalStoageData;

@end
