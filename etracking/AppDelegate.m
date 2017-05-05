//
//  AppDelegate.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "NotificationViewController.h"
#import "NotificationController.h"
#import "Reachability.h"

@interface AppDelegate ()
{
    UIBackgroundTaskIdentifier __block bgTask;
}
-(void)reachabilityChanged:(NSNotification*)note;

@property(strong) Reachability * googleReach;
@property(strong) Reachability * localWiFiReach;
@property(strong) Reachability * internetConnectionReach;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self checkInternetConnection];
    
    NSString *str = [[NSUserDefaults standardUserDefaults] valueForKey:@"dateChange"];
    
    if(!str || [str isEqualToString:@""])
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setDateFormat:@"dd-MM-yyyy"];
        NSDate *date = [NSDate date];
        NSString *dateString = [dateFormat stringFromDate:date];
        
        [[NSUserDefaults standardUserDefaults] setValue:dateString forKey:@"dateChange"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //Remove this line once you get device token from delegate method
    [[NSUserDefaults standardUserDefaults] setValue:@"1234567890123456" forKey:@"DEVICETOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self registerForPushNotification];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"])
    {
        self.navController = [[UINavigationController alloc]initWithRootViewController:[storyBoard instantiateViewControllerWithIdentifier:@"ViewController"]];
    }
    else
    {
        self.navController = [[UINavigationController alloc]initWithRootViewController:[storyBoard instantiateViewControllerWithIdentifier:@"NotificationViewController"]];
    }
    self.navController.navigationBar.hidden = YES;
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    return YES;
}

-(void)registerForPushNotification
{
    //Register for push notifications...
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
#ifdef __IPHONE_8_0
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge                                                                                            | UIUserNotificationTypeSound) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
#endif
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }

}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings // available in iOS8
{
    [application registerForRemoteNotifications];
}

