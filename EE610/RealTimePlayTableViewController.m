//
//  RealTimePlayTableViewController.m
//  EE610
//
//  Created by JzChang on 13/4/22.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "RealTimePlayTableViewController.h"
#import "NSUserDefaults_KEY.h"
#import "RealTimePlaylistParser.h"
#import "CheckNetwork.h"
#import "UIImageResizing.h"
#import "SYSTEM_CONSTANT.h"
#import "RealTimeVideoInfoTableViewController.h"

@interface RealTimePlayTableViewController () <RealTimePlaylistParserDelegate, RealTimeVideoInfoTableViewControllerDelegate> {
    NSUserDefaults *userDefaults;
    NSString *parserString;                                     // 需要parser的URL
    NSURLConnection *connection;
    RealTimePlaylistParser *playlistParser;
    NSString *transcodeVideoBR;
    BOOL PulledTableView;
}

@property (strong, nonatomic) NSArray *parserResult;            // 儲存解析 Playlist XML 後的資料
@property (strong, nonatomic) UIButton *setBtn;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation RealTimePlayTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configView];
    
    // 設定表格下拉更新
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshPlaylist) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PulledTableView = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{    
    NSString *killRealTimeProcessURL = [[parserString stringByAppendingPathComponent:@"transcode"] stringByAppendingPathComponent:@"KillLiveHLS.php"];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:killRealTimeProcessURL]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [super viewWillDisappear:animated];
}

- (void)configView
{
    // 設定 Table View 外型
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone]; // 無分隔線
    self.tableView.backgroundColor = [UIColor darkGrayColor];
    
    self.navigationItem.title = NSLocalizedString(@"即時處理播放", @"Live Convert");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Function

// 讀取 Playlist XML 資料結構
- (void)parserPlaylist:(NSString *)urlString
{    
    //  檢查有網路才解析 XML
    if ([CheckNetwork connectedToNetworkAndShowWarning]) {
        playlistParser = [[RealTimePlaylistParser alloc] init];
        playlistParser.delegate = self; // 設定 delegate
        [playlistParser initParserURL:urlString];
        
        if (!PulledTableView) {
            // 顯示 ActivityIndicatorView
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinner]; // 要封裝為 UIBarButtonItem
        }
    }
    else {
        [self.refreshControl endRefreshing]; // 停止 Table View 的下拉更新中 indicator 轉動
    }
}

- (void)readRealTimePlaylist
{
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:STORE_IP_KEY] != nil) {
        parserString = [NSString stringWithFormat:@"http://%@", [[[[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"IP"] stringByAppendingPathComponent:[[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"Directory"]] stringByAppendingPathComponent:@"RealTimeProcess"]];
        [self parserPlaylist:parserString];
    }
}

- (void)playRealTimeVideoItem:(NSDictionary *)videoItem
{
    // 顯示 ActivityIndicatorView
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinner]; // 要封裝為 UIBarButtonItem
        
    dispatch_queue_t realTimeProcessQueue = dispatch_queue_create("realTimeProcessQueue", NULL);
    
    dispatch_async(realTimeProcessQueue, ^{
        
        NSDictionary *quality = [userDefaults objectForKey:STORE_QUALITY_KEY];
        transcodeVideoBR = [[quality allValues] objectAtIndex:0];
        
        NSString *realTimeProcessURL;
        
        if ([transcodeVideoBR isEqualToString:@""]) {
            realTimeProcessURL = [[parserString stringByAppendingPathComponent:@"transcode"] stringByAppendingPathComponent:[NSString stringWithFormat:@"LiveHLS.php?videoName=%@", [videoItem objectForKey:@"name"]]];
        }
        else {
            realTimeProcessURL = [[parserString stringByAppendingPathComponent:@"transcode"] stringByAppendingPathComponent:[NSString stringWithFormat:@"LiveHLS.php?videoName=%@&vBitrate=%@", [videoItem objectForKey:@"name"], transcodeVideoBR]];
        }
        
        // 使用 urlencode
        realTimeProcessURL = [realTimeProcessURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:realTimeProcessURL]];
        connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    });
    
    [self performSelector:@selector(playRealTimeVideo:) withObject:[videoItem objectForKey:@"name"] afterDelay:1.0];
}

#pragma mark - RealTimePlaylistParserDelegate

