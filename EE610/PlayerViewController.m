//
//  PlayerViewController.m
//  EE610
//
//  Created by JzChang on 13/3/24.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "PlayerViewController.h"
#import "SYSTEM_CONSTANT.h"

@interface PlayerViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIPanGestureRecognizer *panGesture; // 手勢辨識 - 平移

@end

@implementation PlayerViewController

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
    
    // 加入 Player
    [self.view addSubview:self.player.view];
    
    // 設定 Navigation Bar 外型
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    // 設定 Navigation Bar 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    // 設定 leftBarButtonItem (選單按鈕)
    UIImage *menuImg = [UIImage imageNamed:@"menu.png"];
    UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuBtn addTarget:self action:@selector(clickMenu:) forControlEvents:UIControlEventTouchUpInside];
    [menuBtn setShowsTouchWhenHighlighted:YES];
    [menuBtn setImage:menuImg forState:UIControlStateNormal];
    [menuBtn setBounds:CGRectMake(0, 0, menuImg.size.width + 10, menuImg.size.height)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
    
    // 設定 rightBarButtonItem (設定音量按鈕)
    if (IS_IPAD) {
        UIStepper *volumeStepper = [[UIStepper alloc] initWithFrame:CGRectZero];
        volumeStepper.minimumValue = 0.0;
        volumeStepper.maximumValue = 1.0;
        volumeStepper.stepValue = 0.05;
        volumeStepper.value = [MPMusicPlayerController applicationMusicPlayer].volume;
        [volumeStepper setIncrementImage:[UIImage imageNamed:@"volume_up.png"] forState:UIControlStateNormal];
        [volumeStepper setDecrementImage:[UIImage imageNamed:@"volume_down.png"] forState:UIControlStateNormal];
        [volumeStepper addTarget:self action:@selector(clickVolumeStepper:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:volumeStepper];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // 支援多個手勢辨識
    return YES;
}

#pragma mark - selector

- (void)clickMenu:(UIButton *)sender
{
    // 發出關閉 Search Bar 鍵盤通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboardNotification" object:nil];
    
    [self.delegate hideAndShowPlaylistTVC];
}

- (void)clickVolumeStepper:(UIStepper *)sender
{
    // 調整音量
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:sender.value];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    CGFloat translationInView_Y = [gesture translationInView:self.view].y;
    
    if (ABS(translationInView_Y) > 35.0) {
        float newVolume = [MPMusicPlayerController applicationMusicPlayer].volume - (translationInView_Y / 3000.0);
        // 調整音量
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:newVolume];
    }
}

#pragma mark - lazy instantiation

- (MPMoviePlayerController *)player
{
    if (!_player) {
        _player = [[MPMoviePlayerController alloc] init];
        _player.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_player setMovieSourceType:MPMovieSourceTypeStreaming];
        [_player setControlStyle:MPMovieControlStyleDefault];
        
        if (IS_IPHONE) {
            // 加入手勢辨識
            [_player.view addGestureRecognizer:self.panGesture];
        }
    }
    
    return _player;
}

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
    }
    
    return _panGesture;
}

@end
