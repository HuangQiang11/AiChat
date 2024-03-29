//
//  ZHBContactsTVC.m
//  AiChat
//
//  Created by 庄彪 on 15/7/3.
//  Copyright (c) 2015年 XMPP. All rights reserved.
//

#import "TXLContactsTVC.h"
#import "TXLContactsTool.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "TXLContactDetailVC.h"
#import "TXLAddFriendVC.h"
#import "UIView+Frame.h"
#import "ZHBCommonSearchBar.h"
#import "ZHBCommonPopView.h"
#import <MJRefresh.h>
#import <ReactiveCocoa.h>
#import "ZHBXMPPTool.h"

@interface TXLContactsTVC ()<UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarBtnItem;

@property (nonatomic, weak) ZHBCommonSearchBar *searchBar;

@property (nonatomic, strong) TXLContactsTool *contactsTool;

@end

@implementation TXLContactsTVC

#pragma mark -
#pragma mark Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    [self setupSignal];
    [self setupSearchBar];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[TXLContactDetailVC class]]) {
        TXLContactDetailVC *contactDetailVc = segue.destinationViewController;
        contactDetailVc.user = (XMPPUserCoreDataStorageObject *)sender;
    }
}

#pragma mark -

#pragma mark SearchBar Delegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.view endEditing:YES];
}

#pragma mark UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contactsTool.friends.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"contactstvc2detail" sender:self.contactsTool.friends[indexPath.row]];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark -
#pragma mark UITableView Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.imageView.bounds = CGRectMake(0, 0, 40, 40);
     }
    XMPPUserCoreDataStorageObject *user = self.contactsTool.friends[indexPath.row];
    UIImage *photo = user.photo;
    if (!photo) {
        photo = [UIImage imageWithData:[[ZHBXMPPTool sharedXMPPTool].xmppAvatarModule photoDataForJID:user.jid]];
        if (!photo) {
            photo = [UIImage imageNamed:@"DefaultHead"];
        }
     }
    cell.imageView.image = photo;
    cell.textLabel.text = user.jidStr;
    return cell;
}

#pragma mark -
#pragma mark Private Methods
- (void)setupTableView {
    self.tableView.rowHeight = 60;
    
    @weakify(self);
    MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self);
        [self.contactsTool loadContactsList];
    }];    
    self.tableView.header = refreshHeader;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)setupSearchBar {
    ZHBCommonSearchBar *searchBar = [[ZHBCommonSearchBar alloc] init];
    searchBar.frame = CGRectMake(0, 0, self.view.width, 40);
    self.tableView.tableHeaderView = searchBar;
    self.searchBar = searchBar;
}

- (void)setupSignal {
    @weakify(self);
    [self.contactsTool.rac_updateSignal subscribeNext:^(id x) {
        @strongify(self);
        [self.tableView reloadData];
        [self.tableView.header endRefreshing];
    }];
    
    self.rightBarBtnItem.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        [ZHBCommonPopView showPopViewInVC:self];
        return [RACSignal empty];
    }];
}

#pragma mark -
#pragma mark Getters

- (TXLContactsTool *)contactsTool {
    if (nil == _contactsTool) {
        _contactsTool = [[TXLContactsTool alloc] init];
    }
    return _contactsTool;
}

@end
