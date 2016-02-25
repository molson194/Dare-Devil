//
//  MOPostViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/20/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOPostViewController.h"
#import <Parse/Parse.h>
#import "MODareRecipientViewController.h"
#import "MODareTargetViewController.h"

@interface MOPostViewController ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *dareTarget;
@property (nonatomic, strong) UIButton *donateButtonUnselected;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) PFGeoPoint *geoPoint;
@property (nonatomic, strong) UIButton *toButton;
@property (nonatomic, strong) NSMutableArray *facebookTags;
@property (nonatomic, strong) NSMutableArray *facebookIds;
@property (nonatomic) BOOL world;
@property (nonatomic,strong) NSArray* targetPerson;
@property (nonatomic, strong) UIButton *target;
@property (nonatomic, strong) UIButton *daysOpen;
@property (nonatomic, strong) UILabel *numDays;
@property (nonatomic) BOOL displayText;
@property (nonatomic, strong) UIButton *amount;
@property (nonatomic,strong) NSString* daysOpenAmount;
@end

@implementation MOPostViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // NAVIGATION BAR SETUP
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    
    // CANCEL BUTTON IN NAV BAR
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost)];
    [cancelButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(postToCloud)];
    [postButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.rightBarButtonItem = postButton;
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Add a Dare";
    
    self.target=[UIButton buttonWithType:UIButtonTypeCustom];
    self.target.backgroundColor=[UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
    self.target.frame=CGRectMake(0,93,[[UIScreen mainScreen] bounds].size.width,25);
    self.target.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.target setTitle: @"Target:" forState: UIControlStateNormal];
    [self.target addTarget:self action:@selector(recipientPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-25, 3, 30, 20)];
    UIImage *image = [UIImage imageNamed:@"rightArrow.png"];
    imageHolder.image = image;
    [self.target addSubview:imageHolder];
    [self.view addSubview:self.target];
    
    self.daysOpen=[UIButton buttonWithType:UIButtonTypeCustom];
    self.daysOpen.backgroundColor=[UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
    self.daysOpen.frame=CGRectMake(0,120,[[UIScreen mainScreen] bounds].size.width,25);
    self.daysOpen.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.daysOpen setTitle: @"Open: 0 days" forState: UIControlStateNormal];
    [self.daysOpen addTarget:self action:@selector(daysPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *imageHolder3 = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-25, 3, 30, 20)];
    imageHolder3.image = image;
    [self.daysOpen addSubview:imageHolder3];
    [self.view addSubview:self.daysOpen];
    
    // DARE TEXT VIEW
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(3, 146, [[UIScreen mainScreen] bounds].size.width-6, 60)];
    [self.textView setFont:[UIFont systemFontOfSize:16]];
    [self.textView setReturnKeyType:UIReturnKeySend];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.textView.delegate = self;
    self.textView.text = @"I dare the target to...";
    self.textView.textColor = [UIColor lightGrayColor];
    [self.view addSubview:self.textView];
    
    // BORDERS
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, 1)];
    bottomBorder.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomBorder];
    
    // TO BUTTON
    self.toButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.toButton.backgroundColor=[UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
    self.toButton.frame=CGRectMake(0,66,[[UIScreen mainScreen] bounds].size.width,25);
    self.toButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.toButton setTitle: @"Tag:" forState: UIControlStateNormal];
    [self.toButton addTarget:self action:@selector(toButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *imageHolder2 = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-25, 3, 30, 20)];
    imageHolder2.image = image;
    [self.toButton addSubview:imageHolder2];
    [self.view addSubview:self.toButton];
    
    // LOCATION SERVICES
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            self.geoPoint = geoPoint;
        }
    }];
    
    self.world = NO;
    self.displayText = NO;
    self.facebookIds = [NSMutableArray array];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self resignFirstResponder];
}

- (void)daysPressed {
    self.displayText = YES;
    self.daysOpenAmount = @"";
    [self becomeFirstResponder];
}

- (UIKeyboardType) keyboardType {
    return UIKeyboardTypeNumberPad;
}

- (BOOL)canBecomeFirstResponder { return self.displayText; }

- (BOOL)hasText {
    return YES;
}

- (void)insertText:(NSString *)theText {

    self.daysOpenAmount = [NSString stringWithFormat:@"%@%@",self.daysOpenAmount,theText];
    [self.daysOpen setTitle: [NSString stringWithFormat:@"Open: %@ days",self.daysOpenAmount] forState: UIControlStateNormal];
}

