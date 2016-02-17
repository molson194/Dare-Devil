//
//  SideViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 11/24/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "SideViewController.h"
#import "SWRevealViewController.h"
#import "MOAddFundsViewController.h"
#import "MOCompletedDaresViewController.h"
#import "MOMainViewController.h"
#import "MOActivityViewController.h"
#import "MOAdminDareViewController.h"
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

@interface SideViewController ()
@end

@implementation SideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 250)];
    PFImageView *imageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 10, 200, 200)];
    imageView.file = [[PFUser currentUser] objectForKey:@"profilePic"];
    [imageView setClipsToBounds:YES];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView loadInBackground];
    [headerView addSubview:imageView];
    UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, 200, 200)];
    UIImage *image = [UIImage imageNamed:@"ProfileBackground.png"];
    imageHolder.image = image;
    [headerView addSubview:imageHolder];
    UILabel *personSubmitted = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, 200, 30)];
    personSubmitted.textColor = [UIColor blackColor];
    [personSubmitted setFont:[UIFont systemFontOfSize:15]];
    personSubmitted.textAlignment = NSTextAlignmentCenter;
    personSubmitted.text = [[PFUser currentUser] objectForKey:@"name"];
    [headerView addSubview:personSubmitted];
    [self.tableView setTableHeaderView:headerView];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 250, 15)];
    emailLabel.text = @"Email questions to daredevilllc@gmail.com";
    emailLabel.textAlignment = NSTextAlignmentCenter;
    [emailLabel setFont:[UIFont systemFontOfSize:10]];
    [footerView addSubview:emailLabel];
    [self.tableView setTableFooterView:footerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    SWRevealViewController *grandParentRevealController = self.revealViewController.revealViewController;
    grandParentRevealController.bounceBackOnOverdraw = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    SWRevealViewController *grandParentRevealController = self.revealViewController.revealViewController;
    grandParentRevealController.bounceBackOnOverdraw = YES;
}


#pragma marl - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([PFUser currentUser][@"isAdmin"] == [NSNumber numberWithBool:YES]) {
        return 5;
    } else {
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSInteger row = indexPath.row;
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    NSString *text = nil;
    if (row == 0) {
        text = @"Transfer Funds";
    } else if (row == 1) {
        text = @"Dares Feed";
    } else if (row == 2) {
        text = @"Completed Dares";
    } else if (row ==3) {
        text = @"Activity";
    } else if (row == 4) {
        text = @"Admin Activities";
    }
    cell.textLabel.text = NSLocalizedString( text, nil );
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SWRevealViewController *revealController = self.revealViewController;
    NSInteger row = indexPath.row;
    
    UIViewController *newFrontController = nil;
    if (row == 0) {
        MOAddFundsViewController *addFundsViewController = [[MOAddFundsViewController alloc] init];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:addFundsViewController];
    } else if (row==1) {
        MOMainViewController *postedDaresViewController = [[MOMainViewController alloc] initWithStyle:UITableViewStylePlain];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:postedDaresViewController];
    } else if (row==2) {
        MOCompletedDaresViewController *completedDaresViewController = [[MOCompletedDaresViewController alloc] initWithStyle:UITableViewStylePlain];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:completedDaresViewController];
    } else if (row==3) {
        MOActivityViewController *activityViewController = [[MOActivityViewController alloc] initWithStyle:UITableViewStylePlain];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:activityViewController];
    } else if (row==4) {
        MOAdminDareViewController *adminViewController = [[MOAdminDareViewController alloc] initWithStyle:UITableViewStylePlain];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:adminViewController];
    }
    [revealController pushFrontViewController:newFrontController animated:YES];
}


@end
