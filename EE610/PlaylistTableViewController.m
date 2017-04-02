//
//  PlaylistTableViewController.m
//  playlistXML
//
//  Created by JzChang on 13/3/2.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "PlaylistTableViewController.h"
#import "PlaylistParser.h"
#import "VideoInfoTableViewController.h"
#import "CustomSearchBar.h"
#import "SYSTEM_CONSTANT.h"
#import "ServerListTableViewController.h"
#import "CheckNetwork.h"
#import "NSUserDefaults_KEY.h"
#import "PlistHelper.h"
#import "UIImageResizing.h"
#import "RealTimePlayTableViewController.h"

typedef enum {SortByName, SortByPubDate} VideoSortBy;

@interface PlaylistTableViewController () <PlaylistParserDelegate, VideoInfoTableViewControllerDelegate, ServerListTableViewControllerDelegate, RealTimePlayTableViewControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIActionSheetDelegate> {
    NSString *parserString;                                                     // 需要parser的URL
    NSUserDefaults *userDefaults;
    UISearchDisplayController *videoSearchDisplayController;
    PlaylistParser *playlistParser;                                             // 解析 Playlist
    VideoSortBy currentVideoSortBy;                                             // 紀錄目前使用者選擇影片列表的排序方式
    BOOL connected;                                                             // YES:已連線取得 XML 解析後資料
    BOOL PulledTableView;
    BOOL isDeletedSearchVideo;
}
    
@property (strong, nonatomic) NSArray *parserResult, *filteredArray;            // 儲存解析 Playlist XML 後的資料, 儲存 SearchBar 搜尋後的資料
@property (strong, nonatomic) NSArray *parserResultName, *parserResultPubDate;  // 依影片名稱排序, 依影片發佈日期排序
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UIPopoverController *showPopover;
@property (strong, nonatomic) UIBarButtonItem *flexibleSpace;
@property (strong, nonatomic) ServerListTableViewController *serverListTVC;     // 選擇網路位址列表
@property (strong, nonatomic) CustomSearchBar *videoSearchBar;
@property (strong, nonatomic) RealTimePlayTableViewController *realTimePlayTVC;
@property (strong, nonatomic) UIButton *serverBtn, *setBtn;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation PlaylistTableViewController

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

    // 預設排序依名稱
    currentVideoSortBy = SortByName;
    
    // 設定 Table View 的 Search Bar 
    self.tableView.tableHeaderView = self.videoSearchBar;

    // searchDisplayController (必須是全域變數)
    videoSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.videoSearchBar contentsController:self];
    videoSearchDisplayController.delegate = self;
    videoSearchDisplayController.searchResultsDataSource = self;
    videoSearchDisplayController.searchResultsDelegate = self;
    
    // 設定表格下拉更新
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshPlaylist) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // 如有記錄上次使用者選擇 IP 則直接連線上次連線的 IP
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:STORE_IP_KEY] != nil) {
        NSString *pcNameStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"PC_NAME"];
        NSString *ipStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"IP"];
        NSString *directoryStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"Directory"];
        NSDictionary *lastSelectData = @{@"PC_NAME": pcNameStr, @"IP": ipStr, @"Directory": directoryStr};
        
        [self selectVideoData:lastSelectData];
    }
}

- (void)configView
{
    // 設定 Navigation 標題(Title)
    self.navigationItem.title = NSLocalizedString(@"播放清單", @"Playlist");
    
    // 設定 Navigation 外型
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController setToolbarHidden:NO];
    
    // 設定 Navigation 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];

    // 設定 leftBarButtonItem (伺服器按鈕)
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.serverBtn];
    
    // 設定 rightBarButtonItem (設定按鈕)
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.setBtn];
    
    // 設定 Table View 外型
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone]; // 無分隔線
    self.tableView.backgroundColor = [UIColor darkGrayColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 加入監測關閉 Search Bar 顯示鍵盤的 Notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeKeyboard:)
                                                 name:@"closeKeyboardNotification"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 移除 Notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Function

