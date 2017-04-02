//
//  AddServerTableViewController.m
//  EE610
//
//  Created by JzChang on 13/3/18.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "AddServerTableViewController.h"
#import "PlistHelper.h"
#import "NSUserDefaults_KEY.h"
#import "SYSTEM_CONSTANT.h"

@interface AddServerTableViewController () <UITextFieldDelegate> {
    NSInteger currentSelectTextFieldTag;
}

@property (strong, nonatomic) UITextField *pcNameTextField, *ipTextField, *directoryTextField;
@property (strong, nonatomic) UIToolbar *keyboardToolbar;

@end

@implementation AddServerTableViewController

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
    
    // 設定 Navigation Bar 外型
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    // 設定 Navigation Bar 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];

    // 設定 rightBarButtonItem (儲存按鈕)
    UIBarButtonItem *saveBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(clickSave:)];
    self.navigationItem.rightBarButtonItem = saveBtnItem;
    
    self.pcNameTextField.text = @"";
    self.ipTextField.text = @"";
    self.directoryTextField.text = @"";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGRect aFrame = self.pcNameTextField.frame;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = min * 0.6;
    }
    else {
        int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = max * 0.7;
    }
    
    self.pcNameTextField.frame = aFrame;
    self.ipTextField.frame = aFrame;
    self.directoryTextField.frame = aFrame;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.pcNameTextField becomeFirstResponder];
    
    // 加入監測關閉 Search Bar 顯示鍵盤的 Notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeKeyboard:)
                                                 name:@"closeKeyboardNotification"
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.pcNameTextField.text = @"";
    self.ipTextField.text = @"";
    self.directoryTextField.text = @"";
    
    // 移除 Notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{    
    CGRect aFrame = self.pcNameTextField.frame;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = min * 0.6;
    }
    else {
        int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
        aFrame.size.width = max * 0.7;
    }
    
    self.pcNameTextField.frame = aFrame;
    self.ipTextField.frame = aFrame;
    self.directoryTextField.frame = aFrame;
}

#pragma mark - Function