- (void)xmlParserEnd
{
    // 解析結果資料
    self.parserResult = [[NSArray alloc] initWithArray:playlistParser.result];
        
    [self.refreshControl endRefreshing]; // 停止 Table View 的下拉更新中 indicator 轉動
    [self performSelector:@selector(updateTable) withObject:nil afterDelay:0.5];
}

#pragma mark - RealTimeVideoInfoTableViewControllerDelegate

- (void)playSelectRealTimeVideoItem:(NSDictionary *)videoItem
{
    [self playRealTimeVideoItem:videoItem];
}

#pragma mark - selector

// 更新 Table View 資料 (reloadData)
- (void)updateTable
{       
    // 重載 tableView 資料
    [UIView transitionWithView:self.tableView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [self.tableView reloadData];
                    }
                    completion: ^(BOOL finished) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        // 設定 rightBarButtonItem (設定按鈕)
                        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.setBtn];
                    }];
}

// 下拉更新執行動作
- (void)refreshPlaylist
{
    PulledTableView = YES;
    [self readRealTimePlaylist];
}

- (void)clickSetting:(UIButton *)sender
{
    [self.delegate enterSettingsMode];
}

- (void)tappedOutsideView:(UITapGestureRecognizer *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playRealTimeVideoDelegate:(NSDictionary *)playData
{
    // 換回原本設定按鈕
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.setBtn];
    
    [self.delegate playRealTimeVideoURL:[playData objectForKey:@"URL"] andViedoName:[playData objectForKey:@"NAME"]];
}

- (void)playRealTimeVideo:(NSString *)videoName
{   
    NSString *realTimePlaylist = [[parserString stringByAppendingPathComponent:@"transcode"] stringByAppendingPathComponent:@"live.m3u8"];
    
    realTimePlaylist = [realTimePlaylist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // 測試連接 *.m3u8 使用多執行緒執行
    dispatch_queue_t connectQueue = dispatch_queue_create("connectQueue", NULL);
    
    dispatch_async(connectQueue, ^{
        while ([[NSData dataWithContentsOfURL:[NSURL URLWithString:realTimePlaylist]] length] == 0) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
//        NSString *downloadM3U8text = @"";
//        while ([downloadM3U8text isEqualToString:@""]) {
//            NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:realTimePlaylist]];
//            NSLog(@">> %@", urlData);
//            if (urlData.length == 0) {
//                NSLog(@"nil");
//            }
//            downloadM3U8text = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
//        }
        
//        while (true) {
//            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:realTimePlaylist]];
//            NSURLResponse *response = nil;
//            NSError *error = nil;
//            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//            NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
        
//            if (httpStatus == 200) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSelector:@selector(playRealTimeVideoDelegate:)
                               withObject:@{@"URL": [NSURL URLWithString:realTimePlaylist], @"NAME": videoName}
                               afterDelay:0.1];
                    [connection cancel];
                });
    
//                break;
//            }
//        }
    });
}

