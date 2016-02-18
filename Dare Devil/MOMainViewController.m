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
#import <MobileCoreServices/MobileCoreServices.h>
#import "SWRevealViewController.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "MODareFundsViewController.h"

@interface MOMainViewController ()
@property (nonatomic, strong) PFObject *uploadObject;
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
    [super viewWillAppear:animated];
    [self loadObjects];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NAVIGATION BAR SETUP
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDare)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton setTintColor:[UIColor whiteColor]];
    SWRevealViewController *revealController = [self revealViewController];
    UIImage* menuImage = [UIImage imageNamed:@"menuicon.png"];
    UIButton *menuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [menuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
    [menuButton addTarget:revealController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Open Dares";
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    UITapGestureRecognizer *tap = [revealController tapGestureRecognizer];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    // SORTING OPTIONS
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 75)];
    NSArray *popularitySort = [NSArray arrayWithObjects: @"Recent", @"Hot", nil];
    UISegmentedControl *popularityControl = [[UISegmentedControl alloc] initWithItems:popularitySort];
    popularityControl.tintColor = [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
    popularityControl.frame = CGRectMake(5, 5, self.view.bounds.size.width-10, 30);
    [popularityControl addTarget:self action:@selector(popularityControlAction:) forControlEvents:UIControlEventValueChanged];
    popularityControl.selectedSegmentIndex = 0;
    [headerView addSubview:popularityControl];
    NSArray *peopleSort = [NSArray arrayWithObjects: @"World", @"Friends", @"Local", nil];
    UISegmentedControl *peopleControl = [[UISegmentedControl alloc] initWithItems:peopleSort];
    peopleControl.tintColor = [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
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
    static NSString *CellIdentifier;
    CellIdentifier = [NSString stringWithFormat:@"Cell %ld",(long)indexPath.row];
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // DARE TEXT
    UITextView *dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, 7*self.view.bounds.size.width/8, 70)];
    dareLabel.textColor = [UIColor blackColor];
    [dareLabel setFont:[UIFont systemFontOfSize:15]];
    dareLabel.scrollEnabled = false;
    dareLabel.editable = false;
    [dareLabel setUserInteractionEnabled:NO];
    dareLabel.text = [object objectForKey:@"text"];
    [cell.contentView addSubview:dareLabel];
    
    // FUNDS BUTTON
    UILabel *fundsLabel = [[UILabel alloc] initWithFrame:CGRectMake(7*self.view.bounds.size.width/8-10, 40, self.view.bounds.size.width/8, 12)];
    fundsLabel.textAlignment = NSTextAlignmentRight;
    fundsLabel.textColor = [UIColor blackColor];
    fundsLabel.text = [NSString stringWithFormat:@"$%@",[[object objectForKey:@"totalFunding"] stringValue]];
    [cell.contentView addSubview:fundsLabel];
    
    // TIME LEFT LABEL
    UILabel* timeLeft = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-35, 5, 30, 12)];
    timeLeft.textColor = [UIColor lightGrayColor];
    [timeLeft setTextAlignment:NSTextAlignmentCenter];
    timeLeft.font = [UIFont systemFontOfSize:13];
    NSDate *endDate = [object objectForKey:@"closeDate"];
    NSInteger diff = [endDate timeIntervalSinceDate:[NSDate date]]/60;
    if (diff>1440){
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldd", (long) diff/1440];
    } else if (diff>60) {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldh", (long) diff/60];
    } else {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldm", (long) diff];
    }
    [cell.contentView addSubview:timeLeft];
    
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
    
    PFQuery *query;
    if (self.queryLocalFriends == 1 || self.queryLocalFriends ==0){
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:worldQuery, nil]];
    } else if (self.queryLocalFriends == 2) {
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects: facebookQuery, userQuery, nil]];
    } else if (self.queryLocalFriends == 3) {
        query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:worldQuery, facebookQuery,userQuery, nil]];
        [query whereKey:@"location" nearGeoPoint:self.geoPoint withinMiles:10.0];
    }
    if (self.queryHotRecent==1 || self.queryHotRecent == 0) {
        [query orderByDescending:@"createdAt"];
    } else if (self.queryHotRecent == 2) {
        [query orderByDescending:@"totalFunding"];
    }
    [query whereKey:@"closeDate" greaterThan:[NSDate date]];
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

- (void)uploadSubmission:(PFObject *)obj {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    imagePicker.mediaTypes = [[NSMutableArray alloc] initWithObjects:(NSString *)kUTTypeMovie, kUTTypeImage, nil];
    [self presentViewController:imagePicker animated:YES completion:^{
            self.uploadObject = obj;
    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:@"target"] isEqualToString:[[PFUser currentUser] objectForKey:@"fbId"]]) {
        [self uploadSubmission:[self.objects objectAtIndex:indexPath.row]];
    } else {
        MODareFundsViewController *addFundsViewController = [[MODareFundsViewController alloc] init];
        [addFundsViewController addFunds:true forDare:[self.objects objectAtIndex:indexPath.row]];
        self.navigationController.navigationBar.hidden = NO;
        [self.navigationController pushViewController:addFundsViewController animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading";
        
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        PFObject *submission = [PFObject objectWithClassName:@"Submissions"];
    
        if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
            submission[@"isVertical"] = [NSNumber numberWithBool:YES];
            PFFile *videoFile = [PFFile fileWithName:@"video.mp4" contentsAtPath:[videoUrl path]];
            submission[@"video"] = videoFile;
        } else if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
            UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
            if (image.size.height > image.size.width) {
                submission[@"isVertical"] = [NSNumber numberWithBool:YES];
            } else {
                submission[@"isVertical"] = [NSNumber numberWithBool:NO];
            }
            image = [self scaleAndRotateImage:image];
            NSData *imgData= UIImageJPEGRepresentation(image,0.8 /*compressionQuality*/);
            image = [UIImage imageWithData:imgData];
            PFFile *imageFile = [PFFile fileWithName:@"image.png" data:UIImagePNGRepresentation(image)];
            submission[@"image"] = imageFile;
        }
        
        submission[@"toWorld"] = [self.uploadObject objectForKey:@"toWorld"];
        submission[@"facebookIds"] = [self.uploadObject objectForKey:@"facebookIds"];
        submission[@"dare"] = self.uploadObject;
        submission[@"user"] = [PFUser currentUser];
        submission[@"isWinner"] = [NSNumber numberWithBool:NO];
        [submission saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(succeeded) {
                [hud hide:YES];
            } else {
                [hud hide:YES];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error Uploading Submission" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
        // Create our push query
        NSMutableDictionary *funders = [self.uploadObject objectForKey:@"funders"];
        NSArray *fundersPush = [funders allKeys];
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"userObject" containedIn:fundersPush];
        // Send push notification to query
        [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"%@ posted a new submission", [[PFUser currentUser] objectForKey:@"name"]]];
        
        PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
        notification[@"text"] = [NSString stringWithFormat:@"%@ posted a new submission", [[PFUser currentUser] objectForKey:@"name"]];
        notification[@"dare"] = self.uploadObject;
        notification[@"type"] = @"New Submission";
        notification[@"followers"] = fundersPush;
        [notification saveInBackground];
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