- (BOOL)checkIntegrityConstraints
{
    BOOL valid = NO; // YES:驗證無誤
    NSString *warningMsg = @"";
    
    // 檢查 IP
    NSString *ipRegExp = @"\\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b";
//    NSString *ipRegExp = @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
//    NSString *ipRegExp = @"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    NSPredicate *ipTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipRegExp];
   
    // 檢查目錄
    NSString *dirRegExp = @"([^\\/:*?\"<>|]+/?)+"; //[^\\/:*?\"<>|]*";
    NSPredicate *dirTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", dirRegExp];
    
    if (self.pcNameTextField.text.length == 0) {
        warningMsg = NSLocalizedString(@"尚未輸入電腦名稱", @"Not yet entered into the computer name");
    }    
    else if (self.ipTextField.text.length == 0) {
        warningMsg = NSLocalizedString(@"尚未輸入網路位址", @"Not yet entered into the network address");
    }
    else if (self.ipTextField.text.length > 0 && ![ipTest evaluateWithObject:self.ipTextField.text]) {
        warningMsg = NSLocalizedString(@"網路位址格式有誤", @"Network address format is incorrect");
    }
    else if (self.directoryTextField.text.length > 0 && ![dirTest evaluateWithObject:self.directoryTextField.text]) {
        warningMsg = NSLocalizedString(@"目錄路徑格式有誤", @"Directory format is incorrect");
    }
    else {
        valid = YES;
        
        NSRange aRange = [self.directoryTextField.text rangeOfString:@"\\"];

        if (aRange.location == NSNotFound) {
        }
        else {
            warningMsg = NSLocalizedString(@"目錄路徑格式有誤", @"Directory format is incorrect");
            valid = NO;
        }
    }
       
    if (!valid) {
        UIAlertView *warningAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"警告", @"Warning")
                                                                   message:warningMsg
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"好", @"OK")
                                                         otherButtonTitles:nil];
        [warningAlertView show];
    }    
    
    return valid; // YES:驗證無誤
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{        
    if (textField.tag + 1 <= 3) {
        // 透過 tag 取的 TextField
        UITextField *nextTextField = (UITextField*)[self.view viewWithTag:textField.tag + 1];
        [nextTextField becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    else {
        // 最後一個 textField 就關閉鍵盤
        [textField resignFirstResponder];
        // 儲存資料
        [self clickSave:nil];
    }

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // 取得目前哪個 textField 被選取
    currentSelectTextFieldTag = textField.tag;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(textField.tag - 1) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark - selector

- (void)clickSave:(UIBarButtonItem *)sender
{    
    // 檢查輸入資料完整性
    if (![self checkIntegrityConstraints]) {
        return;
    }
    
    NSString *plistPath = [PlistHelper plistFilePathOfIpData]; // plist 路徑

    if (self.editPcName == nil && self.editIp == nil && self.editDirectory == nil) {
        // "新增資料"
        NSDictionary *inputData = @{@"PC_NAME": self.pcNameTextField.text, @"IP": self.ipTextField.text, @"Directory": self.directoryTextField.text};
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            // 修改 plist 資料
            NSMutableArray *readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
            [readStoreData addObject:inputData];
            [readStoreData writeToFile:plistPath atomically:YES];
        }
        else {
            // 新增 plist 資料
            [@[inputData] writeToFile:plistPath atomically:YES];
        }
    }
    else {
        // "修改資料"
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            // 修改 plist 資料
            NSMutableArray *readStoreData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath]; // 讀取 plist
            
            NSDictionary *editData = @{@"PC_NAME": self.pcNameTextField.text, @"IP": self.ipTextField.text, @"Directory": self.directoryTextField.text};
            NSDictionary *oriData = [readStoreData objectAtIndex:self.selectIndex];

            
            // 有修改資料才更新
            if (![editData isEqualToDictionary:oriData]) {
                // 修改後覆蓋原有資料 index
                [readStoreData replaceObjectAtIndex:self.selectIndex withObject:editData];
                [readStoreData writeToFile:plistPath atomically:YES];
                
                [self.delegate editOriData:oriData andUpdateData:editData];
            }
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

// 關閉 Search Bar 的鍵盤 - Notification
- (void)closeKeyboard:(NSNotification *)notification
{
    [self.view endEditing:YES];
}

- (void)prevAndNextSegmtAction:(UISegmentedControl *)sender
{    
    NSInteger gotoTag = currentSelectTextFieldTag;
    
    
    switch (sender.selectedSegmentIndex)
    {
        case 0: // 上一個
            gotoTag--;
            break;
        case 1: // 下一個
            gotoTag++;
            break;
    }
        
    UITextField *gotoTextField = (UITextField*)[self.view viewWithTag:gotoTag];
    
    if ([gotoTextField isKindOfClass:[UITextField class]]) {
        [gotoTextField becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(gotoTag - 1) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Add Server Cell";
   
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"電腦名稱", @"PC Name");
        [cell setAccessoryView:self.pcNameTextField];
    }
    else if (indexPath.section == 0 && indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"網路位址", @"IP Address");
        [cell setAccessoryView:self.ipTextField];
    }
    else if (indexPath.section == 0 && indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"目錄路徑", @"Directory");
        [cell setAccessoryView:self.directoryTextField];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SETTINGS_CELL_HEIGHT;
}

#pragma mark - Setter

- (void)setEditPcName:(NSString *)editPcName
{
    _editPcName = editPcName;
    self.pcNameTextField.text = editPcName;
}

- (void)setEditIp:(NSString *)editIp
{
    _editIp = editIp;
    self.ipTextField.text = editIp;
}

- (void)setEditDirectory:(NSString *)editDirectory
{
    _editDirectory = editDirectory;
    self.directoryTextField.text = editDirectory;
}

#pragma mark - lazy instantiation

- (UITextField *)pcNameTextField
{
    if (!_pcNameTextField) {
        
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            // | 方向
            int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
            _pcNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, min * 0.6, SETTINGS_CELL_HEIGHT - 15)];
        }
        else {
            // - 方向
            int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
            _pcNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, max * 0.7, SETTINGS_CELL_HEIGHT - 15)];
        }
        
        _pcNameTextField.delegate = self;
        [_pcNameTextField setTag:1];
        [_pcNameTextField setReturnKeyType:UIReturnKeyNext];            // 設定鍵盤的 Return 鍵為 Next
        [_pcNameTextField setPlaceholder:NSLocalizedString(@"例: 我的電腦", @"EX: My Computer")];
        [_pcNameTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [_pcNameTextField setFont:[UIFont systemFontOfSize:18]];
        [_pcNameTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_pcNameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [_pcNameTextField setKeyboardType:UIKeyboardTypeDefault];
        
        [_pcNameTextField setInputAccessoryView:self.keyboardToolbar];  // 在鍵盤上面加上 toolbar
    }
    
    return _pcNameTextField;
}