- (void)updateTableViewOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updateData
{
    if (oriData == nil && updateData == nil) {
        
        // 清空 Table View 資料
        self.navigationItem.title = NSLocalizedString(@"播放清單", @"Playlist");
        self.parserResult = nil;
        self.toolbarItems = nil;
        parserString = nil;
        
        [self.tableView reloadData];
    }
    else if ([userDefaults objectForKey:STORE_IP_KEY] != nil) { // 如果有上一次點選紀錄才執行
        
        // 取出上次連線記錄
        NSString *pcNameStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"PC_NAME"];
        NSString *ipStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"IP"];
        NSString *directoryStr = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"Directory"];
        NSDictionary *lastData = @{@"PC_NAME": pcNameStr, @"IP": ipStr, @"Directory": directoryStr};
        
        // 比較上次連線記錄是否與修改前的資料是否同一筆, 一樣就需同時更新上次連線記錄
        if ([lastData isEqualToDictionary:oriData]) {            
            [userDefaults setObject:updateData forKey:STORE_IP_KEY];
            [userDefaults synchronize];
            
            self.navigationItem.title = [updateData objectForKey:@"PC_NAME"];
            
            // 如果修改了網路位址(IP)或目錄路徑(Directory), 就必須重新解析 Playlist XML 
            if (![[lastData objectForKey:@"IP"] isEqualToString:[updateData objectForKey:@"IP"]] ||
                ![[lastData objectForKey:@"Directory"] isEqualToString:[updateData objectForKey:@"Directory"]]) {
                [self.navigationController popToRootViewControllerAnimated:YES];
                parserString = [@"http://" stringByAppendingString:[[updateData objectForKey:@"IP"] stringByAppendingPathComponent:[updateData objectForKey:@"Directory"]]];
                [self parserPlaylist:parserString];                
            }
        }
    }
}

#pragma mark - Private Function

