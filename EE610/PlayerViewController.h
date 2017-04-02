//
//  PlayerViewController.h
//  EE610
//
//  Created by JzChang on 13/3/24.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol PlayerViewControllerDelegate <NSObject>

- (void)hideAndShowPlaylistTVC;

@end

@interface PlayerViewController : UIViewController

@property (weak, nonatomic) id <PlayerViewControllerDelegate> delegate;
@property (strong, nonatomic) MPMoviePlayerController *player;

@end
