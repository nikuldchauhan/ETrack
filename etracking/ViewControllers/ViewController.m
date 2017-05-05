//
//  ViewController.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import "ViewController.h"
#import "Constant.h"
#import "NotificationViewController.h"
#import "AppDelegate.h"
#import "NotificationController.h"

@interface ViewController ()
{
    AppDelegate *del;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    del = [[UIApplication sharedApplication] delegate];
    
    [progressView.layer setCornerRadius:15.0];
    
    //lblBottomLabel.font = [UIFont fontWithName:@"Geometr212 BKcn BT" size:18.0];
    
    [self performSelector:@selector(layoutControls) withObject:nil afterDelay:0.01];
    
    [del saveLogs:@"Login Controller loaded..."];
    NSLog(@"Nikul");
    [self performSelector:@selector(checkConnection) withObject:nil afterDelay:1.0];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkLocalStoageData];
}

-(void)checkConnection
{
    if(!del.isReachable)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"No Internet connection available. Please check your Internet connection." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}

- (UIToolbar *)keyboardToolBar {
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    self.segControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
    [self.segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    self.segControl.momentary = YES;
    
    [self.segControl addTarget:self action:@selector(changeRow:) forControlEvents:(UIControlEventValueChanged)];
    [self.segControl setEnabled:NO forSegmentAtIndex:0];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithCustomView:self.segControl];
    
    NSArray *itemsArray = @[nextButton];
    
    [toolbar setItems:itemsArray];
    
    return toolbar;
}

- (void)changeRow:(id)sender {
    
    int idx = (int)[sender selectedSegmentIndex];
    
    if (idx) {
        
        [txtPassword becomeFirstResponder];
        NSLog(@"1");
    }
    else {
        
        [txtUsername becomeFirstResponder];
    }
}

