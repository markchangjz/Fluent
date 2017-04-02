//
//  VideoInfoTableViewController.h
//  EE610
//
//  Created by JzChang on 13/3/7.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoInfoTableViewControllerDelegate <NSObject>

- (void)playSelectURL:(NSURL *)fileURL andViedoName:(NSString *)name;

@end

@interface VideoInfoTableViewController : UITableViewController

@property (weak, nonatomic) id <VideoInfoTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSDictionary *videoInfo;
@property (strong, nonatomic) NSString *parserString;

@end
