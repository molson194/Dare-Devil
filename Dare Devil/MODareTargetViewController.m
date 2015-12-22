//
//  MODareTargetViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/21/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MODareTargetViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Contacts;

@implementation MODareTargetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-30) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    self.someoneButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.someoneButton.frame=CGRectMake(0,0,self.view.bounds.size.width,50);
    [self.someoneButton setTitle: @"Someone" forState: UIControlStateNormal];
    [self.someoneButton addTarget:self action:@selector(someoneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.someoneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.someoneButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    self.someoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    UILabel *someoneSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 35, 250, 15)];
    [someoneSubtitle setBackgroundColor:[UIColor clearColor]];
    [someoneSubtitle setFont:[UIFont fontWithName:@"Helvetica" size:13]];
    someoneSubtitle.text=@"Anyone tagged in the dare can submit";
    [someoneSubtitle setTextColor:[UIColor blackColor]];
    [self.someoneButton addSubview:someoneSubtitle];
    [headerView addSubview:self.someoneButton];
    self.tableView.tableHeaderView = headerView;
    [self.view addSubview:self.tableView];
    
    
    
    self.allContacts = [NSMutableArray array];
    CNContactStore *store = [[CNContactStore alloc] init];
    NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey];
    NSString *containerId = store.defaultContainerIdentifier;
    NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:containerId];
    NSError *error;
    NSArray *cnContacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
    if (error) {
        NSLog(@"error fetching contacts %@", error);
    } else {
        for (CNContact *contact in cnContacts) {
            for (CNLabeledValue<CNPhoneNumber*>* labeledValue in contact.phoneNumbers)
            {
                if ([labeledValue.label isEqualToString:CNLabelPhoneNumberMobile] || [labeledValue.label isEqualToString:CNLabelPhoneNumberiPhone])
                {
                    NSString *contactName = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
                    NSString *phoneNumber = labeledValue.value.stringValue;
                    [self.allContacts addObject:[NSArray arrayWithObjects:contactName, phoneNumber, nil]];
                    break;
                }
            }
        }
    }
    self.allPeople = [NSMutableArray arrayWithArray:self.allContacts];
    self.searchResults = [self.allPeople mutableCopy];
    
    self.allFacebook = [NSMutableArray array];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields": @"id, name"} HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        for (NSDictionary *friend in [result objectForKey:@"data"]){
            NSArray *friendInfo = [NSArray arrayWithObjects:[friend objectForKey:@"name"], [friend objectForKey:@"id"], nil];
            [self.allFacebook addObject:friendInfo];
        }
        self.allPeople = [NSMutableArray arrayWithArray:self.allFacebook];
        [self.allPeople addObjectsFromArray:self.allContacts];
        self.searchResults = [self.allPeople mutableCopy];
        [self.tableView reloadData];
    }];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search Facebook/Contacts";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 40);
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchController.searchBar];
    self.navigationItem.leftBarButtonItem = searchBarItem;
}

@synthesize delegate;
-(void)viewWillDisappear:(BOOL)animated
{
    [delegate sendDataToPostView:self.finalTarget];
    
}

- (void)someoneButtonPressed{
    self.finalTarget = [NSArray array];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.rightBarButtonItem = nil;
    searchBar.frame = CGRectMake(0, 0, 100, 40);
}

-(void) dealloc {
    [self.searchController.view removeFromSuperview];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.finalTarget = [NSArray arrayWithObjects:cell.textLabel.text, cell.detailTextLabel.text, nil];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%ld,%ld",(long)indexPath.section,(long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.searchResults[indexPath.row][0];
    cell.detailTextLabel.text = self.searchResults[indexPath.row][1];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = self.searchController.searchBar.text;
    if ([searchString isEqualToString:@""]){
        self.searchResults = [self.allPeople mutableCopy];
    } else {
        self.searchResults = [[NSMutableArray alloc] init];
        for (NSArray *contact in self.allPeople) {
            if ([contact[0] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound){
                [self.searchResults addObject:contact];
            }
        }
    }
    [self.tableView reloadData];
}


@end
