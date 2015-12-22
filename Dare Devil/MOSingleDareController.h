//
//  MOSingleDareController.h
//  Dare Devil
//
//  Created by Matthew Olson on 12/22/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@interface MOSingleDareController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate>

- (void)setObject:(PFObject *)object;
@property (nonatomic, strong) __block PFObject *obj;
@property (nonatomic, strong) PFObject *uploadObject;
@property (nonatomic, strong) NSNumber *indexPathRow;


@end
