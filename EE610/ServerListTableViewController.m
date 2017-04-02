//
//  ServerListTableViewController.m
//  EE610
//
//  Created by JzChang on 13/3/19.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "ServerListTableViewController.h"
#import "SYSTEM_CONSTANT.h"
#import "PlistHelper.h"
#import "OpenUrlTableViewController.h"

@interface ServerListTableViewController () <OpenUrlTableViewControllerDelegate> {
    NSString *plistPath; // plist 路徑
}

@property (strong, nonatomic) NSMutableArray *readStoreData;
@property (strong, nonatomic) OpenUrlTableViewController *openUrlTVC;

@end

@implementation ServerListTableViewController

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
    
    // 設定 plist 路徑
    plistPath = [PlistHelper plistFilePathOfIpData];
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 設定 Navigation 標題(Title)
    self.navigationItem.title = NSLocalizedString(@"選擇串流伺服器", @"Select Streaming Server");
    
    // 更新資料
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        self.readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
        [self.tableView reloadData];
    }
    
    if (IS_IPHONE) {
        UIBarButtonItem *closeBarBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                         target:self
                                                                                         action:@selector(clickClose:)];
        self.navigationItem.leftBarButtonItem = closeBarBtnItem;
    
        // 設定 Navigation Bar 背景
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - selector

- (void)clickClose:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.readStoreData.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Server List Cell";
    
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell setSelectedBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_sel_bg2.png"]]];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"開啓網址", @"Open URL");
        cell.imageView.image = [UIImage imageNamed:@"url.png"];
    }
    else {
        NSString *pcNameStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"PC_NAME"];       // 電腦名稱
        NSString *ipStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"IP"];                // 網路位址
        NSString *directoryStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"Directory"];  // 目錄路徑
        cell.textLabel.text = pcNameStr;
        cell.detailTextLabel.text = [ipStr stringByAppendingPathComponent:directoryStr];
        cell.imageView.image = [UIImage imageNamed:@"lan.png"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self.delegate selectVideoData:nil];
        
        UINavigationController *navOpenUrlTVC = [[UINavigationController alloc] initWithRootViewController:self.openUrlTVC];
        
        if (IS_IPAD) {
            [navOpenUrlTVC setModalPresentationStyle:UIModalPresentationPageSheet];
        }
                
        [self presentViewController:navOpenUrlTVC animated:YES completion:nil];
    }
    else {
        NSString *pcNameStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"PC_NAME"];       // 電腦名稱
        NSString *ipStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"IP"];                // 網路位址
        NSString *directoryStr = [[self.readStoreData objectAtIndex:indexPath.row - 1] objectForKey:@"Directory"];  // 目錄路徑
        
        NSDictionary *selectData = @{@"PC_NAME": pcNameStr, @"IP": ipStr, @"Directory": directoryStr};
        
        [self.delegate selectVideoData:selectData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SETTINGS_CELL_HEIGHT + 10;
}

#pragma mark - OpenUrlTableViewControllerDelegate

- (void)openUrl:(NSURL *)url
{
    [self.delegate selectOpenUrl:url];
}

#pragma mark - lazy instantiation

- (NSMutableArray *)readStoreData
{
    if (!_readStoreData) {
        _readStoreData = [[NSMutableArray alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            _readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
        }
    }

    return _readStoreData;
}

- (OpenUrlTableViewController *)openUrlTVC
{
    if (!_openUrlTVC) {
        _openUrlTVC = [[OpenUrlTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _openUrlTVC.delegate = self;
    }
    
    return _openUrlTVC;
}

@end
