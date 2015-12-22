//
//  MOCurrentDaresViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/15/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOCurrentDaresViewController.h"
#import "SWRevealViewController.h"
#import "MOPostViewController.h"
#import "MODareTableViewCell.h"
#import <Parse/Parse.h>
#import "MOVotingViewController.h"

@interface MOCurrentDaresViewController ()
@property (nonatomic) CGFloat previousScrollViewYOffset;
@end

@implementation MOCurrentDaresViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    // PARSE TABLE VIEW SETUP
    if (self) {
        self.parseClassName = @"Dare";
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
    MODareTableViewCell *cell = (MODareTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MODareTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // DARE TEXT
    cell.dareLabel.text = [object objectForKey:@"text"];
    [cell.contentView addSubview:cell.dareLabel];
    
    // UPLOAD CONTENT BUTTON
    PFQuery *uploadsQuery = [PFQuery queryWithClassName:@"Submissions"];
    [uploadsQuery whereKey:@"dare" equalTo:object];
    [uploadsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [cell.uploadButton setTitle: [NSString stringWithFormat:@"\u2191%lu", (unsigned long) [objects count]] forState: UIControlStateSelected];
            [cell.uploadButton setTitle: [NSString stringWithFormat:@"\u2191%lu", (unsigned long) [objects count]] forState: UIControlStateNormal];
        }
    }];
    
    // TIME LEFT LABEL
    NSDate *endDate = [[object createdAt] dateByAddingTimeInterval:60*60*24*1];
    NSInteger diff = [endDate timeIntervalSinceDate:[NSDate date]]/60;
    if (diff>60) {
        cell.timeLeft.text = [NSMutableString stringWithFormat:@"%ldh", (long) diff/60];
    } else {
        cell.timeLeft.text = [NSMutableString stringWithFormat:@"%ldm", (long) diff];
    }
    [cell.contentView addSubview:cell.timeLeft];
    
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

// ORGANIZE QUERY
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-1*24*60*60]];
    [query whereKey:@"funders" containsAllObjectsInArray:@[[PFUser currentUser].objectId]];
    return query;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    MOVotingViewController *votingView = [[MOVotingViewController alloc] initWithStyle:UITableViewStylePlain];
    [votingView setObject:obj];
    [self.navigationController pushViewController:votingView animated:YES];
}

@end
