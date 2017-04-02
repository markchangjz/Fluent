//
//  ServerListTableViewController.h
//  EE610
//
//  Created by JzChang on 13/3/19.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ServerListTableViewControllerDelegate <NSObject>

- (void)selectVideoData:(NSDictionary *)data;
- (void)selectOpenUrl:(NSURL *)url;

@end

@interface ServerListTableViewController : UITableViewController

@property (weak, nonatomic) id <ServerListTableViewControllerDelegate> delegate;

@end
