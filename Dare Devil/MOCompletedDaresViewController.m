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
    static NSString *CellIdentifier = nil;
    CellIdentifier = [NSString stringWithFormat: @"Cell%li", (long)indexPath.row];
    MOSubmissionsCell *cell = (MOSubmissionsCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MOSubmissionsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    PFObject *dareObject = [object objectForKey:@"dare"];
    [dareObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        cell.dareLabel.text = [object objectForKey:@"text"];
        [cell.contentView addSubview:cell.dareLabel];
        cell.moneyRaised.text = [NSString stringWithFormat:@"$ %lu", (unsigned long) [[object objectForKey:@"funders"] count]];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];

    
    PFUser *userSubmitted = (PFUser *)[object objectForKey:@"user"];
    [userSubmitted fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            cell.personSubmitted.text = [object objectForKey:@"name"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    if (object[@"video"]) {
        PFFile *video = [object objectForKey:@"video"];
        cell.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        cell.videoView = nil;
        cell.videoView = [AVPlayerLayer playerLayerWithPlayer:cell.player];
        cell.videoView.frame = CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width+60);
        cell.videoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
        cell.videoView.needsDisplayOnBoundsChange = YES;
        [cell.layer addSublayer:cell.videoView];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if (object[@"image"]) {
        cell.imageView = nil;
        if (object[@"isVertical"] == [NSNumber numberWithBool:YES]) {
            cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width+60)];
        } else {
            cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width-100)];
        }
        cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
        cell.imageView.file = [object objectForKey:@"image"];
        [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [cell.imageView setClipsToBounds:YES];
        [cell.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [cell.contentView addSubview:cell.imageView];
    }
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    [obj fetchInBackground];
    if (obj[@"isVertical"] == [NSNumber numberWithBool:YES]){
        return self.view.bounds.size.width + 150;
    } else {
        return self.view.bounds.size.width-20;
    }
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName]; // TODO handle private dares
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"isWinner" equalTo:[NSNumber numberWithBool:YES]];
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

@end