- (void)accessoryButtonTapped_TableView:(UIButton *)sender event:(id)event
{
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    
	if (indexPath != nil) {
        [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.parserResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Real Time Play Cell";
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell setSelectedBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_sel_bg1.png"]]];
    }
    
    // 設定 Cell Style
    cell.textLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    // 客制化 cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton
    UIButton *infoBtn_searchResultsTableView = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [infoBtn_searchResultsTableView setFrame:CGRectMake(0.0, 0.0, 30.0, 45.0)];
    
    // 固定 icon 大小
//    UIImage *infoImage = [UIImageResizing imageFromImage:[UIImage imageNamed:@"info.png"] resizeToWidth:25.0 andHeight:25.0];
//    infoImage = [infoImage stretchableImageWithLeftCapWidth:floorf(infoImage.size.width/2) topCapHeight:floorf(infoImage.size.height/2)];
    
    [infoBtn_searchResultsTableView setImage:[UIImage imageNamed:@"info.png"] forState:UIControlStateNormal];
    [infoBtn_searchResultsTableView addTarget:self action:@selector(accessoryButtonTapped_TableView:event:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.accessoryView = infoBtn_searchResultsTableView;    

    // 設定 Table View 顯示資料
    NSDictionary *item = [self.parserResult objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [item objectForKey:@"name"];
    cell.detailTextLabel.text = [item objectForKey:@"duration"];
    cell.imageView.image = [UIImageResizing imageWithImage:[item objectForKey:@"image"] scaledToSize:CGSizeMake(75, 50)]; //[item objectForKey:@"image"];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *deleteItem = [self.parserResult objectAtIndex:indexPath.row];
        NSString *deleteURL = [[parserString stringByAppendingPathComponent:@"deleteLiveVideo.php?name="] stringByAppendingString:[deleteItem objectForKey:@"name"]];
        // 使用 urlencode
        deleteURL = [deleteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
        NSMutableArray *mParserResult = [self.parserResult mutableCopy];
        [mParserResult removeObjectAtIndex:indexPath.row];
        self.parserResult = [mParserResult copy];
        
        // 刪除對應的表格項目
        [self performSelector:@selector(updateTable) withObject:nil afterDelay:0.5];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        dispatch_queue_t deleteLiveVideoProcessQueue = dispatch_queue_create("deleteLiveVideoProcessQueue", NULL);
        
        dispatch_async(deleteLiveVideoProcessQueue, ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:deleteURL]];
            [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        });
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self playRealTimeVideoItem:[self.parserResult objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 設定 Cell 顏色
    [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]]];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{    
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    RealTimeVideoInfoTableViewController *realTimeVideoInfoTVC = [[RealTimeVideoInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    realTimeVideoInfoTVC.parserString = parserString;
    realTimeVideoInfoTVC.delegate = self;

    UINavigationController *navVideoInfoTVC = [[UINavigationController alloc] initWithRootViewController:realTimeVideoInfoTVC];
    
    if (IS_IPAD) {
        // 設定 Modal 外型
        [navVideoInfoTVC setModalPresentationStyle:UIModalPresentationFormSheet];
        [navVideoInfoTVC setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    }
    
    realTimeVideoInfoTVC.videoInfo = [self.parserResult objectAtIndex:indexPath.row];
        
    // 顯示 Modal View
    [self presentViewController:navVideoInfoTVC animated:YES completion:nil];
    
    if (IS_IPAD) {
        UIView *dimmingView = [self.view.window.subviews objectAtIndex:1]; // 顯示 Modal View 後, 周圍灰黑色的 View
        [dimmingView addGestureRecognizer:self.tapGesture];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *numberOfVideoLbl = [[UILabel alloc] init];
    numberOfVideoLbl.textAlignment = NSTextAlignmentCenter;
    numberOfVideoLbl.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    numberOfVideoLbl.textColor = [UIColor darkTextColor];
    numberOfVideoLbl.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"footer_bg.png"]];
    numberOfVideoLbl.alpha = 0.6;
    numberOfVideoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"共有 %d 部影片", @"%d Videos"), self.parserResult.count];
    
    return numberOfVideoLbl;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PLAYLIST_CELL_HEIGHT;
}

#pragma mark - Setter

- (void)setIpToolbarItems:(NSArray *)ipToolbarItems
{
    if (_ipToolbarItems != ipToolbarItems) {
        _ipToolbarItems = ipToolbarItems;
        self.toolbarItems = self.ipToolbarItems;
        
        //  避免換了網路位址點選到舊的網路位址資料
        self.parserResult = nil;
        [self.tableView reloadData];
        
        [self readRealTimePlaylist];
    }
}

#pragma mark - lazy instantiation

- (UIButton *)setBtn
{
    if (!_setBtn) {
        UIImage *setImg = [UIImage imageNamed:@"settings.png"];
        _setBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_setBtn addTarget:self action:@selector(clickSetting:) forControlEvents:UIControlEventTouchUpInside];
        [_setBtn setShowsTouchWhenHighlighted:YES];
        [_setBtn setImage:setImg forState:UIControlStateNormal];
        [_setBtn setBounds:CGRectMake(0, 0, setImg.size.width, setImg.size.height)];
    }
    
    return _setBtn;
}

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutsideView:)];
        [_tapGesture setNumberOfTapsRequired:1];
        [_tapGesture setNumberOfTapsRequired:1];
    }
    
    return _tapGesture;
}

- (UIActivityIndicatorView *)spinner
{
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_spinner startAnimating];
    }
    
    return _spinner;
}

@end
