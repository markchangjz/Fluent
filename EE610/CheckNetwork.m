//
//  CheckNetwork.m
//  chkNetwork
//
//  Created by JzChang on 13/3/22.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "CheckNetwork.h"

@implementation CheckNetwork

+ (BOOL)connectedToNetwork
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags) {
        NSLog(@"Error. Could not recover network reachability flags");
        return 0;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    
    return (isReachable && !needsConnection) ? YES : NO; 
}

+ (BOOL)connectedToNetworkAndShowWarning
{
    if (![self connectedToNetwork]) {
        UIAlertView *networkAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"連線失敗", @"Connection failed")
                                                                   message:NSLocalizedString(@"請啓用行動網路或Wi-Fi以下載資料", @"Enalbe mobile network or Wi-Fi to download data")
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"好", @"OK")
                                                         otherButtonTitles:nil];
        [networkAlertView show];
        
        return NO;
    }
    else {
        return YES;
    }    
}

@end
