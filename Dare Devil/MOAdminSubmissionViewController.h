//
//  MOAdminSubmissionViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 12/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface MOAdminSubmissionViewController : PFQueryTableViewController <UINavigationControllerDelegate,UIScrollViewDelegate, UITableViewDelegate>

- (void)setObject:(PFObject *)object;

@end

