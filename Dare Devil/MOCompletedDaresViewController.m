//
//  MOCompletedDaresViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 10/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOCompletedDaresViewController.h"
#import "MOPostViewController.h"
#import "MOAddFundsViewController.h"
#import "SWRevealViewController.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>
#import "MOSingleSubmissionViewController.h"

@interface MOCompletedDaresViewController ()
@property (nonatomic) CGFloat previousScrollViewYOffset;
@property (nonatomic) NSMutableDictionary* players;
@end

@implementation MOCompletedDaresViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    // PARSE TABLE VIEW SETUP
    if (self) {
        self.parseClassName = @"Submissions";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 10;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NAVIGATION BAR SETUP
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDare)];
    self.navigationItem.rightBarButtonItem = addButton;
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Completed Dares";
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
    
    self.players = [NSMutableDictionary dictionary];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFObject *dareObject = [object objectForKey:@"dare"];
    [dareObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        UITextView *dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(3, 0, self.view.bounds.size.width-6, 50)];
        dareLabel.textColor = [UIColor blackColor];
        [dareLabel setFont:[UIFont systemFontOfSize:12]];
        dareLabel.scrollEnabled = false;
        dareLabel.editable = false;
        [dareLabel setUserInteractionEnabled:NO];
        dareLabel.text = [object objectForKey:@"text"];
        [cell.contentView addSubview:dareLabel];
        UILabel *moneyRaised = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-60, 15, 50, 15)];
        moneyRaised.textColor = [UIColor blackColor];
        [moneyRaised setTextAlignment:NSTextAlignmentRight];
        [moneyRaised setFont:[UIFont systemFontOfSize:15]];
        [cell.contentView addSubview:moneyRaised];
        NSNumber *funding = [object objectForKey:@"totalFunding"];
        moneyRaised.text = [NSString stringWithFormat:@"$%d", funding.intValue ];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];

    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    PFQuery *queryWorld = [PFQuery queryWithClassName:self.parseClassName];
    PFQuery *queryFacebook = [PFQuery queryWithClassName:self.parseClassName];
    [queryWorld whereKey:@"toWorld" equalTo:[NSNumber numberWithBool:YES]];
    [queryFacebook whereKey:@"facebookIds" containsAllObjectsInArray:@[[[PFUser currentUser] objectForKey:@"fbId"]]];
    
    query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryFacebook, queryWorld, nil]];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"isWinner" equalTo:[NSNumber numberWithBool:YES]];
    
    return query;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((indexPath.row + 1) > [self.objects count]) {
        [self loadNextPage];
    } else {
        MOSingleSubmissionViewController *view = [[MOSingleSubmissionViewController alloc] initWithStyle:UITableViewStylePlain];
        [view setObject:[self.objects objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:view animated:YES];
    }
}

@end
