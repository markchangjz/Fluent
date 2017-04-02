//
//  SettingTableViewController.m
//  EE610
//
//  Created by JzChang on 13/3/13.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "SettingTableViewController.h"
#import "AddServerTableViewController.h"
#import "PlistHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "NSUserDefaults_KEY.h"
#import "SYSTEM_CONSTANT.h"

@interface SettingTableViewController () <AddServerTableViewControllerDelegate> {
    NSMutableArray *settingSection;     // TableView 的 Section
    NSMutableArray *settingItem;        // TableView 的 Section 裡的 Cell 資料
    NSMutableArray *readStoreData;      // 儲存的 IP 清單
    NSString *ipDataPlistPath;          // plist 路徑
    NSUserDefaults *userDefaults;
}

@property (strong, nonatomic) AddServerTableViewController *addServerTVC;   // 新增
@property (strong, nonatomic) AddServerTableViewController *editServerTVC;  // 編輯
@property (strong, nonatomic) NSIndexPath *checkedCell;                     // 設定 Checkmark
@property (strong, nonatomic) NSArray *realTimeBitrate;                     // 系統使用者選擇 Bitrate
@property (strong, nonatomic) NSDictionary *userSelectQuality, *defaultQuality, *highQuality, *medQuality, *lowQuality;

@end

@implementation SettingTableViewController

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

    // 設定 leftBarButtonItem (選單按鈕)
    UIImage *menuImg = [UIImage imageNamed:@"menu.png"];
    UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuBtn addTarget:self action:@selector(clickMenu:) forControlEvents:UIControlEventTouchUpInside];
    [menuBtn setShowsTouchWhenHighlighted:YES];
    [menuBtn setImage:menuImg forState:UIControlStateNormal];
    [menuBtn setBounds:CGRectMake(0, 0, menuImg.size.width + 10, menuImg.size.height)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
    
    // 設定 plist 路徑
    ipDataPlistPath = [PlistHelper plistFilePathOfIpData];
    
    // 初始化 UserDefaults
    userDefaults = [NSUserDefaults standardUserDefaults];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 設定 Navigation 標題(Title)
    self.navigationItem.title = NSLocalizedString(@"設定", @"Settings");
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    // 設定 Navigation Bar 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    // 設定 rightBarButtonItem (編輯按鈕)
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // 設定 tableView section 資料
    settingSection = [[NSMutableArray alloc] init];
    [settingSection insertObject:@"" atIndex:0];
    
    // 設定 tableView row 資料
    readStoreData = [[NSMutableArray alloc] init];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipDataPlistPath]) {
        // 讀取 plist
        readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:ipDataPlistPath]; 
    }
        
    if (readStoreData.count > 0) {
        [settingSection insertObject:NSLocalizedString(@"串流伺服器列表", @"Streaming Server List") atIndex:1];
        [settingSection insertObject:NSLocalizedString(@"即時處理播放位元率", @"Live Convert Bitrate") atIndex:2];
        
        settingItem = [[NSMutableArray alloc] initWithArray:@[@[NSLocalizedString(@"新增串流伺服器", @"Add Streaming Server")], readStoreData, self.realTimeBitrate]];
    }
    else {
        [settingSection insertObject:NSLocalizedString(@"即時處理播放位元率", @"Live Convert Bitrate") atIndex:1];

        settingItem = [[NSMutableArray alloc] initWithArray:@[@[NSLocalizedString(@"新增串流伺服器", @"Add Streaming Server")], self.realTimeBitrate]];
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];    
    // Dispose of any resources that can be recreated.
}

#pragma mark - AddServerTableViewControllerDelegate

- (void)editOriData:(NSDictionary *)oriData andUpdateData:(NSDictionary *)updataData
{
    [self.delegate updatePlayListOriData:oriData andUpdateData:updataData];
}

#pragma mark - selector

- (void)clickMenu:(UIButton *)sender
{
    [self.delegate hideAndShowPlaylistTVC];
}

