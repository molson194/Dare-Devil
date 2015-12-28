//
//  MOAdminSubmissionViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOAdminSubmissionViewController.h"
#import "MOSubmissionsCell.h"
#import <Parse/Parse.h>

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
    [winner addTarget:self action:@selector(winnerPressed) forControlEvents:UIControlEventTouchUpInside]; // TODO: function: isFinished -> true, add $ to most liked, pop
    [headerView addSubview:winner];
    self.tableView.tableHeaderView = headerView;
}

- (void)setObject:(PFObject *)object {
    self.obj = object;
}

- (void) returnFundsPressed {
    NSArray *funders = [self.obj objectForKey:@"funders"];
    PFQuery * query = [PFUser query];
    [query whereKey:@"objectId" containedIn:funders];
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
                            [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"The following dare was refunded: %@", [self.obj objectForKey:@"text"]]];
                            
                            PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
                            notification[@"text"] = [NSString stringWithFormat:@"The following dare was refunded: %@", [self.obj objectForKey:@"text"]];
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
        cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
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
