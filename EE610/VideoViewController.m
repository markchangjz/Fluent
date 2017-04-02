//
//  VideoViewController.m
//  EE610
//
//  Created by JzChang on 13/3/5.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "VideoViewController.h"
#import "SYSTEM_CONSTANT.h"

@interface VideoViewController () <SettingTableViewControllerDelegate>

@property (strong, nonatomic) SettingTableViewController *settingTVC;
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeUp;    // 手勢辨識 - 向上滑
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeDown;  // 手勢辨識 - 向下滑

@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 初始畫面為 playerMode
    [self playerMode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
    if (IS_IPAD) {
        CGFloat navBarHeight = self.navPlayerVC.navigationBar.frame.size.height;
        
        self.player.view.frame = CGRectMake(0, navBarHeight, self.view.frame.size.width, self.view.frame.size.height - navBarHeight);
        self.maskView.frame = CGRectMake(0, navBarHeight, self.view.frame.size.width, self.view.frame.size.height - navBarHeight);
        
    }
    else {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            self.player.view.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
            self.maskView.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
        }
        else {
            self.player.view.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 32);
            self.maskView.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 32);
        }
    }
}

#pragma mark - Function

- (void)addMaskView
{
    [self.view addSubview:self.maskView];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                         }
                     }];
}

- (void)removeMaskView
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         self.maskView.backgroundColor = [UIColor clearColor];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self.maskView removeFromSuperview];
                         }
                     }];
}

// 進入影片播放模式
- (void)playerMode
{
    // 移除畫面
    [self.navSettingTVC.view removeFromSuperview];
    // 移除 Child View Controller
    [self.navSettingTVC removeFromParentViewController];
    
    // 加入新畫面 & Child View Controller
    [self addChildViewController:self.navPlayerVC];
    [self.view addSubview:self.navPlayerVC.view];
    [self.navPlayerVC.view addSubview:self.player.view];
}

// 進入設定模式
- (void)settingMode
{
    [self.player stop];
    // 移除畫面
    [self.navPlayerVC.view removeFromSuperview];
    // 移除 Child View Controller
    [self.navPlayerVC removeFromParentViewController];
    
    // 加入新畫面 & Child View Controller
    [self addChildViewController:self.navSettingTVC];
    [self.view addSubview:self.navSettingTVC.view];
    [self.view insertSubview:self.navSettingTVC.view belowSubview:self.maskView];
    [self.navSettingTVC popToRootViewControllerAnimated:NO]; // 返回到 Root View
}

#pragma mark - selector

- (void)clickMenu:(UIButton *)sender
{
    // 發出關閉 Search Bar 鍵盤通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboardNotification" object:nil];
    
    [self.delegate hideAndShowPlaylistTVC];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gesture
{
    // 加大音量
    float newVolume = [MPMusicPlayerController applicationMusicPlayer].volume + 0.1;
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:newVolume];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)gesture
{
    // 降低音量
    float newVolume = [MPMusicPlayerController applicationMusicPlayer].volume - 0.1;
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:newVolume];
}

#pragma mark - SettingTableViewControllerDelegate

- (void)hideAndShowPlaylistTVC
{
    [self clickMenu:nil];
}

#pragma mark - lazy instantiation

- (UIView *)maskView
{
    if (!_maskView) {
        CGFloat navBarHeight = self.navPlayerVC.navigationBar.frame.size.height;
        _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, navBarHeight, self.view.frame.size.width, self.view.frame.size.height - navBarHeight)];
        _maskView.backgroundColor = [UIColor clearColor];
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return _maskView;
}

- (MPMoviePlayerController *)player
{
    if (!_player) {
        _player = [[MPMoviePlayerController alloc] init];
        CGFloat navBarHeight = self.navPlayerVC.navigationBar.frame.size.height;
        _player.view.frame = CGRectMake(0, navBarHeight, self.navPlayerVC.view.frame.size.width, self.navPlayerVC.view.frame.size.height - navBarHeight);
        _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_player setControlStyle:MPMovieControlStyleDefault];
        
        // 加入手勢辨識
        [_player.view addGestureRecognizer:self.swipeUp];
        [_player.view addGestureRecognizer:self.swipeDown];
    }
    
    return _player;
}

- (SettingTableViewController *)settingTVC
{
    if (!_settingTVC) {
        _settingTVC = [[SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _settingTVC.delegate = self;
    }
    
    return _settingTVC;
}

- (UINavigationController *)navPlayerVC
{
    if (!_navPlayerVC) {
        
        _navPlayerVC = [[UINavigationController alloc] initWithRootViewController:self];
        
        // 設定 Navigation Bar 外型
        [_navPlayerVC.navigationBar setBarStyle:UIBarStyleBlack];
        // 設定 Navigation Bar 背景
        [_navPlayerVC.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg6.png"] forBarMetrics:UIBarMetricsDefault];
        
        UIImage *menuImg = [UIImage imageNamed:@"menu_white.png"];
        UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [menuBtn addTarget:self action:@selector(clickMenu:) forControlEvents:UIControlEventTouchUpInside];
        [menuBtn setShowsTouchWhenHighlighted:YES];
        [menuBtn setImage:menuImg forState:UIControlStateNormal];
        [menuBtn setBounds:CGRectMake(0, 0, menuImg.size.width+10, menuImg.size.height)];
        
        UIBarButtonItem *menuBtnItem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
        
        self.navigationItem.leftBarButtonItem = menuBtnItem;
    }
    
    return _navPlayerVC;
}

- (UINavigationController *)navSettingTVC
{
    if (!_navSettingTVC) {
        _navSettingTVC = [[UINavigationController alloc] initWithRootViewController:self.settingTVC];
    }
    
    return _navSettingTVC;
}

- (UISwipeGestureRecognizer *)swipeUp
{
    if (!_swipeUp) {
        _swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
        _swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    }
    
    return _swipeUp;
}

- (UISwipeGestureRecognizer *)swipeDown
{
    if (!_swipeDown) {
        _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
        _swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    }
    
    return _swipeDown;
}


@end
