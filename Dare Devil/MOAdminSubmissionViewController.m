//
//  MOAdminSubmissionViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOAdminSubmissionViewController.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

@interface MOAdminSubmissionViewController ()
@property (nonatomic, strong) PFObject *obj;
@property (nonatomic) CGFloat previousScrollViewYOffset;
@end

@implementation MOAdminSubmissionViewController

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
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    // ADD FUNDS BUTTON
    UIButton *returnFunds=[UIButton buttonWithType:UIButtonTypeCustom];
    returnFunds.backgroundColor=[UIColor blueColor];
    returnFunds.frame=CGRectMake(20,5,self.view.bounds.size.width/2-21,30);
    [returnFunds setTitle: @"Return $1" forState: UIControlStateNormal];
    [returnFunds addTarget:self action:@selector(returnFundsPressed) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:returnFunds];
    
    // CASH OUT BUTTON
    UIButton *winner=[UIButton buttonWithType:UIButtonTypeCustom];
    winner.backgroundColor=[UIColor blueColor];
    winner.frame=CGRectMake(self.view.bounds.size.width/2+1,5,self.view.bounds.size.width/2-21,30);
    [winner setTitle: @"Winner Payout" forState: UIControlStateNormal];
    [winner addTarget:self action:@selector(winnerPressed) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:winner];
    self.tableView.tableHeaderView = headerView;
}

- (void)setObject:(PFObject *)object {
    self.obj = object;
}

- (void) returnFundsPressed {
    //todo
    NSDictionary *funders = [self.obj objectForKey:@"funders"];
    PFQuery * query = [PFUser query];
    [query whereKey:@"objectId" containedIn:[funders allKeys]];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            [PFCloud callFunctionInBackground:@"refund" withParameters:@{@"idArray": funders} block:^(id  _Nullable object, NSError * _Nullable error) {
                if (!error) {
                    [self.obj setObject:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                    [self.obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded){
                            // Create our push query
                            NSMutableArray *fundersPush = [self.obj objectForKey:@"funders"];
                            PFQuery *pushQuery = [PFInstallation query];
                            [pushQuery whereKey:@"userObject" containedIn:fundersPush];
                            // Send push notification to query
                            [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"A dare was refunded"]];
                            
                            PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
                            notification[@"text"] = [NSString stringWithFormat:@"A dare was refunded"];
                            notification[@"dare"] = self.obj;
                            notification[@"type"] = @"Refund";
                            notification[@"followers"] = fundersPush;
                            [notification saveInBackground];
                            [self.navigationController popToRootViewControllerAnimated:YES];
                        }
                    }];
                }
                
            }];
    }];
}

- (void) winnerPressed {
    PFUser *winner = [self.obj objectForKey:@"user"];
    [winner fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        int funds = [[object objectForKey:@"funds"] intValue];
        int winnings = [[self.obj objectForKey:@"totalFunding" ] intValue];
        [PFCloud callFunctionInBackground:@"winner" withParameters:@{@"id":winner.objectId, @"newFunds":[NSNumber numberWithInt:(funds+winnings)]} block:^(id  _Nullable object, NSError * _Nullable error) {
            if (!error) {
                [self.obj setObject:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                [self.obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded){
                        // Create our push query
                        NSMutableDictionary* allFunders = [self.obj objectForKey:@"funders"];
                        NSArray *fundersPush = [allFunders allKeys];
                        PFQuery *pushQuery = [PFInstallation query];
                        [pushQuery whereKey:@"userObject" containedIn:fundersPush];
                        PFQuery *pushQueryWinner = [PFInstallation query];
                        [pushQueryWinner whereKey:@"userObject" containedIn:@[winner.objectId]];
                        [PFPush sendPushMessageToQueryInBackground:[PFQuery orQueryWithSubqueries:@[pushQuery, pushQueryWinner]] withMessage:[NSString stringWithFormat:@"%@ won a tagged dare.", [winner objectForKey:@"name"]]];
                        
                        PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
                        notification[@"text"] = [NSString stringWithFormat:@"%@ won a tagged dare", [winner objectForKey:@"name"]];
                        notification[@"dare"] = self.obj;
                        notification[@"type"] = @"Winner";
                        notification[@"followers"] = fundersPush;
                        [notification saveInBackground];
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }
                }];
            }
        }];

    }];
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    PFUser *userSubmitted = (PFUser *)[object objectForKey:@"user"];
    [userSubmitted fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        UILabel* personSubmitted = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, self.view.bounds.size.width-80, 15)];
        personSubmitted.textColor = [UIColor blackColor];
        [personSubmitted setFont:[UIFont systemFontOfSize:15]];
        [cell.contentView addSubview:personSubmitted];
        personSubmitted.text = [object objectForKey:@"name"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    if (object[@"video"]) {
        PFFile *video = [object objectForKey:@"video"];
        AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        AVPlayerLayer *videoView = [AVPlayerLayer playerLayerWithPlayer:player];
        videoView.frame = CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60);
        videoView.videoGravity = AVLayerVideoGravityResizeAspect;
        videoView.needsDisplayOnBoundsChange = YES;
        [cell.layer addSublayer:videoView];
    } else if (object[@"image"]) {
        PFImageView *imageView = nil;
        if (object[@"isVertical"] == [NSNumber numberWithBool:YES]) {
            imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width+60)];
        } else {
            imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 50, cell.bounds.size.width, cell.bounds.size.width-100)];
        }
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        imageView.file = [object objectForKey:@"image"];
        [imageView setClipsToBounds:YES];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [cell addSubview:imageView];
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
