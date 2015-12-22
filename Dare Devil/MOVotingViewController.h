//
//  MOVotingViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 12/15/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface MOVotingViewController : PFQueryTableViewController <UINavigationControllerDelegate,UIScrollViewDelegate, UITableViewDelegate>

- (void)setObject:(PFObject *)object;

@end
