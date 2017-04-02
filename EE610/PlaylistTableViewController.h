//
//  PlaylistTableViewController.h
//  playlistXML
//
//  Created by JzChang on 13/3/2.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlaylistTableViewControllerDelegate <NSObject>

- (void)playURL:(NSURL *)fileURL andViedoName:(NSString *)name; // 設定播放影片 URL 路徑, 並播放影片
- (void)enterSettingsMode;                                      // 進入設定模式

@end

@interface PlaylistTableViewController : UITableViewController

@property (weak, nonatomic) id <PlaylistTableViewControllerDelegate> delegate;

- (void)updateTableViewOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updateData;

@end