- (void)updateTableView:(NSNotification *)notification
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipDataPlistPath]) {
        // 讀取 plist
        readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:ipDataPlistPath]; 
    }
        
    NSMutableArray *mSettingItem = [settingItem mutableCopy];
    [mSettingItem replaceObjectAtIndex:1 withObject:readStoreData];
    settingItem = [mSettingItem copy];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return settingSection.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[settingItem objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [settingSection objectAtIndex:section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 開啟表格項目的移動功能
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // 移動後的 Cell 要與原本同 section
    if (sourceIndexPath.section == destinationIndexPath.section) {
        
        // 調整移動後的資料
        NSDictionary *selectMoveitem = [readStoreData objectAtIndex:sourceIndexPath.row];
        [readStoreData removeObjectAtIndex:sourceIndexPath.row];
        [readStoreData insertObject:selectMoveitem atIndex:destinationIndexPath.row];
        
        // 調整順序後儲存資料
        if ([[NSFileManager defaultManager] fileExistsAtPath:ipDataPlistPath]) {
            // 修改 plist 資料
            [readStoreData writeToFile:ipDataPlistPath atomically:YES];
        }
    }
    else {
        [self.tableView reloadData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Settings Cell";
    
    UITableViewCell *cell;
    
    if (IS_IPAD) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
 
    if (indexPath.section == 0) {
        cell.textLabel.text = [[settingItem objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([settingItem objectAtIndex:indexPath.section] == readStoreData /*indexPath.section == 1*/) {
        
        NSString *pcNameStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"PC_NAME"];        // 電腦名稱
        NSString *ipStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"IP"];                 // 網路位址
        NSString *directoryStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"Directory"];   // 目錄路徑
        
        if (IS_IPHONE) {
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15]];
        }
        
        cell.textLabel.text = [@"http://" stringByAppendingString:[ipStr stringByAppendingPathComponent:directoryStr]];
        cell.detailTextLabel.text = pcNameStr;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([settingItem objectAtIndex:indexPath.section] == self.realTimeBitrate) {
        NSString *key = [[[self.realTimeBitrate objectAtIndex:indexPath.row] allKeys] objectAtIndex:0];
        NSString *value = [[self.realTimeBitrate objectAtIndex:indexPath.row] objectForKey:key];
        NSString *displayText = key;
        
        if (![value isEqualToString:@""]) {
            displayText = [displayText stringByAppendingFormat:@" %@bps", value];
        }
        
        cell.textLabel.text = displayText;
    
        // 設定 Checkmark
        if ((self.checkedCell != nil) && (self.checkedCell.row == indexPath.row) && (self.checkedCell.section == indexPath.section)) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        // 設定使用者選擇 bitrate 品質
        if ([[self.realTimeBitrate objectAtIndex:indexPath.row] isEqualToDictionary:self.userSelectQuality]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.checkedCell = indexPath;
        }    
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < settingItem.count) {
        return ([settingItem objectAtIndex:indexPath.section] == readStoreData /*indexPath.section == 1*/) ? YES : NO;
    }
    else {
        return NO;
    }    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {      
        if ([settingItem objectAtIndex:indexPath.section] == readStoreData/*indexPath.section == 1*/) {
            
            // 如果刪除的資料根儲存上次連線一樣, 就將連線記錄刪除
            NSDictionary *deleteData = [readStoreData objectAtIndex:indexPath.row];
            
            if ([userDefaults objectForKey:STORE_IP_KEY] != nil) {                
                NSDictionary *lastData = [userDefaults objectForKey:STORE_IP_KEY];
                
                if ([deleteData isEqualToDictionary:lastData]) {
                    // 請空上次連線 IP 紀錄
                    [userDefaults removeObjectForKey:STORE_IP_KEY];
                    // 清空 Table View 資料
                    [self.delegate updatePlayListOriData:nil andUpdateData:nil];
                }
            }            
            
            [readStoreData removeObjectAtIndex:indexPath.row];
            
            // 刪除後結果寫回 plist
            [readStoreData writeToFile:ipDataPlistPath atomically:YES];

            // 刪除對應的表格項目
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            if (readStoreData.count == 0) {
                [settingSection removeObjectAtIndex:1];
                [settingItem removeObjectAtIndex:1];
                [self.tableView reloadData];
            }
        }
    }  
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([settingItem objectAtIndex:indexPath.section] == self.realTimeBitrate) {
        // 設定 Checkmark
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        
        if (self.checkedCell != nil) { // Uncheck previously selected cell
            UITableViewCell *prevSelectedCell = [tableView cellForRowAtIndexPath:self.checkedCell];
            prevSelectedCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.checkedCell = indexPath;
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    // 使用者點選 Cell    
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.navigationController pushViewController:self.addServerTVC animated:YES];    
    }
    else if ([settingItem objectAtIndex:indexPath.section] == readStoreData/*indexPath.section == 1*/) {
        NSString *pcNameStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"PC_NAME"];        // 電腦名稱
        NSString *ipStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"IP"];                 // 網路位址
        NSString *directoryStr = [[[settingItem objectAtIndex:1] objectAtIndex:indexPath.row] objectForKey:@"Directory"];
                
        self.editServerTVC.selectIndex = indexPath.row;
        self.editServerTVC.editPcName = pcNameStr;
        self.editServerTVC.editIp = ipStr;
        self.editServerTVC.editDirectory = directoryStr;
        
        [self.navigationController pushViewController:self.editServerTVC animated:YES];
    }
    else if ([settingItem objectAtIndex:indexPath.section] == self.realTimeBitrate) {
        self.userSelectQuality = [self.realTimeBitrate objectAtIndex:indexPath.row];
        
        // 儲存使用者選擇的影片品質
        [userDefaults setObject:[self.realTimeBitrate objectAtIndex:indexPath.row] forKey:STORE_QUALITY_KEY];
        [userDefaults synchronize];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SETTINGS_CELL_HEIGHT;
}

#pragma mark - lazy instantiation

- (AddServerTableViewController *)addServerTVC
{
    if (!_addServerTVC) {
        _addServerTVC = [[AddServerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _addServerTVC.navigationItem.title = NSLocalizedString(@"新增串流伺服器", @"Add Streaming Server");
    }
    
    return _addServerTVC;
}

- (AddServerTableViewController *)editServerTVC
{
    if (!_editServerTVC) {
        _editServerTVC = [[AddServerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _editServerTVC.delegate = self; // 設定 delegate
        _editServerTVC.navigationItem.title = NSLocalizedString(@"編輯串流伺服器", @"Edit Streaming Server");
    }
    
    return _editServerTVC;
}

- (NSArray *)realTimeBitrate
{
    if (!_realTimeBitrate) {
        _realTimeBitrate = @[self.defaultQuality, self.highQuality, self.medQuality, self.lowQuality];
    }
    
    return _realTimeBitrate;
}

- (NSDictionary *)userSelectQuality
{
    if (!_userSelectQuality) {        
        if ([userDefaults objectForKey:STORE_QUALITY_KEY] != nil) {
            _userSelectQuality = [userDefaults objectForKey:STORE_QUALITY_KEY];
        }
        else {
            // 初始值為預設
            _userSelectQuality = self.defaultQuality;
            [userDefaults setObject:_userSelectQuality forKey:STORE_QUALITY_KEY];
            [userDefaults synchronize];
        }    
    }
    
    return _userSelectQuality;
}

- (NSDictionary *)defaultQuality
{
    if (!_defaultQuality) {
        _defaultQuality = @{NSLocalizedString(@"預設", @"Default"): @""};
    }
    
    return _defaultQuality;
}

- (NSDictionary *)highQuality
{
    if (!_highQuality) {
        _highQuality = @{NSLocalizedString(@"高品質", @"High Quality"): @"2.0M"};
    }
    
    return _highQuality;
}

- (NSDictionary *)medQuality
{
    if (!_medQuality) {
        _medQuality = @{NSLocalizedString(@"中品質", @"Medium Quality"): @"1.0M"};
    }
    
    return _medQuality;
}

- (NSDictionary *)lowQuality
{
    if (!_lowQuality) {
        _lowQuality = @{NSLocalizedString(@"低品質", @"Low Quality"): @"300k"};
    }
    
    return _lowQuality;
}

@end
