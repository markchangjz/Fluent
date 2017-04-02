//
//  MainViewController.m
//  EE610
//
//  Created by JzChang on 13/3/4.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SYSTEM_CONSTANT.h"
#import "CheckNetwork.h"
#import "PlistHelper.h"

typedef enum {hideStatus, showStatus} DownViewStatus;

@interface MainViewController () <PlaylistTableViewControllerDelegate, PlayerViewControllerDelegate, SettingTableViewControllerDelegate, UIGestureRecognizerDelegate> {
    DownViewStatus currentDownViewStatus;                                   // 紀錄目前 DownView 顯示狀態
    UINavigationController *navPlaylistTVC, *navPlayerVC, *navSettingTVC;   // 使用 Navigation
    BOOL doHideOrShowDownView;                                              // YES:已執行過 hideDownView 或 showDownView
}

@property (strong, nonatomic) UISwipeGestureRecognizer *swipeLeft;          // 手勢辨識 - 向左滑
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeRight;         // 手勢辨識 - 向右滑
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;           // 手勢辨識 - 平移
@property (strong, nonatomic) UITapGestureRecognizer *tapTouch;             // 手勢辨識 - 輕拍
@property (strong, nonatomic) UIView *overlayView;                          // 浮罩層
@property (strong, nonatomic) UITabBarController *tabBarController;

@end

@implementation MainViewController

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
    
    // 初始化
    navPlaylistTVC = [[UINavigationController alloc] initWithRootViewController:self.playlistTVC];
    [self addChildViewController:navPlaylistTVC];
    
    navPlayerVC = [[UINavigationController alloc] initWithRootViewController:self.playerVC];
    [self addChildViewController:navPlayerVC];
    
    navSettingTVC = [[UINavigationController alloc] initWithRootViewController:self.settingTVC];
    [self addChildViewController:navSettingTVC];
    
    // downView - 使用 PlaylistTableViewController
    [self.view addSubview:self.downView];
    [self.downView addSubview:navPlaylistTVC.view];
    
    // topView - 使用 SettingTableViewController
    [self.view addSubview:self.topView];
    [self.topView addSubview:navSettingTVC.view];
    
    // 在 topView 加入手勢辨識
    [self.topView addGestureRecognizer:self.swipeLeft];
    [self.topView addGestureRecognizer:self.swipeRight];
//    [self.topView addGestureRecognizer:self.panGesture];
    
    // 圓角處理
    self.downView.layer.masksToBounds = YES;
    self.downView.layer.cornerRadius = 6;
    self.topView.layer.masksToBounds = YES;
    self.topView.layer.cornerRadius = 6;
    
    doHideOrShowDownView = NO;
    
    if (IS_IPHONE) {
        [self confingView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (IS_IPHONE) {
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            self.overlayView.frame = CGRectMake(0, 44.0, self.topView.frame.size.width, self.topView.frame.size.height - 44.0);
        }
        else {
            self.overlayView.frame = CGRectMake(0, 32.0, self.topView.frame.size.width, self.topView.frame.size.height - 32.0);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 加入 Notification - 當APP再被喚起時
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterForeground:)
                                                 name:@"UIApplicationWillEnterForegroundNotification"
                                               object:nil];
        
    if (IS_IPAD && !self.playerVC.player.contentURL) {
        [self confingView];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 移除 Notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    UIAlertView *memoryWarningAlertView = [[UIAlertView alloc] initWithTitle:@"MainViewController"
                                                                     message:@"didReceiveMemoryWarning"
                                                                    delegate:nil cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
    [memoryWarningAlertView show];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (IS_IPAD) {
        CGFloat navBarHeight = navPlayerVC.navigationBar.frame.size.height;
        self.overlayView.frame = CGRectMake(0, navBarHeight, self.topView.frame.size.width, self.topView.frame.size.height - navBarHeight);
    }
    else {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            self.overlayView.frame = CGRectMake(0, 44.0, self.topView.frame.size.width, self.topView.frame.size.height - 44.0);
        }
        else {
            self.overlayView.frame = CGRectMake(0, 32.0, self.topView.frame.size.width, self.topView.frame.size.height - 32.0);
        }
    }
}

#pragma mark - Private Function

- (void)confingView
{
    // 有儲存網路位址才顯示 Playlist TVC
    NSString *plistPath = [PlistHelper plistFilePathOfIpData];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSArray *readStoreData = [[NSArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
        
        if (readStoreData.count > 0) {
            [self showDownView];
        }
    }
}

- (void)addOverlayView
{
    [self.topView addSubview:self.overlayView];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                         }
                     }];
}

- (void)removeOverlayView
{
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.overlayView.backgroundColor = [UIColor clearColor];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self.overlayView removeFromSuperview];
                         }
                     }];
}