- (UITextField *)ipTextField
{
    if (!_ipTextField) {
        
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            // | 方向
            int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
            _ipTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, min * 0.6, SETTINGS_CELL_HEIGHT - 15)];

        }
        else {
            // - 方向
            int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
            _ipTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, max * 0.7, SETTINGS_CELL_HEIGHT - 15)];
        }
        
        _ipTextField.delegate = self;
        [_ipTextField setTag:2];
        [_ipTextField setReturnKeyType:UIReturnKeyNext];            // 設定鍵盤的 Return 鍵為 Next
        [_ipTextField setPlaceholder:NSLocalizedString(@"例: 192.168.0.1", @"EX: 192.168.0.1")];
        [_ipTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [_ipTextField setFont:[UIFont systemFontOfSize:18]];
        [_ipTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_ipTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        
        if (IS_IPAD) {
            [_ipTextField setKeyboardType:UIKeyboardTypeNumberPad];
        }
        else {
            [_ipTextField setKeyboardType:UIKeyboardTypeDecimalPad];
        }
        
        [_ipTextField setInputAccessoryView:self.keyboardToolbar];  // 在鍵盤上面加上 toolbar
    }
    
    return _ipTextField;
}

- (UITextField *)directoryTextField
{
    if (!_directoryTextField) {
        
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            // | 方向
            int min = MIN(self.view.frame.size.width, self.view.frame.size.height);
            _directoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, min * 0.6, SETTINGS_CELL_HEIGHT - 15)];
            
        }
        else {
            // - 方向
            int max = MAX(self.view.frame.size.width, self.view.frame.size.height);
            _directoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, max * 0.7, SETTINGS_CELL_HEIGHT - 15)];
        }
        
        _directoryTextField.delegate = self;
        [_directoryTextField setTag:3];
        [_directoryTextField setReturnKeyType:UIReturnKeyDone];             // 設定鍵盤的 Return 鍵為 Done
        [_directoryTextField setPlaceholder:NSLocalizedString(@"例: HLS/Path", @"EX: HLS/Path")];
        [_directoryTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [_directoryTextField setFont:[UIFont systemFontOfSize:18]];
        [_directoryTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_directoryTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [_directoryTextField setKeyboardType:UIKeyboardTypeURL];
        
        [_directoryTextField setInputAccessoryView:self.keyboardToolbar];   // 在鍵盤上面加上 toolbar
    }
    
    return _directoryTextField;
}

- (UIToolbar *)keyboardToolbar
{
    if (!_keyboardToolbar) {
        _keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 35)];
        _keyboardToolbar.tintColor = [UIColor darkGrayColor];
        
        UISegmentedControl *prevAndNextSegmt = [[UISegmentedControl alloc] initWithItems:@[[UIImage imageNamed:@"prev.png"], [UIImage imageNamed:@"next.png"]]];
        [prevAndNextSegmt addTarget:self action:@selector(prevAndNextSegmtAction:) forControlEvents:UIControlEventValueChanged];
        prevAndNextSegmt.frame = CGRectMake(0, 0, 200, 25);
        prevAndNextSegmt.segmentedControlStyle = UISegmentedControlStyleBar;
        prevAndNextSegmt.momentary = YES;
        
        UIBarButtonItem *prevAndNextBarItem = [[UIBarButtonItem alloc] initWithCustomView:prevAndNextSegmt];
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                       target:nil
                                                                                       action:nil];
       
        _keyboardToolbar.items = @[flexibleSpace, prevAndNextBarItem, flexibleSpace];
    }
    
    return _keyboardToolbar;
}

@end
