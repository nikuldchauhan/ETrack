//
//  ViewController.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URLManager.h"
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController <URLManagerDelegate,UITextFieldDelegate,MFMailComposeViewControllerDelegate>
{
    IBOutlet UITextField *txtUsername;
    IBOutlet UITextField *txtPassword;
    
    IBOutlet UIButton *btnLogin;
    IBOutlet UIImageView *imgLogo;
    
    IBOutlet UIView *loginView;
    IBOutlet UIView *innerView;
    
    IBOutlet UIView *progressView;
    
    //IBOutlet UILabel *lblBottomLabel;
    
    UIAlertView *processAlert;
    int uploadCounter;
    
    NSMutableArray *arrOfflineStorage;
}

@property (nonatomic,strong)UISegmentedControl *segControl;

@end

