//
//  MOSingleDareController.m
//  Dare Devil
//
//  Created by Matthew Olson on 12/22/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOSingleDareController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

@implementation MOSingleDareController

-(void)viewDidLoad {
    self.tableView.delegate = self;
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Dare";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)setObject:(PFObject *)object {
    self.obj = object;
    [self.obj fetchInBackground];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // DARE TEXT
    UITextView* dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(2, 0, 7*self.view.bounds.size.width/8, 70)];
    dareLabel.textColor = [UIColor blackColor];
    [dareLabel setFont:[UIFont systemFontOfSize:15]];
    dareLabel.scrollEnabled = false;
    dareLabel.editable = false;
    [dareLabel setUserInteractionEnabled:NO];
    dareLabel.text = [self.obj objectForKey:@"text"];
    [cell.contentView addSubview:dareLabel];
    
    // TIME LEFT LABEL
    UILabel* timeLeft = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-35, 5, 30, 12)];
    timeLeft.textColor = [UIColor lightGrayColor];
    [timeLeft setTextAlignment:NSTextAlignmentCenter];
    timeLeft.font = [UIFont systemFontOfSize:13];
    NSDate *endDate = [self.obj objectForKey:@"closeDate"];
    NSInteger diff = [endDate timeIntervalSinceDate:[NSDate date]]/60;
    if (diff>1440){
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldd", (long) diff/1440];
    } else if (diff>60) {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldh", (long) diff/60];
    } else {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldm", (long) diff];
    }
    [cell.contentView addSubview:timeLeft];
    if ([[self.obj objectForKey:@"target"] isEqualToString:[[PFUser currentUser] objectForKey:@"fbId"]]) {
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-30, 40, 30, 30)];
        UIImage *image = [UIImage imageNamed:@"RedRight.png"];
        imageHolder.image = image;
        [cell.contentView addSubview:imageHolder];
    }
    
    return cell;
}

- (void)uploadSubmission{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    imagePicker.mediaTypes = [[NSMutableArray alloc] initWithObjects:(NSString *)kUTTypeMovie, kUTTypeImage, nil];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self.obj objectForKey:@"target"] isEqualToString:[[PFUser currentUser] objectForKey:@"fbId"]]) {
        [self uploadSubmission];
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
        
        submission[@"dare"] = self.obj;
        submission[@"user"] = [PFUser currentUser];
        [submission saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(succeeded) {
                [hud hide:YES];
                [self.obj setObject:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                [self.obj saveInBackground];
                [self.tableView reloadData];
            } else {
                [hud hide:YES];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error Uploading Submission" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
        
        // Create our push query
        NSArray *facebookPush = [self.obj objectForKey:@"facebookIds"];
        PFQuery *facebook = [PFInstallation query];
        [facebook whereKey:@"facebook" containedIn:facebookPush];
        [PFPush sendPushMessageToQueryInBackground:facebook withMessage:[NSString stringWithFormat:@"%@ posted a new submission", [[PFUser currentUser] objectForKey:@"name"]]];
        
        PFUser *makerPush = [self.obj objectForKey:@"user"];
        PFQuery *maker = [PFInstallation query];
        [maker whereKey:@"userObject" equalTo:makerPush.objectId];
        [PFPush sendPushMessageToQueryInBackground:maker withMessage:[NSString stringWithFormat:@"%@ posted a new submission", [[PFUser currentUser] objectForKey:@"name"]]];
        
        PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
        notification[@"text"] = [NSString stringWithFormat:@"%@ posted a new submission", [[PFUser currentUser] objectForKey:@"name"]];
        notification[@"dare"] = self.obj;
        notification[@"type"] = @"New Submission";
        notification[@"followers"] = facebookPush;
        notification[@"maker"] = makerPush;
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
