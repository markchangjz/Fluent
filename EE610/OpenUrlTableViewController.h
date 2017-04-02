//
//  OpenUrlTableViewController.h
//  EE610
//
//  Created by JzChang on 13/4/5.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OpenUrlTableViewControllerDelegate <NSObject>

- (void)openUrl:(NSURL *)url;

@end

@interface OpenUrlTableViewController : UITableViewController

@property (weak, nonatomic) id <OpenUrlTableViewControllerDelegate> delegate;

@end
