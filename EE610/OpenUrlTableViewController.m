//
//  OpenUrlTableViewController.m
//  EE610
//
//  Created by JzChang on 13/4/5.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "OpenUrlTableViewController.h"
#import "PlistHelper.h"
#import "SYSTEM_CONSTANT.h"

@interface OpenUrlTableViewController () {
    NSString *plistPath;
}

@property (strong, nonatomic) UITextField *urlTextField;
@property (strong, nonatomic) NSMutableArray *openedUrl;

@end

@implementation OpenUrlTableViewController

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
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                  target:self
                                                                                  action:@selector(clickCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                                target:self
                                                                                action:@selector(clickPlay:)];
    self.navigationItem.rightBarButtonItem = playButton;
    
    self.navigationItem.titleView = self.urlTextField;
    
    plistPath = [PlistHelper plistFilePathOfUrlData]; // plist 路徑
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 更新資料
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        // 讀取 plist
        self.openedUrl = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; 
        [self.tableView reloadData];
    }
    
    [self.urlTextField becomeFirstResponder];    
    
    // 設定 Navigation Bar 外型
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    // 設定 Navigation Bar 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect aFrame = self.urlTextField.frame;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = min - 100;
    }
    else {
        int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = max - 100;
    }
    
    self.urlTextField.frame = aFrame;
}

#pragma mark - selector

- (void)clickCancel:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickPlay:(UIBarButtonItem *)sender
{
    if (self.urlTextField.text.length > 0) {
        
        NSString *adjustInputUrlText = self.urlTextField.text;
        
        // 如果使用者尚未輸入以 http:// 或 https:// 系統預設則自動補上 http://
        if (!([self.urlTextField.text hasPrefix:@"http://"] || [self.urlTextField.text hasPrefix:@"https://"])) {
            adjustInputUrlText = [NSString stringWithFormat:@"%@%@", @"http://", adjustInputUrlText];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            NSMutableArray *readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
            
            // 沒有重複再新增資料
            if (![readStoreData containsObject:adjustInputUrlText]) {
                [readStoreData addObject:adjustInputUrlText];
                [readStoreData writeToFile:plistPath atomically:YES];
            }      
        }
        else {
            [@[self.urlTextField.text] writeToFile:plistPath atomically:YES];
        }
        
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     [self.delegate openUrl:[NSURL URLWithString:adjustInputUrlText]];                                   
                                 }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.openedUrl.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Open URL Cell";
    
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setSelectedBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_sel_bg2.png"]]];
    }
    
    cell.textLabel.text = [self.openedUrl objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"link.png"];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.openedUrl removeObjectAtIndex:indexPath.row];
        [self.openedUrl writeToFile:plistPath atomically:YES];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } 
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.urlTextField.text = [self.openedUrl objectAtIndex:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SETTINGS_CELL_HEIGHT;
}

#pragma mark - lazy instantiation

- (UITextField *)urlTextField
{
    int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
    int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
    
    if (!_urlTextField) {
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            // | 方向
            _urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, min - 100 , 30)];
        }
        else {
            // - 方向
            _urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, max - 100, 30)];
        }
        
        [_urlTextField setPlaceholder:@"http://"];
        [_urlTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [_urlTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_urlTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    }
    else {
        CGRect aFrame = _urlTextField.frame;
        
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            aFrame.size.width = min - 100;
        }
        else {
            aFrame.size.width = max - 100;
        }
        
        _urlTextField.frame = aFrame;
    }
    
    return _urlTextField;
}

- (NSMutableArray *)openedUrl
{
    if (!_openedUrl) {        
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            _openedUrl = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
        }
        else {
            _openedUrl = [[NSMutableArray alloc] init];
        }
    }
    
    return _openedUrl;
}

@end