-(void)saveLogs:(NSString *)log
{
    log = [NSString stringWithFormat:@"\n\n %@ --- DateTime: %@",log,[NSDate date]];
    //Get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"logFile.txt"];
    
    //create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    
    //append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString * token = [NSString stringWithFormat:@"%@", deviceToken];
    //Format token as you need:
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    NSLog(@"%@",token);
    
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:token message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//    [alert show];
    
    [[NSUserDefaults standardUserDefaults] setValue:token forKey:@"DEVICETOKEN"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isRegistered"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Handle your remote RemoteNotification
    NSLog(@"Remove Notification Received : %@",userInfo);
    /*
    NSArray *notificationData = [[NSUserDefaults standardUserDefaults] valueForKey:@"NotificationData"];
    NSMutableArray *notificationArray;
    if(!notificationData)
    {
        notificationArray = [[NSMutableArray alloc]init];
    }
    else
    {
        notificationArray = [[NSMutableArray alloc]initWithArray:notificationData];
    }
    NSLog(@"Notification Array: %@",notificationArray);
    
    NSString *jsonString = [userInfo valueForKey:@"sentfrom"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSLog(@"JSON Dic : %@",dataDic);
    
    NSString *dateString = [NSString stringWithFormat:@"%@ %@",[dataDic valueForKey:@"date"],[dataDic valueForKey:@"time"]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dt = [dateFormat dateFromString:dateString];
    NSLog(@"Date: %@",dt);
    
    NSDictionary *dic = @{@"NotificationDate":dt,@"message":[userInfo valueForKey:@"sentfrom"] ,@"link":[[userInfo valueForKey:@"aps"] valueForKey:@"link_url"]};
    [notificationArray addObject:dic];
    
    [[NSUserDefaults standardUserDefaults] setValue:notificationArray forKey:@"NotificationData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    */
    
    [self saveNotification:userInfo];
    
    [self performSelector:@selector(refreshController) withObject:nil afterDelay:0.2];
}

-(void)refreshController
{
    NotificationController *controller;
    
    if([[self.navController.viewControllers lastObject] isKindOfClass:[NotificationController class]])
    {
        controller = [self.navController.viewControllers lastObject];
        [controller viewWillAppear:YES];
    }
}

-(void)saveNotification:(NSDictionary *)userInfo
{
    NSMutableArray *notificationData = [[NSUserDefaults standardUserDefaults] valueForKey:@"NotificationData"];
    NSMutableArray *notificationArray;
    if(!notificationData)
    {
        notificationArray = [[NSMutableArray alloc]init];
    }
    else
    {
        notificationArray = [[NSMutableArray alloc]initWithArray:notificationData];
    }
    
    NSString *jsonString = [userInfo valueForKey:@"sentfrom"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSLog(@"JSON Dic : %@",dataDic);
    
    int i=0;
    for(;i<[notificationArray count];i++)
    {
        if([[[notificationArray objectAtIndex:i] valueForKey:@"Title"] isEqualToString:[dataDic valueForKey:@"date"]])
        {
            NSMutableDictionary *mutDic = [[notificationArray objectAtIndex:i] mutableCopy];
            
            NSMutableArray *tempArray = [[[notificationArray objectAtIndex:i] valueForKey:@"Data"] mutableCopy];
            
            NSString *dateString = [NSString stringWithFormat:@"%@ %@",[dataDic valueForKey:@"date"],[dataDic valueForKey:@"time"]];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *dt = [dateFormat dateFromString:dateString];
            NSLog(@"Date: %@",dt);
            
            NSDictionary *dic = @{@"NotificationDate":dt,@"message":[userInfo valueForKey:@"sentfrom"] ,@"link":[[userInfo valueForKey:@"aps"] valueForKey:@"link_url"]};

            [tempArray addObject:dic];
            
            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"NotificationDate"
                                                         ascending:NO];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            NSArray *myArray = [tempArray sortedArrayUsingDescriptors:sortDescriptors];
            
            [mutDic setValue:[dataDic valueForKey:@"date"] forKey:@"Title"];
            [mutDic setValue:myArray forKey:@"Data"];
            
            notificationArray[i] = mutDic;

            break;
        }
    }
    
    if(i==[notificationArray count])
    {
        NSMutableDictionary *mutDic = [[NSMutableDictionary alloc]init];
        
        NSMutableArray *tempArray = [[NSMutableArray alloc]init];
        
        NSString *dateString = [NSString stringWithFormat:@"%@ %@",[dataDic valueForKey:@"date"],[dataDic valueForKey:@"time"]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *dt = [dateFormat dateFromString:dateString];
        NSLog(@"Date: %@",dt);
        
        NSDictionary *dic = @{@"NotificationDate":dt,@"message":[userInfo valueForKey:@"sentfrom"] ,@"link":[[userInfo valueForKey:@"aps"] valueForKey:@"link_url"]};
        [tempArray addObject:dic];
        
        NSSortDescriptor *sortDescriptor;
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"NotificationDate"
                                                     ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *myArray = [tempArray sortedArrayUsingDescriptors:sortDescriptors];
        
        [mutDic setValue:[dataDic valueForKey:@"date"] forKey:@"Title"];
        [mutDic setValue:myArray forKey:@"Data"];
        
        notificationArray[i] = mutDic;
    }
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"Title"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *myArray = [notificationArray sortedArrayUsingDescriptors:sortDescriptors];
    
    [[NSUserDefaults standardUserDefaults] setValue:myArray forKey:@"NotificationData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    NSLog(@"Notification Info : %@",userInfo);
    /*
    NSMutableArray *notificationData = [[NSUserDefaults standardUserDefaults] valueForKey:@"NotificationData"];
    NSMutableArray *notificationArray;
    if(!notificationData)
    {
        notificationArray = [[NSMutableArray alloc]init];
    }
    else
    {
        notificationArray = [[NSMutableArray alloc]initWithArray:notificationData];
    }
    NSLog(@"Notification Array: %@",notificationArray);
    
    NSString *jsonString = [userInfo valueForKey:@"sentfrom"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSLog(@"JSON Dic : %@",dataDic);
    
    NSString *dateString = [NSString stringWithFormat:@"%@ %@",[dataDic valueForKey:@"date"],[dataDic valueForKey:@"time"]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dt = [dateFormat dateFromString:dateString];
    NSLog(@"Date: %@",dt);
    
    NSDictionary *dic = @{@"NotificationDate":dt,@"message":[userInfo valueForKey:@"sentfrom"] ,@"link":[[userInfo valueForKey:@"aps"] valueForKey:@"link_url"]};
    [notificationArray addObject:dic];
    
    [[NSUserDefaults standardUserDefaults] setValue:notificationArray forKey:@"NotificationData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    */
    
    [self saveNotification:userInfo];
    
    NotificationController *controller;
    
    if([[self.navController.viewControllers lastObject] isKindOfClass:[NotificationController class]])
    {
        controller = [self.navController.viewControllers lastObject];
        [controller viewWillAppear:YES];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error:%@",error);
}

-(void)checkInternetConnection
{
    //////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////
    //
    // create a Reachability object for www.google.com
    
    __weak __block typeof(self) weakself = self;
    
    self.googleReach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    self.googleReach.reachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Reachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this uses NSOperationQueue mainQueue
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            weakself.isReachable = YES;
        }];
    };
    
    self.googleReach.unreachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Unreachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this one uses dispatch_async they do the same thing (as above)
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.isReachable = NO;
        });
    };
    
    [self.googleReach startNotifier];
    
    //////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////
    //
    // create a reachability for the local WiFi
    
    self.localWiFiReach = [Reachability reachabilityForLocalWiFi];
    
    // we ONLY want to be reachable on WIFI - cellular is NOT an acceptable connectivity
    self.localWiFiReach.reachableOnWWAN = NO;
    
    self.localWiFiReach.reachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"LocalWIFI Block Says Reachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.isReachable = YES;
        });
    };
    
    self.localWiFiReach.unreachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"LocalWIFI Block Says Unreachable(%@)", reachability.currentReachabilityString];
        
        NSLog(@"%@", temp);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.isReachable = NO;
        });
    };
    
    [self.localWiFiReach startNotifier];
    
    
    
    //////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////
    //
    // create a Reachability object for the internet
    
    self.internetConnectionReach = [Reachability reachabilityForInternetConnection];
    
    self.internetConnectionReach.reachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@" InternetConnection Says Reachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.isReachable = YES;
        });
    };
    
    self.internetConnectionReach.unreachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"InternetConnection Block Says Unreachable(%@)", reachability.currentReachabilityString];
        
        NSLog(@"%@", temp);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.isReachable = NO;
        });
    };
    
    [self.internetConnectionReach startNotifier];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    [self saveLogs:@"Reachability changed...."];
    
    if(reach == self.googleReach)
    {
        if([reach isReachable])
        {
            [self saveLogs:@"Internet Reachable.... App Delegate..."];
            
            NSString * temp = [NSString stringWithFormat:@"GOOGLE Notification Says Reachable(%@)", reach.currentReachabilityString];
            NSLog(@"%@", temp);
            
            
            if(![[NSUserDefaults standardUserDefaults] boolForKey:@"isRegistered"])
            {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isRegistered"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self saveLogs:@"Register for push notification will be called..."];
                
                [self registerForPushNotification];
            }
            
            if(![[NSUserDefaults standardUserDefaults] boolForKey:@"Reachable"])
            {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Reachable"];
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                NotificationController *controller;
                
                if([[self.navController.viewControllers lastObject] isKindOfClass:[NotificationController class]])
                {
                    [self saveLogs:@"Check local storage data will be called... Inside IF condition..."];
                    controller = [self.navController.viewControllers lastObject];
                    [controller checkLocalStoageData];
                }
                else
                {
                    [self saveLogs:@"Check local storage data will not be called... Inside ELSE condition..."];
                }
            }
            self.isReachable = YES;
        }
        else
        {
            [self saveLogs:@"Internet Not Reachable.... App Delegate..."];
            
            NSString * temp = [NSString stringWithFormat:@"GOOGLE Notification Says Unreachable(%@)", reach.currentReachabilityString];
            NSLog(@"%@", temp);

            self.isReachable = NO;
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Reachable"];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        //Prevent from going inactive by starting location update
        //[controller setGPSCalls];
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive ) {
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
                break;
            } else {
                //DO something in the background
            }
            
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self checkInternetConnection];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