-(void)layoutControls
{
    [btnLogin setFrame:CGRectMake(btnLogin.frame.origin.x, imgLogo.frame.origin.y+imgLogo.frame.size.height, btnLogin.frame.size.width, btnLogin.frame.size.height)];
    if([UIScreen mainScreen].bounds.size.height>568)
    {
        [innerView setFrame:CGRectMake(innerView.frame.origin.x, btnLogin.frame.origin.y - innerView.frame.size.height - 60, innerView.frame.size.width, innerView.frame.size.height)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)checkLocalStoageData
{
    [del saveLogs:@"Check local storage data"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"LocationData.plist"];
    
    arrOfflineStorage = [[NSMutableArray alloc]initWithContentsOfFile:plistPath];
    
    NSLog(@"Data Array From Controller: %@",arrOfflineStorage);
    NSLog(@"Hi");
    if(!del.isReachable)
    {
        
    }
    else
    {
        NSLog(@"Reachable.... Else....");
        if([arrOfflineStorage count]>0)
        {
            processAlert = [[UIAlertView alloc]initWithTitle:@"" message:@"Please wait while location data is uploding on server." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [processAlert show];
            
            [self startUplodingProcessForCounter:uploadCounter=0 ForArray:arrOfflineStorage];
        }
    }
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

#pragma mark -
#pragma mark - BUTTON ACTIONS

-(IBAction)btnLoginClicked:(id)sender
{
    //Perform credentials verification
    
    [del saveLogs:@"Login Button Tapped...."];
    
    if(![self isNull:txtUsername.text] && ![self isNull:txtPassword.text])
    {
        //Call Login API here...
        
        [del saveLogs:@"Validation verified..."];
        
        if(del.isReachable)
        {
            [del saveLogs:@"Internet available..."];
            
            progressView.hidden = NO;
            self.view.userInteractionEnabled = NO;
            
            NSDictionary *paramDic = @{@"postCase":@"login",@"userName":txtUsername.text,@"passWord":txtPassword.text,@"appName":@"eTrack_Ios",@"deviceId":[[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICETOKEN"]};
            
            
            [del saveLogs:[NSString stringWithFormat:@"Parameters Built: %@",paramDic]];
            
            NSDictionary *postDic = @{@"postData":paramDic};
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:nil];
            NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"JSON String: %@",jsonString);
            
            NSLog(@"Params : %@",paramDic);
            URLManager *manager = [[URLManager alloc]init];
            manager.commandName = @"LoginAction";
            manager.delegate = self;
            manager.responseType = JSON_TYPE;
//            [manager urlCall:API_LOGIN withParameters:(NSMutableDictionary *)postDic];
            [manager urlCall:API_LOGIN withJSONString:jsonString];
            
            [del saveLogs:@"LOGIN API FIRED..."];
        }
        else
        {
            [self showAlertWithTitle:@"" andMessage:@"No Internet Connection Available!"];
        }
    }
    else
    {
        [self showAlertWithTitle:@"" andMessage:@"Username and Password can not be blank. Please try again"];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(BOOL)isNull:(NSString *)str
{
    if([str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0 && ![str isEqualToString:@""])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

-(void)pushNotificationScreen
{
    [del saveLogs:@"Push notification history screen...."];
    NSLog(@"Hello");
    NotificationController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NotificationViewController"];
    [self.navigationController pushViewController:controller animated:YES];
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

#pragma mark -
#pragma mark - UITEXTFIELD DELEGATE METHODS

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    if(textField.tag==1)
//    {
//        [textField resignFirstResponder];
//        [txtPassword becomeFirstResponder];
//    }
//    else
    
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if([UIScreen mainScreen].bounds.size.height<568)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [loginView setFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, loginView.frame.size.height)];
        [UIView commitAnimations];
    }
    NSLog(@"method");
    if (!textField.inputAccessoryView) {
        
        textField.inputAccessoryView = [self keyboardToolBar];
    }
    if (textField == txtUsername) {
        
        [self.segControl setEnabled:YES forSegmentAtIndex:1];
        [self.segControl setEnabled:NO forSegmentAtIndex:0];
    }
    else
    {
        [self.segControl setEnabled:NO forSegmentAtIndex:1];
        [self.segControl setEnabled:YES forSegmentAtIndex:0];
    }
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if([UIScreen mainScreen].bounds.size.height<568)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [loginView setFrame:CGRectMake(0, 111, [UIScreen mainScreen].bounds.size.width, loginView.frame.size.height)];
        [UIView commitAnimations];
    }
    return YES;
}

#pragma mark -
#pragma mark - URL MANAGER DELEGATE METHODS

-(void)onResult:(NSDictionary *)result
{
    NSString *commandName = [result valueForKey:@"commandName"];
    NSLog(@"Result: %@",result);
    
    [del saveLogs:[NSString stringWithFormat:@"Response received : %@",result]];
    
    progressView.hidden = YES;
    self.view.userInteractionEnabled = YES;
    
    if([commandName isEqualToString:@"LoginAction"])
    {
        NSLog(@"Login Response received...");
        
        [del saveLogs:@"Login Response received..."];
        
        if([[[result valueForKey:@"result"] valueForKey:@"status"] isEqualToString:@"Success"])
        {
            //Positive response...
            
            [del saveLogs:@"Success response received for login..."];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:[[[result valueForKey:@"result"] valueForKey:@"response"] valueForKey:@"PK_USER_ID"] forKey:@"USERID"];
            [defaults setValue:[[[result valueForKey:@"result"] valueForKey:@"response"] valueForKey:@"FULLNAME"] forKey:@"FULLNAME"];
            [defaults setValue:[[[result valueForKey:@"result"] valueForKey:@"response"] valueForKey:@"GPS_FREQ"] forKey:@"FREQ"];
            [defaults setValue:[[[result valueForKey:@"result"] valueForKey:@"response"] valueForKey:@"FK_SESSION_ID"] forKey:@"LOGINSESSIONID"];
            [defaults setBool:YES forKey:@"isLoggedIn"];
            [defaults setBool:YES forKey:@"shouldSendFirstLocation"];
            [defaults synchronize];
            
            if(![defaults boolForKey:@"isFirstTime"])
            {
                [del saveLogs:@"This is first time....."];
                NSLog(@"response");
                progressView.hidden = NO;
                self.view.userInteractionEnabled = NO;
                
                [defaults setBool:YES forKey:@"isFirstTime"];
                [defaults synchronize];
                
                if(del.isReachable)
                {
                    [self pushNotificationScreen];
                }
                else
                {
                    [self showAlertWithTitle:@"" andMessage:@"No Internet Connection Available!"];
                }
            }
            else
            {
                [self pushNotificationScreen];
            }
        }
        else if([[[[result valueForKey:@"result"] valueForKey:@"response"]valueForKey:@"PK_USER_ID"] intValue] == -1)
        {
            //Negative response...
            [self showAlertWithTitle:@"" andMessage:@"Username or Password is incorrect. Please try again."];
        }
    }
    else if([commandName isEqualToString:@"Register"])
    {
        NSLog(@"Register device api respose received...");
        
        [del saveLogs:@"Register device api respose received..."];
        
        if([[[result valueForKey:@"result"] valueForKey:@"failure"] intValue]==1)
        {
//            [self showAlertWithTitle:@"" andMessage:@"Device Registration Failed"];
        }
        [self pushNotificationScreen];
    }
    else if([commandName isEqualToString:@"UploadProcess"])
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
                NSLog(@"Nikul");
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
    else
    {
        NSLog(@"Nikul1");
        [self showAlertWithTitle:@"" andMessage:@"Something went wrong. Please try again!"];
    }
}

-(void)onError:(NSError *)error
{
    NSLog(@"Error: %@",error.description);
}

@end
