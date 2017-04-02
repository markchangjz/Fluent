//
//  CheckNetwork.h
//  chkNetwork
//
//  Created by JzChang on 13/3/22.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#include <netinet/in.h>
#import <SystemConfiguration/SCNetworkReachability.h>

/*
 需要先 import "SystemConfiguration" framework
 參考網址: http://furnacedigital.blogspot.tw/2010/12/blog-post_27.html
 */

@interface CheckNetwork : NSObject

+ (BOOL)connectedToNetwork;
+ (BOOL)connectedToNetworkAndShowWarning;

@end