// 讀取 Playlist XML 資料結構
- (void)parserPlaylist:(NSString *)urlString
{
    //  檢查有網路才解析 XML
    if ([CheckNetwork connectedToNetworkAndShowWarning]) {
        
        // 連線逾時
        connected = NO;
        [self performSelector:@selector(checkConnected) withObject:nil afterDelay:TIME_OUT];
        
        playlistParser = [[PlaylistParser alloc] init];
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

- (void)checkConnected
{
    if (!connected) {        
        connected = YES;
        
        [self.delegate playURL:nil andViedoName:nil];
        self.parserResult = nil;
        [self.refreshControl endRefreshing];
        [self updateTable];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"警告", @"Warning")
                                                            message:NSLocalizedString(@"連線逾時", @"Connection timed out")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"好", @"OK")
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger rows = 0;
    
    if (tableView == self.tableView) {
        rows = self.parserResult.count;
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        // 設定搜尋條件
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains[c] %@", @"name", self.videoSearchBar.text];
        NSMutableArray *mParserResult = [self.parserResult mutableCopy];
        [mParserResult removeObjectAtIndex:0]; // 搜尋時略過即時處理播放 Cell
        
        self.filteredArray = [mParserResult filteredArrayUsingPredicate:predicate];
        rows = self.filteredArray.count;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Playlist Cell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    [cell setSelectedBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_sel_bg1.png"]]]; 

    // 設定 Cell Style
    cell.textLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    NSDictionary *item = [[NSDictionary alloc] init];
    
    if (tableView == self.tableView) {
                
        if (indexPath.row < self.parserResult.count) {
            item = [self.parserResult objectAtIndex:indexPath.row];
        }     
        
        // 客制化 cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton
        UIButton *infoBtn_TableView = [UIButton buttonWithType:UIButtonTypeCustom];
        [infoBtn_TableView setFrame:CGRectMake(0.0, 0.0, 30.0, 45.0)];
        
        // 固定 icon 大小
//        UIImage *infoImage = [UIImageResizing imageFromImage:[UIImage imageNamed:@"info.png"] resizeToWidth:25.0 andHeight:25.0];
//        infoImage = [infoImage stretchableImageWithLeftCapWidth:floorf(infoImage.size.width/2) topCapHeight:floorf(infoImage.size.height/2)];
        
        [infoBtn_TableView setImage:[UIImage imageNamed:@"info.png"] forState:UIControlStateNormal];
        [infoBtn_TableView addTarget:self action:@selector(accessoryButtonTapped_TableView:event:) forControlEvents:UIControlEventTouchUpInside];
        
        if (indexPath.row == 0) {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            // 設定 Cell 資料顯示
            cell.textLabel.text = [item objectForKey:@"name"];
            cell.imageView.image = [UIImage imageNamed:@"real_time.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]];
        }
        else {
            cell.accessoryView = infoBtn_TableView;
        
            // 設定 Cell 資料顯示
            cell.textLabel.text = [item objectForKey:@"name"];
            cell.detailTextLabel.text = [item objectForKey:@"duration"];
            cell.imageView.image = [UIImageResizing imageWithImage:[item objectForKey:@"image"] scaledToSize:CGSizeMake(75, 50)];
        }
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        item = [self.filteredArray objectAtIndex:indexPath.row];
        
        // 客制化 cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton
        UIButton *infoBtn_searchResultsTableView = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [infoBtn_searchResultsTableView setFrame:CGRectMake(0.0, 0.0, 30.0, 45.0)];
        
        // 固定 icon 大小
//        UIImage *infoImage = [UIImageResizing imageFromImage:[UIImage imageNamed:@"info.png"] resizeToWidth:25.0 andHeight:25.0];
//        infoImage = [infoImage stretchableImageWithLeftCapWidth:floorf(infoImage.size.width/2) topCapHeight:floorf(infoImage.size.height/2)];
        
        [infoBtn_searchResultsTableView setImage:[UIImage imageNamed:@"info.png"] forState:UIControlStateNormal];
        [infoBtn_searchResultsTableView addTarget:self action:@selector(accessoryButtonTapped_searchResultsTableView:event:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessoryView = infoBtn_searchResultsTableView;
        
        // 設定 Cell 資料顯示
        cell.textLabel.text = [item objectForKey:@"name"];
        cell.detailTextLabel.text = [item objectForKey:@"duration"];
        cell.imageView.image = [UIImageResizing imageWithImage:[item objectForKey:@"image"] scaledToSize:CGSizeMake(75, 50)];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        return (indexPath.row == 0) ? NO : YES;
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return YES;
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *deleteItem = [self.parserResult objectAtIndex:indexPath.row];
        NSString *deleteURL = [[parserString stringByAppendingPathComponent:@"deleteVideo.php?name="] stringByAppendingString:[deleteItem objectForKey:@"id"]];
        // 使用 urlencode
        deleteURL = [deleteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
        NSMutableArray *mParserResult = [self.parserResult mutableCopy];
        NSMutableArray *mParserResultName = [self.parserResultName mutableCopy];
        NSMutableArray *mParserResultPubDate = [self.parserResultPubDate mutableCopy];
        
        [mParserResult removeObject:deleteItem];
        [mParserResultName removeObject:deleteItem];
        [mParserResultPubDate removeObject:deleteItem];
        
        self.parserResult = [mParserResult copy];
        self.parserResultName = [mParserResultName copy];
        self.parserResultPubDate = [mParserResultPubDate copy];
        
        // 刪除對應的表格項目
        [self performSelector:@selector(updateTable) withObject:nil afterDelay:0.5];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

        dispatch_queue_t deleteVideoProcessQueue = dispatch_queue_create("deleteVideoProcessQueue", NULL);
        
        dispatch_async(deleteVideoProcessQueue, ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:deleteURL]];
            [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        });
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *deleteItem = [self.filteredArray objectAtIndex:indexPath.row];
        NSString *deleteURL = [[parserString stringByAppendingPathComponent:@"deleteVideo.php?name="] stringByAppendingString:[deleteItem objectForKey:@"id"]];
        // 使用 urlencode
        deleteURL = [deleteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
        /*
         self.tableView 和 self.searchDisplayController.searchResultsTableView 兩邊資料都要一起刪除
         否則 self.searchDisplayController.searchResultsTableView 在刪除 Cell 會有錯誤
         */
        
        NSMutableArray *mFilteredArray = [self.filteredArray mutableCopy];
        NSMutableArray *mParserResult = [self.parserResult mutableCopy];
        NSMutableArray *mParserResultName = [self.parserResultName mutableCopy];
        NSMutableArray *mParserResultPubDate = [self.parserResultPubDate mutableCopy];
        
        [mFilteredArray removeObject:deleteItem];
        [mParserResult removeObject:deleteItem];
        [mParserResultName removeObject:deleteItem];
        [mParserResultPubDate removeObject:deleteItem];
        
        self.filteredArray = [mFilteredArray copy];
        self.parserResult = [mParserResult copy];
        self.parserResultName = [mParserResultName copy];
        self.parserResultPubDate = [mParserResultPubDate copy];
                
        // 刪除對應的表格項目
        isDeletedSearchVideo = YES;
        [self performSelector:@selector(updateSearchTable) withObject:nil afterDelay:0.5];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        dispatch_queue_t deleteVideoProcessQueue = dispatch_queue_create("deleteVideoProcessQueue", NULL);
        
        dispatch_async(deleteVideoProcessQueue, ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:deleteURL]];
            [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        });
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item;
    
    if (tableView == self.tableView) {
        if (indexPath.row == 0) {
            self.realTimePlayTVC.ipToolbarItems = self.toolbarItems;
            [self.navigationController pushViewController:self.realTimePlayTVC animated:YES];
        }
        else {
            item = [self.parserResult objectAtIndex:indexPath.row];
            
            NSString *urlPath = [NSString stringWithFormat:@"%@/%@/variant.m3u8", parserString, [item objectForKey:@"id"]];
            NSString *escapedUrlString = [urlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [self.delegate playURL:[NSURL URLWithString:escapedUrlString] andViedoName:[item objectForKey:@"name"]];
        }
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.view endEditing:YES]; // 關閉鍵盤, 或[searchBar resignFirstResponder];
        item = [self.filteredArray objectAtIndex:indexPath.row];
        
        NSString *urlPath = [NSString stringWithFormat:@"%@/%@/variant.m3u8", parserString, [item objectForKey:@"id"]];
        NSString *escapedUrlString = [urlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [self.delegate playURL:[NSURL URLWithString:escapedUrlString] andViedoName:[item objectForKey:@"name"]];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // 發出關閉鍵盤通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboardNotification" object:nil];
    
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    VideoInfoTableViewController *videoInfoTVC = [[VideoInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    videoInfoTVC.parserString = parserString;
    videoInfoTVC.delegate = self;
    
    UINavigationController *navVideoInfoTVC = [[UINavigationController alloc] initWithRootViewController:videoInfoTVC];
    
    if (IS_IPAD) {
        // 設定 Modal 外型
        [navVideoInfoTVC setModalPresentationStyle:UIModalPresentationFormSheet];
        [navVideoInfoTVC setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    }
        
    if (tableView == self.tableView) {
        videoInfoTVC.videoInfo = [self.parserResult objectAtIndex:indexPath.row];
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.view endEditing:YES]; // 關閉鍵盤, 或[searchBar resignFirstResponder];
        videoInfoTVC.videoInfo = [self.filteredArray objectAtIndex:indexPath.row];
    }
    
    // 顯示 Modal View
    [self presentViewController:navVideoInfoTVC animated:YES completion:nil];
    
    if (IS_IPAD) {
        UIView *dimmingView = [self.view.window.subviews objectAtIndex:1]; // 顯示 Modal View 後, 周圍灰黑色的 View
        [dimmingView addGestureRecognizer:self.tapGesture];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 設定 Cell 顏色
    [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PLAYLIST_CELL_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *numberOfVideoLbl = [[UILabel alloc] init];
    numberOfVideoLbl.textAlignment = NSTextAlignmentCenter;
    numberOfVideoLbl.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    numberOfVideoLbl.textColor = [UIColor darkTextColor];
    numberOfVideoLbl.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"footer_bg.png"]];
    numberOfVideoLbl.alpha = 0.6;

    if (tableView == self.tableView) {
        numberOfVideoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"共有 %d 部影片", @"%d Videos"), (self.parserResult.count > 0) ? (self.parserResult.count - 1) : 0];  
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView) {
        numberOfVideoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"共有 %d 部影片", @"%d Videos"), self.filteredArray.count];
    }
    
    return numberOfVideoLbl;
}

#pragma mark - PlaylistParserDelegate

- (void)xmlParserEnd
{
    // XML Parser 結束(parserDidEndDocument:)後觸發
    connected = YES;
    
    // 設定 Navigation Toolbar
    NSString *ipAddress = [[userDefaults objectForKey:STORE_IP_KEY] objectForKey:@"IP"];
    NSString *hostName = playlistParser.PlaylistHostName;
    
    if (ipAddress != nil && hostName != nil) {
        UILabel *ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, DOWN_VIEW_WIDTH - 20, 20)];
        [ipLabel setText:[NSString stringWithFormat:@"%@(%@)", ipAddress, hostName]];
        [ipLabel setBackgroundColor:[UIColor clearColor]];
        [ipLabel setTextColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7]];
        [ipLabel setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:IS_IPAD ? 16 : 14]];
        [ipLabel setTextAlignment:NSTextAlignmentCenter];
        self.toolbarItems = @[self.flexibleSpace, [[UIBarButtonItem alloc] initWithCustomView:ipLabel], self.flexibleSpace];
    }
    
    //  檢查「有網路」 & 「已連線到伺服器」 才加入"即時處理播放" Cell
    if (!([CheckNetwork connectedToNetwork] && self.toolbarItems)) {
        [self.refreshControl endRefreshing]; // 停止 Table View 的下拉更新中 indicator 轉動
        return;
    }
    
    // 解析結果資料
    NSArray *tempParserResult = [[NSArray alloc] initWithArray:playlistParser.result];
    
    // 影片名稱排序
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    self.parserResultName = [tempParserResult sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    // 發佈日期排序
    self.parserResultPubDate = tempParserResult;
    
    NSMutableArray *RealTimeCellByName = [[NSMutableArray alloc] initWithArray:@[@{@"name": NSLocalizedString(@"即時處理播放", @"Live Convert")}]];
    [RealTimeCellByName addObjectsFromArray:self.parserResultName];
    self.parserResultName = [RealTimeCellByName copy];
    
    NSMutableArray *RealTimeCellByDate = [[NSMutableArray alloc] initWithArray:@[@{@"name": NSLocalizedString(@"即時處理播放", @"Live Convert")}]];
    [RealTimeCellByDate addObjectsFromArray:self.parserResultPubDate];
    self.parserResultPubDate = [RealTimeCellByDate copy];
    
    // 系統預設使用影片名稱排序
    if (currentVideoSortBy == SortByName) {
        self.parserResult = [RealTimeCellByName copy];
    }
    else if (currentVideoSortBy == SortByPubDate) {
        self.parserResult = [RealTimeCellByDate copy];
    }
    
    [self.refreshControl endRefreshing]; // 停止 Table View 的下拉更新中 indicator 轉動
    [self performSelector:@selector(updateTable) withObject:nil afterDelay:0.5];
}

#pragma mark - RealTimePlayTableViewControllerDelegate

- (void)playRealTimeVideoURL:(NSURL *)fileURL andViedoName:(NSString *)name
{
    [self playSelectURL:fileURL andViedoName:name];
}

- (void)enterSettingsMode
{
    [self.delegate enterSettingsMode];
}

#pragma mark - VideoInfoTableViewControllerDelegate

- (void)playSelectURL:(NSURL *)fileURL andViedoName:(NSString *)name
{
    [self.delegate playURL:fileURL andViedoName:name];
}

#pragma mark - ServerListTableViewControllerDelegate

- (void)selectVideoData:(NSDictionary *)data
{
    if (data == nil) {
        if (IS_IPAD) {
            [self.showPopover dismissPopoverAnimated:YES];
        }
      
        return;
    }
    
    // 儲存選擇的 IP 和 Directory
    [userDefaults setObject:data forKey:STORE_IP_KEY];
    [userDefaults synchronize];
    
    self.navigationItem.title = [data objectForKey:@"PC_NAME"];
    self.toolbarItems = nil;
    self.parserResult = nil;
    
    if (IS_IPAD) {
        [self.showPopover dismissPopoverAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    // 解析 XML
    parserString = [@"http://" stringByAppendingString:[[data objectForKey:@"IP"] stringByAppendingPathComponent:[data objectForKey:@"Directory"]]];
    [self parserPlaylist:parserString];
}

- (void)selectOpenUrl:(NSURL *)url
{
    // absoluteString: 將 NSURL 轉型為 NSString
    if (IS_IPAD) {
        [self.delegate playURL:url andViedoName:[url absoluteString]];
    }
    else {
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     [self.delegate playURL:url andViedoName:[url absoluteString]];
                                 }];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
//    [self.navigationController setToolbarHidden:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
//    [self.navigationController setToolbarHidden:NO];
    [self.tableView setEditing:NO animated:NO];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // 有刪除 SearchBar 搜尋到的影片 (Cell) 才重載 TableView
    if (isDeletedSearchVideo) {
        [self updateTable];
        isDeletedSearchVideo = NO;
    }
}

#pragma mark - UISearchDisplayDelegate

// 設定 self.searchDisplayController.searchResultsTableView 外型
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    // 設定 Cell 高度
    tableView.rowHeight = 60.0f;
    // 設定無分隔線
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 設定背景顏色
    tableView.backgroundColor = [UIColor darkGrayColor];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // 影片名稱      
            currentVideoSortBy = SortByName;
            self.parserResult = self.parserResultName;
            break;
        case 1:
            // 發佈日期
            currentVideoSortBy = SortByPubDate;
            self.parserResult = self.parserResultPubDate;
            break;
        default:
            break;
    }
        
    [self updateTable];
}

#pragma mark - selector

- (void)clickSetting:(UIButton *)sender
{
    [self.delegate enterSettingsMode];
}

- (void)clickSorting:(UIButton *)sender
{
    if (IS_IPAD) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"排序方式", @"Sort by")
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"影片名稱", @"A - Z"), NSLocalizedString(@"最新日期", @"Newest - Oldest"), nil];
        
        [actionSheet showFromRect:sender.frame inView:self.view animated:YES];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"排序方式", @"Sort by")
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"取消", @"Cancel")
                                                   destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"影片名稱", @"A - Z"), NSLocalizedString(@"最新日期", @"Newest - Oldest"), nil];
        
        [actionSheet showInView:self.view];
    }
}

