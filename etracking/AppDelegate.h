//
//  AppDelegate.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,assign) BOOL isReachable;

@property (nonatomic,strong) UILabel *lblBottom;

@property (nonatomic,strong) UINavigationController *navController;

-(void)saveLogs:(NSString *)log;

@end

