//
//  MOMainViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 9/19/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <CoreLocation/CoreLocation.h>

@interface MOMainViewController : PFQueryTableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate,UIScrollViewDelegate, CLLocationManagerDelegate, UITableViewDelegate>

@end
