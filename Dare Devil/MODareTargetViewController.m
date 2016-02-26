//
//  MODareRecipientViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/18/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MODareTargetViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Contacts;

@implementation MODareTargetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Target a Friend";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost)];
    [cancelButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.allFacebook = [NSMutableArray array];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields": @"id, name"} HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        for (NSDictionary *friend in [result objectForKey:@"data"]){
            NSArray *friendInfo = [NSArray arrayWithObjects:[friend objectForKey:@"name"], [friend objectForKey:@"id"], nil];
            [self.allFacebook addObject:friendInfo];
        }
        [self.tableView reloadData];
    }];
}

@synthesize delegate;

- (void)cancelPost {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.rightBarButtonItem = nil;
    searchBar.frame = CGRectMake(0, 0, 100, 40);
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width-100, 40);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [delegate sendPerson:[NSArray arrayWithObjects:self.allFacebook[indexPath.row][0], self.allFacebook[indexPath.row][1], nil]];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%ld,%ld",(long)indexPath.section,(long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.allFacebook[indexPath.row][0];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allFacebook count];
}


@end