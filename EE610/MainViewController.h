//
//  MainViewController.h
//  EE610
//
//  Created by JzChang on 13/3/4.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistTableViewController.h"
#import "PlayerViewController.h"
#import "SettingTableViewController.h"

@interface MainViewController : UIViewController

@property (strong, nonatomic) UIView *downView, *topView;
@property (strong, nonatomic) PlaylistTableViewController *playlistTVC;
@property (strong, nonatomic) PlayerViewController *playerVC;
@property (strong, nonatomic) SettingTableViewController *settingTVC;

@end
