//
//  MOSingleSubmissionViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 2/16/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@interface MOSingleSubmissionViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate>

- (void)setObject:(PFObject *)object;
@property (nonatomic, strong) __block PFObject *obj;

@end