- (void)clickServerList:(UIButton *)sender
{
    UINavigationController *navServerListTVC = [[UINavigationController alloc] initWithRootViewController:self.serverListTVC];
    
    if (IS_IPAD) {
        // showPopover 目前是否已經顯示
        if (!self.showPopover.isPopoverVisible) {
        
            // 1. 設定要放到 popover 的 View Controller
            self.showPopover = [[UIPopoverController alloc] initWithContentViewController:navServerListTVC];
            
            // 2. 設定 popover 顯示的大小
            [self.showPopover setPopoverContentSize:CGSizeMake(DOWN_VIEW_WIDTH, 500)];
            // 或是在步驟1.前 show.contentSizeForViewInPopover = CGSizeMake(W, H);
            
            // 3. 顯示 popover
            [self.showPopover presentPopoverFromRect:sender.frame
                                              inView:sender
                            permittedArrowDirections:UIPopoverArrowDirectionUp
                                            animated:YES];
        }
        else {
            // 關閉 popover
            [self.showPopover dismissPopoverAnimated:YES];
        }
    }
    else {
        [self presentViewController:navServerListTVC animated:YES completion:nil];
    }
}

- (void)tappedOutsideView:(UITapGestureRecognizer *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 關閉 Search Bar 的鍵盤 - Notification
- (void)closeKeyboard:(NSNotification *)notification
{
    [self.view endEditing:YES];
}

// 下拉更新執行動作
- (void)refreshPlaylist
{
    PulledTableView = YES;
    [self parserPlaylist:parserString];
}

// 更新 Table View 資料 (reloadData)
- (void)updateTable
{    
    // 隱藏 search bar
    [UIView animateWithDuration:0.3
                          delay:0.5
                        options:(UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                         }
                     }];
    
    // 重載 tableView 資料
    [UIView transitionWithView:self.tableView
                      duration:0.5
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

- (void)updateSearchTable
{
    // 重載 tableView 資料
    [UIView transitionWithView:self.searchDisplayController.searchResultsTableView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [self.searchDisplayController.searchResultsTableView reloadData];
                    }
                    completion: ^(BOOL finished) {
                    }];
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

- (void)accessoryButtonTapped_searchResultsTableView:(UIButton *)sender event:(id)event
{
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.searchDisplayController.searchResultsTableView];
	NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:currentTouchPosition];
    
	if (indexPath != nil) {
        [self tableView:self.searchDisplayController.searchResultsTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

#pragma mark - lazy instantiation

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutsideView:)];
        [_tapGesture setNumberOfTapsRequired:1];
        [_tapGesture setNumberOfTapsRequired:1];
    }
    
    return _tapGesture;
}

