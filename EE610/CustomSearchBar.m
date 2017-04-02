//
//  CustomSearchBar.m
//  EE610
//
//  Created by JzChang on 13/3/17.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "CustomSearchBar.h"

@implementation CustomSearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.placeholder = NSLocalizedString(@"搜尋影片", @"Search Video");
        
        self.customButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.customButton setImage:[UIImage imageNamed:@"sort.png"] forState:UIControlStateNormal];
        [self addSubview:self.customButton];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.customButton setFrame:CGRectMake(self.frame.size.width - 80, 0, 75, 43)];
    
    UITextField *searchField = [self.subviews objectAtIndex:1];
        
    if (self.showsCancelButton == YES) {
        // 顯示取消按鈕 就 移除按鈕
        [self.customButton removeFromSuperview];
        [searchField setFrame:CGRectMake(5, 6, self.frame.size.width - 70, 31)];
    }
    else {
        // 沒有顯示取消按鈕 就 加入按鈕
        [self addSubview:self.customButton];
        [searchField setFrame:CGRectMake(5, 6, self.frame.size.width - 90, 31)];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