- (void)deleteBackward {
    self.daysOpenAmount = [self.daysOpenAmount substringToIndex:[self.daysOpenAmount length] - 1];
    [self.daysOpen setTitle: [NSString stringWithFormat:@"Open: %@ days",self.daysOpenAmount] forState: UIControlStateNormal];
}

- (void) recipientPressed {
    MODareTargetViewController *targetVC = [[MODareTargetViewController alloc] init];
    targetVC.delegate = self;
    UIViewController *targetNav =  [[UINavigationController alloc] initWithRootViewController:targetVC];
    [self presentViewController:targetNav animated:YES completion:nil];
}

// USER PRESSED CANCEL BUTTON
- (void)cancelPost {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"I dare the target to..."]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"I dare the target to...";
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

- (void)toButtonPressed {
    MODareRecipientViewController *recipientView = [[MODareRecipientViewController alloc] init];
    recipientView.delegate = self;
    [recipientView reopenWithFacebook:self.facebookTags];
    UIViewController *recipientNav =  [[UINavigationController alloc] initWithRootViewController:recipientView];
    [self presentViewController:recipientNav animated:YES completion:nil];
}

- (void)sendPerson:(NSArray *)person {
    self.targetPerson = person;
    [self.target setTitle:[NSString stringWithFormat:@"Target: %@", person[0]] forState:UIControlStateNormal];
}

-(void)sendWorld:(BOOL)worldPost {
    [self.toButton setTitle:@"Tag: World" forState: UIControlStateNormal];
    self.world = worldPost;
    self.facebookTags = [NSMutableArray array];
}

-(void)sendFacebook:(NSMutableArray *)facebookPost {
    [self.toButton setTitle:@"Tag: Current Facebook Friends" forState: UIControlStateNormal];
    self.world = NO;
    for (NSArray *array in facebookPost) {
        [self.facebookIds addObject:array[1]];
    }
}

-(void)sendIndividuals:(NSMutableArray *)individuals {
    self.facebookTags = individuals;
    self.world = NO;
    for (NSArray *array in individuals) {
        [self.facebookIds addObject:array[1]];
    }
    NSString *buttonString;
    if ([individuals count]>1) {
        buttonString = [NSString stringWithFormat:@"Tag: %@ and %li others", individuals[0][0], [individuals count]-1];
    } else if ([individuals count] == 1){
        buttonString = [NSString stringWithFormat:@"Tag: %@", individuals[0][0]];
    } else {
        buttonString = @"Tag:";
    }

    [self.toButton setTitle:buttonString forState: UIControlStateNormal];
}

// USER ABLE TO POST, POST TO CLOUD
- (void)postToCloud {
    if (self.daysOpenAmount == nil || self.daysOpenAmount.intValue == 0 || [self.textView.text isEqualToString:@"I dare the target to..."] || [self.textView.text isEqualToString:@""] ||(self.world == NO && [self.facebookIds count] == 0) || self.targetPerson == nil){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Fill in all input fields" message:@"Make sure days open inputted, dare text filled in, tags included, and target added." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        PFObject *dare = [PFObject objectWithClassName:@"Dare"];
        dare[@"text"] = [NSString stringWithFormat:@"I dare %@ to %@", self.targetPerson[0],self.textView.text];
        dare[@"user"] = [PFUser currentUser];
        if (self.geoPoint) {
            dare[@"location"] = self.geoPoint;
        } else {
            dare[@"location"] = [PFGeoPoint geoPointWithLatitude:0 longitude:0];
        }
        dare[@"closeDate"] = [[NSDate date] dateByAddingTimeInterval:60*60*24*self.daysOpenAmount.intValue];
        dare[@"facebookIds"] = self.facebookIds;
        dare[@"target"] = self.targetPerson[1];
        dare[@"toWorld"] = [NSNumber numberWithBool:self.world];
        dare[@"isFinished"] = [NSNumber numberWithBool:NO];
        [dare saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                PFQuery *pushQuery = [PFInstallation query];
                NSMutableArray *arr = [NSMutableArray arrayWithArray:self.facebookIds];
                [arr addObject:self.targetPerson[1]];
                [pushQuery whereKey:@"facebook" containedIn:arr];
                // Send push notification to query
                [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"%@ tagged you in a new dare", [[PFUser currentUser] objectForKey:@"name"]]];
                
                PFObject *notification = [PFObject objectWithClassName:@"Notifications"];
                notification[@"text"] = [NSString stringWithFormat:@"%@ tagged you in a new dare", [[PFUser currentUser] objectForKey:@"name"]];
                notification[@"dare"] = dare;
                notification[@"type"] = @"New Dare";
                notification[@"facebook"] = arr;
                notification[@"maker"] = [PFUser currentUser];
                [notification saveInBackground];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

@end
