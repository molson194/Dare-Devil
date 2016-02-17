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
#import "MOSingleDareController.h"
#import "MOSingleSubmissionViewController.h"

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
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:0.88 green:0.40 blue:0.40 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDare)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton setTintColor:[UIColor whiteColor]];
    SWRevealViewController *revealController = [self revealViewController];
    UIImage* menuImage = [UIImage imageNamed:@"menuicon.png"];
    UIButton *menuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [menuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
    [menuButton addTarget:revealController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
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
    if ((indexPath.row + 1) > [self.objects count]) {
        [self loadNextPage];
        return;
    }
    
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    PFObject *dareObj = obj[@"dare"];
    
    if ([obj[@"type"] isEqualToString:@"New Submission"]) {
        PFQuery *query  = [PFQuery queryWithClassName:@"Submissions"];
        [query whereKey:@"dare" equalTo:dareObj];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            MOSingleSubmissionViewController *view = [[MOSingleSubmissionViewController alloc] initWithStyle:UITableViewStylePlain];
            [view setObject:objects[1]];
            [self.navigationController pushViewController:view animated:YES];
        }];
    } else if ([obj[@"type"] isEqualToString:@"New Dare"]) {
        [dareObj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            MOSingleDareController *singleView = [[MOSingleDareController alloc] initWithStyle:UITableViewStylePlain];
            [singleView setObject:object];
            [self.navigationController pushViewController:singleView animated:YES];
        }];
    }
}

@end
