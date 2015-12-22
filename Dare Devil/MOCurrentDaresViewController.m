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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.navigationController.navigationBar.frame;
    CGFloat size = frame.size.height - 21;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - self.previousScrollViewYOffset;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
    
    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
    }
    
    [self.navigationController.navigationBar setFrame:frame];
    [self updateBarButtonItems:(1 - framePercentageHidden)];
    self.previousScrollViewYOffset = scrollOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self stoppedScrolling];
    }
}

- (void)stoppedScrolling {
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)updateBarButtonItems:(CGFloat)alpha {
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)animateNavBarTo:(CGFloat)y {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
    }];
}

@end
