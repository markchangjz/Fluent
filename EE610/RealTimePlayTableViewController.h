//
//  RealTimePlayTableViewController.h
//  EE610
//
//  Created by JzChang on 13/4/22.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RealTimePlayTableViewControllerDelegate <NSObject>

- (void)playRealTimeVideoURL:(NSURL *)fileURL andViedoName:(NSString *)name;    // 設定播放影片 URL 路徑, 並播放影片
- (void)enterSettingsMode;                                                      // 進入設定模式

@end

@interface RealTimePlayTableViewController : UITableViewController

@property (weak, nonatomic) id <RealTimePlayTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSArray *ipToolbarItems;

@end
