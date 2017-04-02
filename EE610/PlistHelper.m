//
//  PlistHelper.m
//  EE610
//
//  Created by JzChang on 13/3/18.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "PlistHelper.h"

@implementation PlistHelper

+ (NSString *)plistFilePathOfIpData
{
    // 取得 Document 檔案路徑
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // plist 檔名
    NSString *plistPath = [docPath stringByAppendingPathComponent:@"ipData.plist"];
    
    return plistPath;
}

+ (NSString *)plistFilePathOfUrlData
{
    // 取得 Document 檔案路徑
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // plist 檔名
    NSString *plistPath = [docPath stringByAppendingPathComponent:@"urlData.plist"];
    
    return plistPath;
}

@end
