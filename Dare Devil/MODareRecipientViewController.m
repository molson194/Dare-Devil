//
//  MODareRecipientViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/18/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MODareRecipientViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Contacts;

@implementation MODareRecipientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-30) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Tag Friends";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost)];
    [cancelButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    self.worldButton=[UIButton buttonWithType:UIButtonTypeCustom];
    if (self.toWorld) {
        [self.worldButton setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.worldButton setBackgroundColor:[UIColor whiteColor]];
    }
    self.worldButton.frame=CGRectMake(0,0,self.view.bounds.size.width,50);
    [self.worldButton setTitle: @"World" forState: UIControlStateNormal];
    [self.worldButton addTarget:self action:@selector(worldButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.worldButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.worldButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    self.worldButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    UILabel *worldSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 35, 250, 15)];
    [worldSubtitle setBackgroundColor:[UIColor clearColor]];
    [worldSubtitle setFont:[UIFont fontWithName:@"Helvetica" size:13]];
    worldSubtitle.text=@"Visible to everyone in the world";
    [worldSubtitle setTextColor:[UIColor blackColor]];
    [self.worldButton addSubview:worldSubtitle];
    [headerView addSubview:self.worldButton];
    
    self.friendsButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [self.friendsButton setBackgroundColor:[UIColor whiteColor]];
    self.friendsButton.frame=CGRectMake(0,50,self.view.bounds.size.width,50);
    [self.friendsButton setTitle: @"Facebook Friends" forState: UIControlStateNormal];
    [self.friendsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.friendsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.friendsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    [self.friendsButton addTarget:self action:@selector(friendsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *friendsSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 35, 250, 15)];
    [friendsSubtitle setBackgroundColor:[UIColor clearColor]];
    [friendsSubtitle setFont:[UIFont fontWithName:@"Helvetica" size:13]];
    friendsSubtitle.text=@"Tag all friends currently using the app";
    [friendsSubtitle setTextColor:[UIColor blackColor]];
    [self.friendsButton addSubview:friendsSubtitle];
    [headerView addSubview:self.friendsButton];
    self.tableView.tableHeaderView = headerView;
    [self.view addSubview:self.tableView];
    
    self.allFacebook = [NSMutableArray array];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields": @"id, name"} HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        for (NSDictionary *friend in [result objectForKey:@"data"]){
            NSArray *friendInfo = [NSArray arrayWithObjects:[friend objectForKey:@"name"], [friend objectForKey:@"id"], nil];
            [self.allFacebook addObject:friendInfo];
        }
        [self.tableView reloadData];
    }];
    
    UIBarButtonItem *tagButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(tagPeople)];
    [tagButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.rightBarButtonItem = tagButton;
    
    if (self.taggedFacebook == nil) {
        self.taggedFacebook = [NSMutableArray array];
    }

}

@synthesize delegate;

- (void)cancelPost {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) reopenWithFacebook:(NSMutableArray*)facebookTags {
    self.taggedFacebook = facebookTags;
    [self.tableView reloadData];
    
}

- (void)worldButtonPressed{
    [delegate sendWorld:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)friendsButtonPressed{
    [delegate sendFacebook:self.allFacebook];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.rightBarButtonItem = nil;
    searchBar.frame = CGRectMake(0, 0, 100, 40);
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    UIBarButtonItem *tagButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(tagPeople)];
    self.navigationItem.rightBarButtonItem = tagButton;
    searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width-100, 40);
}

-(void) tagPeople {
    [delegate sendIndividuals:self.taggedFacebook];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.contentView.backgroundColor != [UIColor lightGrayColor]){
        [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
        [self.taggedFacebook addObject:[NSArray arrayWithObjects:self.allFacebook[indexPath.row][0], self.allFacebook[indexPath.row][1], nil]];
    } else {
        [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        [self.taggedFacebook removeObject:[NSArray arrayWithObjects:self.allFacebook[indexPath.row][0], self.allFacebook[indexPath.row][1], nil]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%ld,%ld",(long)indexPath.section,(long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.allFacebook[indexPath.row][0];
    
    if ([self.taggedFacebook containsObject:self.allFacebook[indexPath.row]]) {
        [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allFacebook count];
}


@end