- (ServerListTableViewController *)serverListTVC
{
    if (!_serverListTVC) {
        _serverListTVC = [[ServerListTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _serverListTVC.delegate = self;
    }
    
    return _serverListTVC;
}

- (UIBarButtonItem *)flexibleSpace
{
    if (!_flexibleSpace) {
        _flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                       target:nil
                                                                       action:nil];
    }
    
    return _flexibleSpace;
}

- (CustomSearchBar *)videoSearchBar
{
    if (!_videoSearchBar) {
        _videoSearchBar = [[CustomSearchBar alloc] init];
        _videoSearchBar.delegate = self;
        [_videoSearchBar sizeToFit];
        [_videoSearchBar setBarStyle:UIBarStyleBlack];
        [_videoSearchBar.customButton addTarget:self action:@selector(clickSorting:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _videoSearchBar;
}

- (RealTimePlayTableViewController *)realTimePlayTVC
{
    if (!_realTimePlayTVC) {
        _realTimePlayTVC = [[RealTimePlayTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _realTimePlayTVC.delegate = self;
        
    }
    
    return _realTimePlayTVC;
}

- (UIButton *)serverBtn
{
    if (!_serverBtn) {
        UIImage *serverImg = [UIImage imageNamed:@"server.png"];
        _serverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_serverBtn addTarget:self action:@selector(clickServerList:) forControlEvents:UIControlEventTouchUpInside];
        [_serverBtn setShowsTouchWhenHighlighted:YES];
        [_serverBtn setImage:serverImg forState:UIControlStateNormal];
        [_serverBtn setBounds:CGRectMake(0, 0, serverImg.size.width, serverImg.size.height)];
    }
    
    return _serverBtn;
}

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

- (UIActivityIndicatorView *)spinner
{
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_spinner startAnimating];
    }
    
    return _spinner;
}

@end
