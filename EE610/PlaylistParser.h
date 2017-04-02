//
//  PlaylistParser.h
//  playlistXML
//
//  Created by JzChang on 13/3/2.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {tagId, tagPubDate, tagName, tagQuality, tagResolution, tagDuration, tagUnknown} PlaylistTag;

@protocol PlaylistParserDelegate <NSObject>

- (void)xmlParserEnd;                                               // XML 解析結束

@end

@interface PlaylistParser : NSObject <NSXMLParserDelegate> {
    NSMutableDictionary *videoItem;                                 // 儲存單一個 videoItem tag 裡整個資料
    NSString *nodeContent;                                          // tag 裡的本文
    PlaylistTag currentTag;                                         // 目前 XML 解析到的 tag
    BOOL startVideoItem;                                            // YES:<videoItem>, NO:</videoItem>
}

@property (weak, nonatomic) id <PlaylistParserDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *result;               // 儲存整個 XML 解析到的資料
@property (strong, nonatomic) NSString *PlaylistHostName;           // 主機名稱

- (void)initParserURL:(NSString *)url;                              // 初始化欲解析的 XML URL

@end
