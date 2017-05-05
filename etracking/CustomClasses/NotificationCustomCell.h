//
//  NotificationCustomCell.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationCustomCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel *lblTitle;
@property (nonatomic,strong) IBOutlet UILabel *lblDescription;
@property (nonatomic,strong) IBOutlet UILabel *lblDate;

@end
