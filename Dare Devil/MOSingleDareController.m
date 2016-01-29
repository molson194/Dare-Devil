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
}

- (void)setObject:(PFObject *)object {
    self.obj = object;
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
    UITextView* dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, 7*self.view.bounds.size.width/8, 70)];
    dareLabel.textColor = [UIColor blackColor];
    [dareLabel setFont:[UIFont systemFontOfSize:15]];
    dareLabel.scrollEnabled = false;
    dareLabel.editable = false;
    dareLabel.text = [self.obj objectForKey:@"text"];
    [cell.contentView addSubview:dareLabel];
    
    // FUNDS BUTTON
    UILabel *fundsLabel = [[UILabel alloc] initWithFrame:CGRectMake(7*self.view.bounds.size.width/8, 40, self.view.bounds.size.width/8, 12)];
    fundsLabel.textColor = [UIColor blackColor];
    fundsLabel.text = [[self.obj objectForKey:@"totalFunding"] stringValue];
    [cell.contentView addSubview:fundsLabel];
    
    // TIME LEFT LABEL
    UILabel* timeLeft = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-35, 5, 30, 12)];
    timeLeft.textColor = [UIColor lightGrayColor];
    [timeLeft setTextAlignment:NSTextAlignmentCenter];
    timeLeft.font = [UIFont systemFontOfSize:13];
    NSDate *endDate = [[self.obj createdAt] dateByAddingTimeInterval:60*60*24*1];
    NSInteger diff = [endDate timeIntervalSinceDate:[NSDate date]]/60;
    if (diff>60) {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldh", (long) diff/60];
    } else {
        timeLeft.text = [NSMutableString stringWithFormat:@"%ldm", (long) diff];
    }
    [cell.contentView addSubview:timeLeft];
    
    return cell;
}

// FUND DARE
- (void)fundDare:(UIButton *)sender{
    if (!sender.selected && (int)[[PFUser currentUser] objectForKey:@"funds"] >= 1) {
        NSMutableArray *funders = [self.obj objectForKey:@"funders"];
        [funders addObject:[PFUser currentUser].objectId];
        [self.obj saveInBackground];
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
        [self presentViewController:imagePicker animated:YES completion:nil];
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
        submission[@"isWinner"] = [NSNumber numberWithBool:NO];
        [submission saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(succeeded) {
                [hud hide:YES];
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
        NSMutableArray *fundersPush = [self.obj objectForKey:@"funders"];
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"userObject" containedIn:fundersPush];
        // Send push notification to query
        [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"%@ posted a new submission to the follwoing dare: %@", [[PFUser currentUser] objectForKey:@"name"], [self.obj objectForKey:@"text"]]];
        
        PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
        notification[@"text"] = [NSString stringWithFormat:@"%@ posted a new submission to the follwoing dare: %@", [[PFUser currentUser] objectForKey:@"name"], [self.obj objectForKey:@"text"]];
        notification[@"dare"] = self.obj;
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
