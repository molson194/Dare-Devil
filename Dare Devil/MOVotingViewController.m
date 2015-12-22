//
//  MOVotingViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/15/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOVotingViewController.h"
#import "MOSubmissionsCell.h"
#import <Parse/Parse.h>

@interface MOVotingViewController ()
@property (nonatomic, strong) PFObject *obj;
@property (nonatomic) CGFloat previousScrollViewYOffset;
@end

@implementation MOVotingViewController

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
}

- (void)setObject:(PFObject *)object {
    [object fetchIfNeededInBackground];
    self.obj = object;
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";
    MOSubmissionsCell *cell = (MOSubmissionsCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MOSubmissionsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    PFUser *userSubmitted = (PFUser *)[object objectForKey:@"user"];
    [userSubmitted fetchIfNeededInBackground];
    cell.personSubmitted.text = [userSubmitted objectForKey:@"username"];
    if ([[object objectForKey:@"votingFavorites"] containsObject:[PFUser currentUser].objectId]) {
        cell.favoriteButton.selected = true;
    } else {
        cell.favoriteButton.selected = false;
    }
    [cell.favoriteButton addTarget:self action:@selector(favoriteDare:) forControlEvents:UIControlEventTouchUpInside];
    [[cell.favoriteButton layer] setValue:object forKey:@"submissionObject"];
    cell.favoriteButton.tag = indexPath.row;
    [cell addSubview:cell.favoriteButton];
    
    if (object[@"video"]) {
        PFFile *video = [object objectForKey:@"video"];
        cell.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        cell.videoView = [AVPlayerLayer playerLayerWithPlayer:cell.player];
        cell.videoView.frame = CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60);
        cell.videoView.videoGravity = AVLayerVideoGravityResizeAspect;
        cell.videoView.needsDisplayOnBoundsChange = YES;
        [cell.layer addSublayer:cell.videoView];
    } else if (object[@"image"]) {
        cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60)];
        cell.imageView.file = [object objectForKey:@"image"];
        [cell.imageView loadInBackground];
        [cell addSubview:cell.imageView];
    }
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.view.bounds.size.width + 110;
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"dare" equalTo:self.obj];
    [query orderByDescending:@"createdAt"];
    return query;
}

// FAVORITE DARE ACTION
- (void)favoriteDare:(UIButton *)sender {
    if (!sender.selected) {
        PFObject *object = [[sender layer] valueForKey:@"submissionObject"];
        NSMutableArray *array = [object objectForKey:@"votingFavorites"];
        [array addObject:[PFUser currentUser].objectId];
        [object saveInBackground];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        sender.selected = YES;
    }
}

@end
