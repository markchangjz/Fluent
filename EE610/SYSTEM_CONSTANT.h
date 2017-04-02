//
//  SYSTEM_CONSTANT.h
//  EE610
//
//  Created by JzChang on 13/3/18.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#ifdef UI_USER_INTERFACE_IDIOM
    #define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    #define IS_IPHONE !IS_IPAD
#else
    #define IS_IPAD false
    #define IS_IPHONE !IS_IPAD
#endif

#define DOWN_VIEW_WIDTH (IS_IPAD ? 350 : 275)
#define PLAYLIST_CELL_HEIGHT 60
#define SETTINGS_CELL_HEIGHT (IS_IPAD ? 50 : 45)
#define TIME_OUT 60.0