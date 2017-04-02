//
//  PlistHelper.h
//  EE610
//
//  Created by JzChang on 13/3/18.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlistHelper : NSObject

+ (NSString *)plistFilePathOfIpData;    // 回傳儲存 IP 位址 plist 檔案位置
+ (NSString *)plistFilePathOfUrlData;   // 回傳儲存開啟 URL 位址 plist 檔案位置

@end