- (void)showDownView
{
    doHideOrShowDownView = YES;
    currentDownViewStatus = showStatus;
    
    // 加入 tap 手勢
    [self.topView addGestureRecognizer:self.tapTouch];
    
    // 發出關閉鍵盤通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboardNotification" object:nil];
    
    if (self.playerVC.player.playbackState == MPMoviePlaybackStatePlaying) {
        // 如果 player 正在播放影片就暫停播放
        [self.playerVC.player pause];
    }
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.topView.frame = CGRectMake(DOWN_VIEW_WIDTH + 10, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             // 加入浮罩層
                             [self addOverlayView];
                             
                             [UIView animateWithDuration:0.1
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  self.topView.frame = CGRectMake(DOWN_VIEW_WIDTH - 5, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                                              }
                                              completion:^(BOOL finished) {
                                                  if (finished) {
                                                      [UIView animateWithDuration:0.05
                                                                            delay:0.0
                                                                          options:UIViewAnimationOptionCurveEaseInOut
                                                                       animations:^{
                                                                           self.topView.frame = CGRectMake(DOWN_VIEW_WIDTH + 1, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                                                                       }
                                                                       completion:^(BOOL finished) {
                                                                           if (finished) {
                                                                               // 結束
                                                                               doHideOrShowDownView = NO;
                                                                           }
                                                                       }];
                                                  }
                                              }];
                         }
                     }];
}

- (void)hideDownView
{
    doHideOrShowDownView = YES;
    currentDownViewStatus = hideStatus;
    
    // 移除 tap 手勢
    [self.topView removeGestureRecognizer:self.tapTouch];
    
    // 發出關閉鍵盤通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboardNotification" object:nil];
    
    if (self.playerVC.player.playbackState == MPMoviePlaybackStatePaused) {
        // 如果 player 暫停播放影片就繼續播放
        [self.playerVC.player play];
    }
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.topView.frame = CGRectMake(-10, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             // 移除浮罩層
                             [self removeOverlayView];
                             
                             [UIView animateWithDuration:0.1
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  self.topView.frame = CGRectMake(5, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                                              }
                                              completion:^(BOOL finished) {
                                                  if (finished) {
                                                      [UIView animateWithDuration:0.05
                                                                            delay:0.0
                                                                          options:UIViewAnimationOptionCurveEaseInOut
                                                                       animations:^{
                                                                           self.topView.frame = CGRectMake(0, 0, self.topView.frame.size.width, self.topView.frame.size.height);
                                                                       }
                                                                       completion:^(BOOL finished) {
                                                                           if (finished) {
                                                                               // 結束
                                                                               doHideOrShowDownView = NO;
                                                                           }
                                                                       }];
                                                  }
                                              }];
                         }
                     }];
}

#pragma mark - PlaylistTableViewControllerDelegate

- (void)playURL:(NSURL *)fileURL andViedoName:(NSString *)name
{
//    [self.topView removeGestureRecognizer:self.panGesture];
    
    if (fileURL == nil && name == nil) {
        [self.playerVC.player setContentURL:nil];
        self.playerVC.navigationItem.title = nil;
        return;
    }

    [self hideDownView];
    
    [self.topView addSubview:navPlayerVC.view];
    
    // 設定 tilte 為播放影片的名稱
    self.playerVC.navigationItem.title = name;
    
    if (self.playerVC.player.playbackState == MPMoviePlaybackStatePlaying) {
        // 如果 player 正在播放影片就停止播放
        [self.playerVC.player stop];
    }
    
    // 設定影片 URL 路徑
    [self.playerVC.player setContentURL:fileURL];
    [self.playerVC.player prepareToPlay];
    
    [self.playerVC.player play];
    
    // 避免 MPMoviePlayerController 從全銀幕縮小後會停留在 AddServerTVC 而再顯示鍵盤
    [navSettingTVC popToRootViewControllerAnimated:NO];
}

- (void)enterSettingsMode
{
//    [self.topView addGestureRecognizer:self.panGesture];
    
    [self hideDownView];
    
    [self.topView addSubview:navSettingTVC.view];
    
    // 回到 Navigation 第一個畫面
    [navSettingTVC popToRootViewControllerAnimated:YES];
    
    [self.playerVC.player stop];
}

#pragma mark - PlayerViewControllerDelegate & SettingTableViewControllerDelegate

// 按下 menu 按鈕觸發
- (void)hideAndShowPlaylistTVC
{
    if (currentDownViewStatus == hideStatus) {
        [self showDownView];
    }
    else if (currentDownViewStatus == showStatus) {
        [self hideDownView];
    }
}

#pragma mark - SettingTableViewControllerDelegate

