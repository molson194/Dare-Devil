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
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:0.88 green:0.40 blue:0.40 alpha:1.0];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.allFacebook = [NSMutableArray array];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields": @"id, name"} HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        for (NSDictionary *friend in [result objectForKey:@"data"]){
            NSArray *friendInfo = [NSArray arrayWithObjects:[friend objectForKey:@"name"], [friend objectForKey:@"id"], nil];
            [self.allFacebook addObject:friendInfo];
        }
        self.searchResults = [self.allFacebook mutableCopy];
        [self.tableView reloadData];
    }];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search Facebook/Contacts";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width-80, 40);
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchController.searchBar];
    self.navigationItem.leftBarButtonItem = searchBarItem;
    
}

@synthesize delegate;

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.rightBarButtonItem = nil;
    searchBar.frame = CGRectMake(0, 0, 100, 40);
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width-100, 40);
}

-(void) dealloc {
    [self.searchController.view removeFromSuperview];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [delegate sendPerson:[NSArray arrayWithObjects:self.searchResults[indexPath.row][0], self.searchResults[indexPath.row][1], nil]];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%ld,%ld",(long)indexPath.section,(long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.searchResults[indexPath.row][0];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = self.searchController.searchBar.text;
    if ([searchString isEqualToString:@""]){
        self.searchResults = [self.allFacebook mutableCopy];
    } else {
        self.searchResults = [[NSMutableArray alloc] init];
        for (NSArray *contact in self.allFacebook) {
            if ([contact[0] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound){
                [self.searchResults addObject:contact];
            }
        }
    }
    [self.tableView reloadData];
}


@end