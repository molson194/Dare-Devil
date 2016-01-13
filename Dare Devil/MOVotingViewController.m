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
    [userSubmitted fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        cell.personSubmitted.text = [object objectForKey:@"name"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    if (object[@"video"]) {
        PFFile *video = [object objectForKey:@"video"];
        cell.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        cell.videoView = [AVPlayerLayer playerLayerWithPlayer:cell.player];
        cell.videoView.frame = CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60);
        cell.videoView.videoGravity = AVLayerVideoGravityResizeAspect;
        cell.videoView.needsDisplayOnBoundsChange = YES;
        [cell.layer addSublayer:cell.videoView];
    } else if (object[@"image"]) {
        cell.imageView = nil;
        if (object[@"isVertical"] == [NSNumber numberWithBool:YES]) {
            cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60)];
        } else {
            cell.imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width-100)];
        }
        cell.imageView.file = [object objectForKey:@"image"];
        [cell.imageView setClipsToBounds:YES];
        [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [cell.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [cell addSubview:cell.imageView];
    }
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *obj = [self.objects objectAtIndex:indexPath.row];
    if (obj[@"isVertical"] == [NSNumber numberWithBool:YES]){
        return self.view.bounds.size.width + 120;
    } else {
        return self.view.bounds.size.width-50;
    }
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"dare" equalTo:self.obj];
    [query orderByDescending:@"createdAt"];
    return query;
}

@end
