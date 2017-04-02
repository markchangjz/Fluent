//
//  VideoViewController.h
//  EE610
//
//  Created by JzChang on 13/3/5.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SettingTableViewController.h"

@protocol VideoViewControllerDelegate <NSObject>

- (void)hideAndShowPlaylistTVC;

@end

@interface VideoViewController : UIViewController

@property (weak, nonatomic) id <VideoViewControllerDelegate> delegate;
@property (strong, nonatomic) UINavigationController *navPlayerVC, *navSettingTVC;
@property (strong, nonatomic) MPMoviePlayerController *player;

- (void)addMaskView;
- (void)removeMaskView;
- (void)playerMode;
- (void)settingMode;

@end
