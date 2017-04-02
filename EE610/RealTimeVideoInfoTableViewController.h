//
//  RealTimeVideoInfoTableViewController.h
//  EE610
//
//  Created by JzChang on 13/5/20.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RealTimeVideoInfoTableViewControllerDelegate <NSObject>

- (void)playSelectRealTimeVideoItem:(NSDictionary *)videoItem;

@end

@interface RealTimeVideoInfoTableViewController : UITableViewController

@property (weak, nonatomic) id <RealTimeVideoInfoTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSDictionary *videoInfo;
@property (strong, nonatomic) NSString *parserString;

@end
