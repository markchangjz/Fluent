//
//  SettingTableViewController.h
//  EE610
//
//  Created by JzChang on 13/3/13.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingTableViewControllerDelegate <NSObject>

// 按下 menu 按鈕顯示和影藏左手邊 TVC 影片列表
- (void)hideAndShowPlaylistTVC;
// 修改伺服器資訊
- (void)updatePlayListOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updateData;

@end

@interface SettingTableViewController : UITableViewController

@property (weak, nonatomic) id <SettingTableViewControllerDelegate> delegate;

@end
