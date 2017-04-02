//
//  VideoInfoTableViewController.m
//  EE610
//
//  Created by JzChang on 13/3/7.
//  Copyright (c) 2013年 JzChang. All rights reserved.
//

#import "VideoInfoTableViewController.h"
#import "SYSTEM_CONSTANT.h"

@interface VideoInfoTableViewController () {
    NSArray *keyArray, *valueArray;
}

@end

@implementation VideoInfoTableViewController

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
    
    self.navigationItem.title = [self.videoInfo objectForKey:@"name"];
    
    // 設定 Navigation Bar 外型
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    // 設定 Navigation Bar 背景
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    if (IS_IPHONE) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                      target:self
                                                                                      action:@selector(clickCancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                                target:self
                                                                                action:@selector(clickPlay:)];
    self.navigationItem.rightBarButtonItem = playButton;
        
    keyArray = @[NSLocalizedString(@"片長", @"Duration"), NSLocalizedString(@"解析度", @"Resolution"), NSLocalizedString(@"品質", @"Quality"), NSLocalizedString(@"發佈日期", @"Publish Date")];
    valueArray = @[[self.videoInfo objectForKey:@"duration"], [self.videoInfo objectForKey:@"resolution"], [self.videoInfo objectForKey:@"quality"], [self.videoInfo objectForKey:@"pubDate"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (IS_IPAD) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 340)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 480, 320)];
        imageView.image = [self.videoInfo objectForKey:@"image"];
        imageView.center = CGPointMake(self.view.center.x, 170 + 5);
        [headerView addSubview:imageView];
        
        self.tableView.tableHeaderView = headerView;
    }
    else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 220)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        imageView.image = [self.videoInfo objectForKey:@"image"];
        imageView.center = CGPointMake(self.view.center.x, 110);
        [headerView addSubview:imageView];
        
        self.tableView.tableHeaderView = headerView;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (IS_IPHONE) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 220)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        imageView.image = [self.videoInfo objectForKey:@"image"];
        imageView.center = CGPointMake(self.view.center.x, 110);
        [headerView addSubview:imageView];
        
        self.tableView.tableHeaderView = headerView;
    }
}

#pragma mark - selector

- (void)clickPlay:(UIBarButtonItem *)sender
{
    NSString *urlPath = [NSString stringWithFormat:@"%@/%@/variant.m3u8", self.parserString, [self.videoInfo objectForKey:@"id"]];
    NSString *escapedUrlString = [urlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [self.delegate playSelectURL:[NSURL URLWithString:escapedUrlString] andViedoName:[self.videoInfo objectForKey:@"name"]];
                             }];
}

- (void)clickCancel:(UIBarButtonItem *)sender
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
    return keyArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Video Cell";
    
    UITableViewCell *cell;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone]; // 設定不能選擇 Cell
    }
    
    // 設定 Cell Style
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    // 設定 Cell 資料顯示
    cell.textLabel.text = [keyArray objectAtIndex:indexPath.row];
    
    if (indexPath.row != 2) {
        cell.detailTextLabel.text = [valueArray objectAtIndex:indexPath.row];
    }
    else {
        NSString *qualityStr = @"";
        
        if ([[valueArray objectAtIndex:indexPath.row] characterAtIndex:0] == '1') {
            qualityStr = [qualityStr stringByAppendingFormat:@" %@", NSLocalizedString(@"高品質", @"High Quality")];
        }
        if ([[valueArray objectAtIndex:indexPath.row] characterAtIndex:1] == '1') {
            qualityStr = [qualityStr stringByAppendingFormat:@" %@", NSLocalizedString(@"中品質", @"Medium Quality")];
        }
        if ([[valueArray objectAtIndex:indexPath.row] characterAtIndex:2] == '1') {
            qualityStr = [qualityStr stringByAppendingFormat:@" %@", NSLocalizedString(@"低品質", @"Low Quality")];
        }
        
        cell.detailTextLabel.text = qualityStr;
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
