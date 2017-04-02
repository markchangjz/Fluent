//
//  PlaylistParser.m
//  playlistXML
//
//  Created by JzChang on 13/3/2.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "PlaylistParser.h"

@implementation PlaylistParser {
    NSString *urlStr;
}

- (void)initParserURL:(NSString *)url
{
    if (!(url == nil)) {        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        nodeContent = @"";
        urlStr = url;
        
        // Parser 時使用多執行緒執行
        dispatch_queue_t parserXMLQueue = dispatch_queue_create("parserXMLQueue", NULL);
        
        dispatch_async(parserXMLQueue, ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];//[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3];
            NSError *error = [[NSError alloc] init];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
                        
            // 連線逾時
//            if ([error.userInfo objectForKey:@"NSLocalizedDescription"] != nil) {
//                // 回到主執行緒
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.delegate xmlParserEnd];
//
//                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error.userInfo objectForKey:@"NSErrorFailingURLStringKey"]
//                                                                        message:[error.userInfo objectForKey:@"NSLocalizedDescription"]
//                                                                        delegate:self
//                                                                cancelButtonTitle:NSLocalizedString(@"好", @"OK")
//                                                                otherButtonTitles:nil];
//                        [alertView show];           
//                });
//            }            
            
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
            parser.delegate = self; // 設定 delegate
            
            [parser parse];
        });
    }   
    else {
        [self.delegate xmlParserEnd];
    }
}

/*
 <videoItem>
    <id>...................</id>
    <pubDate>.........</pubDate>
    <name>...............</name>
    <quality>.........</quality>
    <resolution>...</resolution>
    <duration>.......</duration>
 </videoItem>
 */

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (startVideoItem) {
        if ([elementName isEqualToString:@"id"]) {
            currentTag = tagId;
        }
        else if ([elementName isEqualToString:@"pubDate"]) {
            currentTag = tagPubDate;
        }
        else if ([elementName isEqualToString:@"name"]) {
            currentTag = tagName;
        }
        else if ([elementName isEqualToString:@"quality"]) {
            currentTag = tagQuality;
        }
        else if ([elementName isEqualToString:@"resolution"]) {
            currentTag = tagResolution;
        }
        else if ([elementName isEqualToString:@"duration"]) {
            currentTag = tagDuration;
        }
        else {
            currentTag = tagUnknown;
        }
    }
    
    if ([elementName isEqualToString:@"playlist"]) {
        self.PlaylistHostName = [attributeDict objectForKey:@"HOST_NAME"];
    }
    
    if ([elementName isEqualToString:@"videoItem"]) {
        startVideoItem = YES; // <videoItem>
        videoItem = [[NSMutableDictionary alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"videoItem"]) {
        startVideoItem = NO; // </videoItem>
            
        NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@.jpg", urlStr, [videoItem objectForKey:@"id"], [videoItem objectForKey:@"name"]];
        NSString *escapedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *thumbnail = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:escapedUrlString]]];
        
        [videoItem setValue:thumbnail forKey:@"image"];
        
        [self.result addObject:videoItem];
    }
    
    if (startVideoItem && currentTag != tagUnknown) {
        [videoItem setValue:nodeContent forKey:elementName];
        nodeContent = @"";
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (currentTag == tagUnknown || !startVideoItem) {
        return;
    }
    
    nodeContent = [nodeContent stringByAppendingString:[string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
}

// 解析開始
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

// 解析結束
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    // 回到主執行緒更新資料
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate xmlParserEnd];
    });
}

#pragma mark - lazy instantiation

- (NSMutableArray *)result
{
    if (!_result) {
        _result = [[NSMutableArray alloc] init];
    }
    
    return _result;
}

@end
