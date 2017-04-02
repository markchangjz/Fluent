//
//  AddServerTableViewController.h
//  EE610
//
//  Created by JzChang on 13/3/18.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddServerTableViewControllerDelegate <NSObject>

- (void)editOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updataData;   // 回傳更新的資料給 SettingTVC

@end

@interface AddServerTableViewController : UITableViewController

@property (weak, nonatomic) id <AddServerTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString *editPcName, *editIp, *editDirectory;
@property (nonatomic) NSInteger selectIndex;

@end
