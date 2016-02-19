//
//  MOAdminDareViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOAdminDareViewController.h"
#import "SWRevealViewController.h"
#import "MOPostViewController.h"
#import <Parse/Parse.h>
#import "MOAdminSubmissionViewController.h"

@interface MOAdminDareViewController ()
@end

@implementation MOAdminDareViewController

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
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadObjects];
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // DARE TEXT
    UITextView *dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, 7*self.view.bounds.size.width/8, 70)];
    dareLabel.textColor = [UIColor blackColor];
    [dareLabel setFont:[UIFont systemFontOfSize:15]];
    dareLabel.scrollEnabled = false;
    dareLabel.editable = false;
    dareLabel.text = [object objectForKey:@"text"];
    [dareLabel setUserInteractionEnabled:NO];
    [cell.contentView addSubview:dareLabel];
    
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

// ORGANIZE QUERY
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"isFinished" equalTo:[NSNumber numberWithBool:NO]];
    [query whereKey:@"closeDate" lessThan:[NSDate date]];
    return query;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    [obj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        MOAdminSubmissionViewController *adminView = [[MOAdminSubmissionViewController alloc] initWithStyle:UITableViewStylePlain];
        [adminView setObject:object];
        [self.navigationController pushViewController:adminView animated:YES];
    }];
}

@end