- (void)updatePlayListOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updateData
{
    [self.playlistTVC updateTableViewOriData:oriData andUpdateData:updateData];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // 支援多個手勢辨識    
    return YES;
}

#pragma mark - selector

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gesture
{
    if (currentDownViewStatus == showStatus) {
        if (!doHideOrShowDownView) {
            [self hideDownView];
        }
    }
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gesture
{
    if (currentDownViewStatus == hideStatus) {
        if (!doHideOrShowDownView) {
            [self showDownView];
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self hideDownView];
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture;
{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint origin = gesture.view.frame.origin;
        CGPoint translation = [gesture translationInView:gesture.view];
        
        if (ABS(translation.x) > 2.0) {
            if (self.topView.frame.origin.x > DOWN_VIEW_WIDTH) {
                origin = CGPointMake(origin.x + translation.x / (self.topView.frame.origin.x / 20), 0);
            }
            else if (self.topView.frame.origin.x < 0) {
                origin = CGPointMake(origin.x - translation.x / (self.topView.frame.origin.x), 0);
            }
            else {
                origin = CGPointMake(origin.x + translation.x, 0);
            }
            
            gesture.view.frame = CGRectMake(origin.x, 0, gesture.view.frame.size.width, gesture.view.frame.size.height);
            [gesture setTranslation:CGPointZero inView:gesture.view];
        }
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        if (self.topView.frame.origin.x >= DOWN_VIEW_WIDTH / 2) {
            if (!doHideOrShowDownView) {
                [self showDownView];
            }
        }
        else {
            if (!doHideOrShowDownView) {
                [self hideDownView];
            }
        }
    }    
}

// Notification - 當APP在被喚起時
- (void)handleEnterForeground:(NSNotification *)notification
{
    if (currentDownViewStatus == hideStatus) {
        [self performSelector:@selector(showDownView) withObject:nil afterDelay:0.5];
    }
}

#pragma mark - lazy instantiation

// 左邊 View
- (UIView *)downView
{
    if (!_downView) {
        _downView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DOWN_VIEW_WIDTH, self.view.frame.size.height)];
        _downView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
    }
    
    return _downView;
}

// 右邊 View
- (UIView *)topView
{
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return _topView;
}

// downView 裡的 playlistTVC
- (PlaylistTableViewController *)playlistTVC
{
    if (!_playlistTVC) {
        _playlistTVC = [[PlaylistTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _playlistTVC.delegate = self; // 設定 delegate
    }
    
    return _playlistTVC;
}

// topView 裡的 playerVC
- (PlayerViewController *)playerVC
{
    if (!_playerVC) {
        _playerVC = [[PlayerViewController alloc] init];
        _playerVC.delegate = self; // 設定 delegate
    }
    
    return _playerVC;
}

// topView 裡的 settingTVC
- (SettingTableViewController *)settingTVC
{
    if (!_settingTVC) {
        _settingTVC = [[SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _settingTVC.delegate = self; // 設定 delegate
    }
    
    return _settingTVC;
}

- (UIView *)overlayView
{
    CGFloat navBarHeight = navPlayerVC.navigationBar.frame.size.height;
    CGRect aFrame = self.topView.frame;
    aFrame.origin.x = 0;
    aFrame.origin.y = navBarHeight;
    aFrame.size.height -= navBarHeight;
    
    if (!_overlayView) {
        _overlayView = [[UIView alloc] initWithFrame:aFrame];
        _overlayView.backgroundColor = [UIColor clearColor];
        _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    if (IS_IPHONE) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            aFrame.origin.y = 32.0;
            aFrame.size.height += 12.0;
        }
    }
    
    _overlayView.frame = aFrame;
    
    return _overlayView;
}

- (UISwipeGestureRecognizer *)swipeLeft
{
    if (!_swipeLeft) {
        _swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
        _swipeLeft.delegate = self;
        _swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    
    return _swipeLeft;
}

- (UISwipeGestureRecognizer *)swipeRight
{
    if (!_swipeRight) {
        _swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
        _swipeRight.delegate = self;
        _swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    }
    
    return _swipeRight;
}

- (UITapGestureRecognizer *)tapTouch
{
    if (!_tapTouch) {
        _tapTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tapTouch.numberOfTouchesRequired = 1;  // 手指數
        _tapTouch.numberOfTapsRequired = 1;     // 連續點擊次數
    }
    
    return _tapTouch;
}

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
    }
    
    return _panGesture;
}

- (UITabBarController *)tabBarController
{
    if (!_tabBarController) {
        _tabBarController = [[UITabBarController alloc] init];
        _tabBarController.viewControllers = @[navPlaylistTVC];
    }
    
    return _tabBarController;
}

@end
