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
#import "MOSubmissionsCell.h"
#import "SWRevealViewController.h"
#import <Parse/Parse.h>

@interface MOCompletedDaresViewController ()
@property (nonatomic) CGFloat previousScrollViewYOffset;
@end

@implementation MOCompletedDaresViewController

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
    MOSubmissionsCell *cell = (MOSubmissionsCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MOSubmissionsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSMutableArray *subArray = [object objectForKey:@"submissions"];
    __block long max = -1;
    __block PFObject *submissionObject;
    for (PFObject* submission in subArray) {
        [submission fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            NSMutableArray *votingArray = [object objectForKey:@"votingFavorites"];
            long count = [votingArray count];
            if (count > max){
                max = count;
                submissionObject = submission;
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }]; //TODO(0): MAKE SURE NOT EVERY PIC IS FETCHED
    }

    cell.dareLabel.text = [object objectForKey:@"text"];
    [cell.contentView addSubview:cell.dareLabel];
    cell.moneyRaised.text = [NSString stringWithFormat:@"$ %lu", (unsigned long) [[object objectForKey:@"funders"] count]];
    
    PFUser *userSubmitted = (PFUser *)[submissionObject objectForKey:@"user"];
    [userSubmitted fetchIfNeededInBackground];
    cell.personSubmitted.text = [userSubmitted objectForKey:@"name"];

    if (submissionObject[@"video"]) {
        PFFile *video = [submissionObject objectForKey:@"video"];
        cell.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        cell.videoView = [AVPlayerLayer playerLayerWithPlayer:cell.player];
        cell.videoView.frame = CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60);
        cell.videoView.videoGravity = AVLayerVideoGravityResizeAspect;
        cell.videoView.needsDisplayOnBoundsChange = YES;
        [cell.layer addSublayer:cell.videoView];
    } else if (submissionObject[@"image"]) {
        cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60)];
        cell.imageView.file = [submissionObject objectForKey:@"image"];
        [cell.imageView loadInBackground];
        [cell addSubview:cell.imageView];
    }
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.view.bounds.size.width + 170;
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"hasSubmission" equalTo:[NSNumber numberWithBool:YES]];
    // TODO(0): after 24 hours
    return query;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    MOSubmissionsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ((indexPath.row + 1) > [self.objects count]) {
        [self loadNextPage];
    } else if (cell.player!=nil) {
        [cell.player seekToTime:kCMTimeZero];
        [cell.player play];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self stoppedScrolling];
    }
}

- (void)stoppedScrolling
{
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)animateNavBarTo:(CGFloat)y
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
    }];
}

@end
