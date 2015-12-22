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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-30) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
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
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width-80, 40);
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchController.searchBar];
    self.navigationItem.leftBarButtonItem = searchBarItem;
    
    UIBarButtonItem *tagButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(tagPeople)];
    self.navigationItem.rightBarButtonItem = tagButton;
    
    if (self.taggedContacts == nil) {
        self.taggedContacts = [NSMutableArray array];
    }
    if (self.taggedFacebook == nil) {
        self.taggedFacebook = [NSMutableArray array];
    }

}

@synthesize delegate;
-(void)viewWillDisappear:(BOOL)animated
{
    [delegate sendDataToPostViewfacebook:self.taggedFacebook contacts:self.taggedContacts world:[self.worldButton.backgroundColor isEqual:[UIColor lightGrayColor]]];
    
}

- (void) reopenWithFacebook:(NSMutableArray*)facebookTags contacts:(NSMutableArray *)contactTags world:(BOOL)world {
    self.taggedFacebook = facebookTags;
    self.taggedContacts = contactTags;
    self.toWorld = world;
    [self.tableView reloadData];
    
}

- (void)worldButtonPressed{
    if (self.worldButton.backgroundColor == [UIColor whiteColor]) {
        [self.worldButton setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.worldButton setBackgroundColor:[UIColor whiteColor]];
    }
}
- (void)friendsButtonPressed{
    if (self.friendsButton.backgroundColor == [UIColor whiteColor]) {
        [self.friendsButton setBackgroundColor:[UIColor lightGrayColor]];
        [self.taggedFacebook addObjectsFromArray:self.allFacebook];
    } else {
        [self.friendsButton setBackgroundColor:[UIColor whiteColor]];
        for (NSArray *fbInfo in self.allFacebook){
            [self.taggedFacebook removeObjectAtIndex:[self.taggedFacebook indexOfObject:fbInfo]];
        }
    }
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

-(void) dealloc {
    [self.searchController.view removeFromSuperview];
}

-(void) tagPeople {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.contentView.backgroundColor != [UIColor lightGrayColor]){
        [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
        if([cell.detailTextLabel.text length] > 14){
            [self.taggedFacebook addObject:[NSArray arrayWithObjects:cell.textLabel.text, cell.detailTextLabel.text, nil]];
        } else {
            [self.taggedContacts addObject:[NSArray arrayWithObjects:cell.textLabel.text, cell.detailTextLabel.text, nil]];
        }
    } else {
        [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        if([cell.detailTextLabel.text length] > 14){
            [self.taggedFacebook removeObject:[NSArray arrayWithObjects:cell.textLabel.text, cell.detailTextLabel.text, nil]];
        } else {
            [self.taggedContacts removeObject:[NSArray arrayWithObjects:cell.textLabel.text, cell.detailTextLabel.text, nil]];
        }
    }
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
    
    if ([self.taggedFacebook containsObject:self.searchResults[indexPath.row]] || [self.taggedContacts containsObject:self.searchResults[indexPath.row]]) {
        [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    //TODO(0): fix bug with color of cell on reload data (need to check if

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