//
//  MOMainViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/19/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOMainViewController.h"
#import "MOPostViewController.h"
#import "MOAddFundsViewController.h"
#import "MODareTableViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SWRevealViewController.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

@interface MOMainViewController ()
@property (nonatomic, strong) PFObject *uploadObject;
@property (nonatomic, strong) NSNumber *indexPathRow;
@property (nonatomic) CGFloat previousScrollViewYOffset;
@property (nonatomic) int queryHotRecent;
@property (nonatomic) int queryLocalFriends;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) PFGeoPoint *geoPoint;
@end

@implementation MOMainViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    // PARSE TABLE VIEW SETUP
    if (self) {
        self.parseClassName = @"Dare";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 10;
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NAVIGATION BAR SETUP
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDare)];
    self.navigationItem.rightBarButtonItem = addButton;
    SWRevealViewController *revealController = [self revealViewController];
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    UITapGestureRecognizer *tap = [revealController tapGestureRecognizer];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    // SORTING OPTIONS
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 75)];
    NSArray *popularitySort = [NSArray arrayWithObjects: @"Recent", @"Hot", nil];
    UISegmentedControl *popularityControl = [[UISegmentedControl alloc] initWithItems:popularitySort];
    popularityControl.frame = CGRectMake(5, 5, self.view.bounds.size.width-10, 30);
    [popularityControl addTarget:self action:@selector(popularityControlAction:) forControlEvents:UIControlEventValueChanged];
    popularityControl.selectedSegmentIndex = 0;
    [headerView addSubview:popularityControl];
    NSArray *peopleSort = [NSArray arrayWithObjects: @"World", @"Friends", @"Local", nil];
    UISegmentedControl *peopleControl = [[UISegmentedControl alloc] initWithItems:peopleSort];
    peopleControl.frame = CGRectMake(5, 40, self.view.bounds.size.width-10, 30);
    [peopleControl addTarget:self action:@selector(peopleControlAction:) forControlEvents:UIControlEventValueChanged];
    peopleControl.selectedSegmentIndex = 0;
    [headerView addSubview:peopleControl];
    [self.tableView setTableHeaderView:headerView];
    
    // LOCATION SERVICES
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            self.geoPoint = geoPoint;
        } else {
            self.geoPoint = [PFGeoPoint geoPointWithLatitude:0 longitude:0];
        }
    }];
}

// POST DARE NAVIGATION BUTTON ACTION
- (void)addDare {
    MOPostViewController *postViewController = [[MOPostViewController alloc] init];
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController pushViewController:postViewController animated:YES];
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";
    MODareTableViewCell *cell = (MODareTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MODareTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // DARE TEXT
    cell.dareLabel.text = [object objectForKey:@"text"];
    [cell.contentView addSubview:cell.dareLabel];
    
    // FUNDS BUTTON
    [cell.fundsButton setTitle: [NSString stringWithFormat:@"$ %lu", (unsigned long) [[object objectForKey:@"funders"] count]] forState: UIControlStateSelected];
    [cell.fundsButton setTitle: [NSString stringWithFormat:@"$ %lu", (unsigned long) [[object objectForKey:@"funders"] count]] forState: UIControlStateNormal];
    cell.fundsButton.tag = indexPath.row;
    if ([[object objectForKey:@"funders"] containsObject:[PFUser currentUser].objectId]) {
        cell.fundsButton.selected = true;
    } else {
        cell.fundsButton.selected = false;
    }
    [cell.fundsButton addTarget:self action:@selector(fundDare:) forControlEvents:UIControlEventTouchUpInside];
    [[cell.fundsButton layer] setValue:object forKey:@"dareObject"];
    [cell.contentView addSubview:cell.fundsButton];
    
    // UPLOAD CONTENT BUTTON
    PFQuery *uploadsQuery = [PFQuery queryWithClassName:@"Submissions"];
    [uploadsQuery whereKey:@"dare" equalTo:object];
    [uploadsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [cell.uploadButton setTitle: [NSString stringWithFormat:@"\u2191%lu", (unsigned long) [objects count]] forState: UIControlStateSelected];
            [cell.uploadButton setTitle: [NSString stringWithFormat:@"\u2191%lu", (unsigned long) [objects count]] forState: UIControlStateNormal];
        }
    }];
    [cell.uploadButton addTarget:self action:@selector(uploadSubmission:) forControlEvents:UIControlEventTouchUpInside];
    cell.uploadButton.tag = indexPath.row;
    [[cell.uploadButton layer] setValue:object forKey:@"dareObject"];
    PFQuery *userUploadsQuery = [PFQuery queryWithClassName:@"Submissions"];
    [userUploadsQuery whereKey:@"dare" equalTo:object];
    [userUploadsQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [userUploadsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if ([objects count] >= 1) {
                cell.uploadButton.selected = true;
            } else {
                cell.uploadButton.selected = false;
            }
        }
    }];
    [cell.contentView addSubview:cell.uploadButton];
    
    // TIME LEFT LABEL
    NSDate *endDate = [[object createdAt] dateByAddingTimeInterval:60*60*24*1];
    NSInteger diff = [endDate timeIntervalSinceDate:[NSDate date]]/60;
    if (diff>60) {
        cell.timeLeft.text = [NSMutableString stringWithFormat:@"%ldh", (long) diff/60];
    } else {
        cell.timeLeft.text = [NSMutableString stringWithFormat:@"%ldm", (long) diff];
    }
    [cell.contentView addSubview:cell.timeLeft];
    
    return cell;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

