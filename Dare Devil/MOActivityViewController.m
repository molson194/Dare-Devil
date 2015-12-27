//
//  MOActivityViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/17/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOActivityViewController.h"
#import "SWRevealViewController.h"
#import "MOPostViewController.h"
#import <Parse/Parse.h>
#import "MOVotingViewController.h"
#import "MOSingleDareController.h"

@interface MOActivityViewController ()
@property (nonatomic) CGFloat previousScrollViewYOffset;
@end

@implementation MOActivityViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    // PARSE TABLE VIEW SETUP
    if (self) {
        self.parseClassName = @"Notifications";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 10;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NAVIGATION BAR SETUP
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDare)];
    self.navigationItem.rightBarButtonItem = addButton;
    SWRevealViewController *revealController = [self revealViewController];
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    UITapGestureRecognizer *tap = [revealController tapGestureRecognizer];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

// POST DARE NAVIGATION BUTTON ACTION
- (void)addDare {
    MOPostViewController *postViewController = [[MOPostViewController alloc] init];
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController pushViewController:postViewController animated:YES];
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [object objectForKey:@"text"];
    return cell;
}

// ORGANIZE QUERY
- (PFQuery *)queryForTable {
    PFQuery *queryUsers = [PFQuery queryWithClassName:self.parseClassName];
    [queryUsers whereKey:@"followers" containsAllObjectsInArray:@[[PFUser currentUser].objectId]];
    
    PFQuery *queryFacebook = [PFQuery queryWithClassName:self.parseClassName];
    [queryFacebook whereKey:@"facebook" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryUsers, queryFacebook, nil]];
    [query orderByDescending:@"createdAt"];
    return query;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    //if created at > 2 days or if new dare and > 1 day
    NSDate *createdAt = obj.createdAt;
    NSDate *now = [NSDate date];
    
    if (([now laterDate:[createdAt dateByAddingTimeInterval:2*24*60*60]] == now) && [obj[@"type"] isEqualToString:@"New Submission"]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Voting Over" message:@"48 Hours after dare posted" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (([now laterDate:[createdAt dateByAddingTimeInterval:24*60*60]] == now) && [obj[@"type"] isEqualToString:@"New Dare"]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Fudning/Submissions Over" message:@"24 Hours after dare posted" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
    
        if ([obj[@"type"] isEqualToString:@"New Submission"]) {
            PFObject *dareObj = obj[@"dare"];
            [dareObj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                MOVotingViewController *votingView = [[MOVotingViewController alloc] initWithStyle:UITableViewStylePlain];
                [votingView setObject:object];
                [self.navigationController pushViewController:votingView animated:YES];
            }];
        } else if ([obj[@"type"] isEqualToString:@"New Dare"]) {
            PFObject *dareObj = obj[@"dare"];
            [dareObj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                MOSingleDareController *singleView = [[MOSingleDareController alloc] initWithStyle:UITableViewStylePlain];
                [singleView setObject:object];
                [self.navigationController pushViewController:singleView animated:YES];
            }];
        }
    }
}

@end
