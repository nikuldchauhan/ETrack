//
//  NotificationViewController.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "URLManager.h"

@class AppDelegate;

@interface NotificationViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate,URLManagerDelegate>
{
    IBOutlet UITableView *myTableView;
    
    IBOutlet UILabel *lblTitle;
    IBOutlet UILabel *lblBottomLabel;
    
    IBOutlet UIImageView *bgImage;
    IBOutlet UIImageView *bgInnerImage;
    
    CLLocation *prevLocation;
    UIAlertView *processAlert;
    
    AppDelegate *del;
    
    int uploadCounter;
    
    NSMutableArray *arrOfflineStorage;
}

@property (nonatomic,assign) BOOL isInBackground;
@property (nonatomic,strong)CLLocationManager *manager;

-(void)setGPSCalls;

@end
