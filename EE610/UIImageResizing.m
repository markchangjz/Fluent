//
//  UIImageResizing.m
//  MyMoviePlayer2
//
//  Created by JzChang on 12/10/15.
//  Copyright (c) 2012年 JzChang. All rights reserved.
//

#import "UIImageResizing.h"

@implementation UIImageResizing

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0);
        } else {
            UIGraphicsBeginImageContext(newSize);
        }
    } else {
        UIGraphicsBeginImageContext(newSize);
    }
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageFromImage:(UIImage *)oriImage resizeToWidth:(NSUInteger)W andHeight:(NSUInteger)H
{
    //使用"layer" class method建立CALayer物件
    CALayer *layer = [CALayer layer];
    //設定CALayer的frame大小
    layer.frame = CGRectMake(0, 0, W, H);
    
    //設定CALayer的內容為image物件
    layer.contents = (id)oriImage.CGImage;
    
    UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
