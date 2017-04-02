//
//  MyScearchBar.m
//  EE610
//
//  Created by JzChang on 13/3/16.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "MyScearchBar.h"

@implementation MyScearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.selectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.selectButton.contentEdgeInsets = (UIEdgeInsets){.left=4,.right=4};
//        [self.selectButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        
        self.selectButton.titleLabel.numberOfLines = 1;
        self.selectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.selectButton setTitle:@"123" forState:UIControlStateNormal];
//        self.selectButton.titleLabel.lineBreakMode = UILineBreakModeClip;
        
        [self addSubview:self.selectButton];
        [self.selectButton setFrame:CGRectMake(5, 6, 75, 31)];

    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float cancelButtonWidth = 65.0;
    UITextField *searchField = [self.subviews objectAtIndex:1];
    
    if (self.showsCancelButton == YES)
    {
        [self.selectButton removeFromSuperview];
        [searchField setFrame:CGRectMake(5, 6, self.frame.size.width + 100 - 100 - cancelButtonWidth, 31)];
    }
    else
    {
        [self addSubview:self.selectButton];
        [searchField setFrame:CGRectMake(90, 6, self.frame.size.width - 100, 31)];
    }

}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    

//    self.autoresizesSubviews = YES;
//    
//    [self setShowsCancelButton:NO animated:NO];
//    
//    
//    UITextField *textField = [self.subviews objectAtIndex:1];
//    [textField setFrame:CGRectMake(90,5,250,31)];
//    textField.backgroundColor=[UIColor clearColor];
//    
//    UIButton *settings=[UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [settings setFrame:CGRectMake(10, 5, 70, 31)];
//    [self addSubview:settings];
}

@end