// ORGANIZE DATA BASED ON INDIVIDUALS/FRIENDS/PUBLIC, HOT/RECENT, NEARME/WORLD
- (PFQuery *)queryForTable {
    PFQuery *worldQuery = [PFQuery queryWithClassName:self.parseClassName];
    [worldQuery whereKey:@"toWorld" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *facebookQuery = [PFQuery queryWithClassName:self.parseClassName];
    NSString *fbId = [[PFUser currentUser] objectForKey:@"fbId"];
    [facebookQuery whereKey:@"facebookIds" containsAllObjectsInArray:[NSArray arrayWithObject:fbId]];
    
    PFQuery *userQuery = [PFQuery queryWithClassName:self.parseClassName];
    [userQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    
    //TODO(0): Targetted in a dare
    
    PFQuery *query;
    if (self.queryLocalFriends == 1 || self.queryLocalFriends ==0){
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:worldQuery, facebookQuery,userQuery, nil]];
    } else if (self.queryLocalFriends == 2) {
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects: facebookQuery, userQuery, nil]];
    } else if (self.queryLocalFriends == 3) {
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:worldQuery, facebookQuery,userQuery, nil]];
        [query whereKey:@"location" nearGeoPoint:self.geoPoint withinMiles:10.0];
    }
    if (self.queryHotRecent==1 || self.queryHotRecent == 0) {
        [query orderByDescending:@"createdAt"];
    } else if (self.queryHotRecent == 2) {
        [query orderByDescending:@"funders"];
    }
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-1*24*60*60]];
    return query;
}

- (void)popularityControlAction:(UISegmentedControl *)segment {
    if(segment.selectedSegmentIndex==0) {
        self.queryHotRecent = 1;
    } else if (segment.selectedSegmentIndex==1) {
        self.queryHotRecent = 2;
    }
    [self loadObjects];
}

- (void)peopleControlAction:(UISegmentedControl *)segment {
    if(segment.selectedSegmentIndex == 0) {
        self.queryLocalFriends = 1;
    } else if (segment.selectedSegmentIndex==1) {
        self.queryLocalFriends = 2;
    } else if (segment.selectedSegmentIndex==2) {
        self.queryLocalFriends = 3;
    }
    [self loadObjects];
}

// FUND DARE
- (void)fundDare:(UIButton *)sender{
    if (!sender.selected) {
        PFObject *object = [[sender layer] valueForKey:@"dareObject"];
        NSMutableArray *funders = [object objectForKey:@"funders"];
        [funders addObject:[PFUser currentUser].objectId];
        [object saveInBackground];
        int fundsRemaining = (int) [[[PFUser currentUser] objectForKey:@"funds"] integerValue] - 1;
        [[PFUser currentUser] setObject:@(fundsRemaining) forKey:@"funds"];
        [[PFUser currentUser] saveEventually];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (void)uploadSubmission:(UIButton *)sender {
    if (!sender.selected){
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        imagePicker.mediaTypes = [[NSMutableArray alloc] initWithObjects:(NSString *)kUTTypeMovie, kUTTypeImage, nil];
        [self presentViewController:imagePicker animated:YES completion:^{
            self.uploadObject = [[sender layer] valueForKey:@"dareObject"];
            self.indexPathRow = [NSNumber numberWithInt:(int)sender.tag];
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        PFObject *submission = [PFObject objectWithClassName:@"Submissions"];
    
        if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
            PFFile *videoFile = [PFFile fileWithName:@"video.mp4" contentsAtPath:[videoUrl path]];
            submission[@"video"] = videoFile;
        } else if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
            UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
            image = [self scaleAndRotateImage:image];
            NSData *imgData= UIImageJPEGRepresentation(image,0.8 /*compressionQuality*/);
            image = [UIImage imageWithData:imgData];
            PFFile *imageFile = [PFFile fileWithName:@"image.png" data:UIImagePNGRepresentation(image)];
            submission[@"image"] = imageFile;
        }
    
        submission[@"dare"] = self.uploadObject;
        submission[@"votingFavorites"] = [NSMutableArray array];
        submission[@"user"] = [PFUser currentUser];
        [submission saveInBackground];
        // Create our push query
        NSMutableArray *fundersPush = [self.uploadObject objectForKey:@"funders"];
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"userObject" containedIn:fundersPush];
        // Send push notification to query
        [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"%@ posted a new submission to the follwoing dare: %@", [[PFUser currentUser] objectForKey:@"name"], [self.uploadObject objectForKey:@"text"]]];
        
        PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
        notification[@"text"] = [NSString stringWithFormat:@"%@ posted a new submission to the follwoing dare: %@", [[PFUser currentUser] objectForKey:@"name"], [self.uploadObject objectForKey:@"text"]];
        notification[@"dare"] = self.uploadObject;
        notification[@"type"] = @"New Submission";
        notification[@"followers"] = fundersPush;
        [notification saveInBackground];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.indexPathRow integerValue] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }];
}

- (UIImage *)scaleAndRotateImage:(UIImage *) image {
    int kMaxResolution = 720;
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

@end
