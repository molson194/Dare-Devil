//
//  MOPostViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/20/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOPostViewController.h"
#import "MOAddFundsViewController.h"
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
@property (nonatomic, strong) NSMutableArray *contactTags;
@property (nonatomic, strong) NSMutableArray *facebookIds;
@property (nonatomic, strong) NSMutableArray *contactPhones;
@property (nonatomic) BOOL world;
@property (nonatomic, strong) NSString *targetId;
@end

@implementation MOPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // CANCEL BUTTON IN NAV BAR
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(postDare)];
    self.navigationItem.rightBarButtonItem = postButton;
    
    UITextField *iDare = [[UITextField alloc] initWithFrame:CGRectMake(3, 100, 50, 25)];
    iDare.text = @"I dare";
    iDare.textColor = [UIColor blackColor];
    [self.view addSubview:iDare];
    
    self.dareTarget = [UIButton buttonWithType:UIButtonTypeCustom];
    self.dareTarget.backgroundColor = [UIColor lightGrayColor];
    self.dareTarget.frame = CGRectMake(53, 100, self.view.bounds.size.width-90, 25);
    [self.dareTarget addTarget:self action:@selector(dareTargetPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.dareTarget setTitle:@"Someone" forState:UIControlStateNormal];
    [self.view addSubview:self.dareTarget];
    
    UITextField *to = [[UITextField alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-35, 100, 35, 25)];
    to.text = @"to...";
    to.textColor = [UIColor blackColor];
    [self.view addSubview:to];
    
    // DARE TEXT VIEW
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(3, 130, [[UIScreen mainScreen] bounds].size.width-6, [[UIScreen mainScreen] bounds].size.height - 390)];
    [self.textView setFont:[UIFont systemFontOfSize:16]];
    [self.textView setReturnKeyType:UIReturnKeySend];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.textView.delegate = self;
    self.textView.text = @"Write dare here!";
    self.textView.textColor = [UIColor lightGrayColor];
    [self.view addSubview:self.textView];
    
    // TO BUTTON
    self.toButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.toButton.backgroundColor=[UIColor lightGrayColor];
    self.toButton.frame=CGRectMake(0,65,[[UIScreen mainScreen] bounds].size.width,30);
    self.toButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.toButton setTitle: @"To:" forState: UIControlStateNormal];
    [self.toButton addTarget:self action:@selector(toButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toButton];
    
    // LOCATION SERVICES
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            self.geoPoint = geoPoint;
        }
    }];
    
    self.targetId = [NSString string];
    self.facebookIds = [NSMutableArray array];
    self.contactPhones = [NSMutableArray array];
}
- (void)postDare {
    [self attemptToPost];
}

- (void)dareTargetPressed {
    MODareTargetViewController *targetView = [[MODareTargetViewController alloc] init];
    targetView.delegate = self;
    UIViewController *targetNav =  [[UINavigationController alloc] initWithRootViewController:targetView];
    [self presentViewController:targetNav animated:YES completion:nil];
}

// USER PRESSED CANCEL BUTTON
- (void)cancelPost {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Write dare here!"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Write dare here!";
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

- (void)toButtonPressed {
    MODareRecipientViewController *recipientView = [[MODareRecipientViewController alloc] init];
    recipientView.delegate = self;
    [recipientView reopenWithFacebook:self.facebookTags contacts:self.contactTags world:self.world];
    UIViewController *recipientNav =  [[UINavigationController alloc] initWithRootViewController:recipientView];
    [self presentViewController:recipientNav animated:YES completion:nil];
}

-(void)sendDataToPostView:(NSArray *)contact {
    if ([contact count] == 0) {
        [self.dareTarget setTitle:@"Someone" forState:UIControlStateNormal];
    } else {
        [self.dareTarget setTitle:contact[0] forState:UIControlStateNormal];
        if ([contact[1] length]<=14){
            NSString *phone = contact[1];
            phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableString *result = [NSMutableString string];
            NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];
            NSScanner *scanner = [NSScanner scannerWithString:phone];
            while ([scanner isAtEnd] == NO){
                NSString *buffer;
                if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
                    [result appendString:buffer];
                } else {
                    [scanner setScanLocation:([scanner scanLocation] + 1)];
                }
            }
            NSString *firstLetter = [phone substringToIndex:1];
            if ([firstLetter isEqualToString:@"+"]) {
                self.targetId = result;
            } else {
                self.targetId = [NSString stringWithFormat:@"+1%@",result];
            }
        } else {
            self.targetId = contact[1];
        }
    }
}

-(void)sendDataToPostViewfacebook:(NSMutableArray *)facebookTags contacts:(NSMutableArray *)contactTags world:(BOOL)worldPost {
    NSMutableArray *allContacts = [NSMutableArray arrayWithArray:facebookTags];
    [allContacts addObjectsFromArray:contactTags];
    self.facebookTags = facebookTags;
    self.contactTags = contactTags;
    self.world = worldPost;
    
    for (NSArray *array in facebookTags) {
        [self.facebookIds addObject:array[1]];
    }
    for (NSArray *array in contactTags) {
        NSString *phone = array[1];
        phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableString *result = [NSMutableString string];
        NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];
        NSScanner *scanner = [NSScanner scannerWithString:phone];
        while ([scanner isAtEnd] == NO){
            NSString *buffer;
            if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
                [result appendString:buffer];
            } else {
                [scanner setScanLocation:([scanner scanLocation] + 1)];
            }
        }
    
        NSString *firstLetter = [phone substringToIndex:1];
        if ([firstLetter isEqualToString:@"+"]) {
            [self.contactPhones addObject:result];
        } else {
            [self.contactPhones addObject:[NSString stringWithFormat:@"+1%@",result]];
        }
    }
    
    NSString *buttonString;
    if (worldPost == YES){
        if ([allContacts count]>1) {
            buttonString = [NSString stringWithFormat:@"To: World, %@, and %li others", allContacts[0][0], [allContacts count]-1];
        } else if ([allContacts count] == 1){
            buttonString = [NSString stringWithFormat:@"To: World and %@", allContacts[0][0]];
        } else {
            buttonString = @"To: World";
        }
    } else {
        if ([allContacts count]>1) {
            buttonString = [NSString stringWithFormat:@"To: %@ and %li others", allContacts[0][0], [allContacts count]-1];
        } else if ([allContacts count] == 1){
            buttonString = [NSString stringWithFormat:@"To: %@", allContacts[0][0]];
        } else {
            buttonString = @"To:";
        }
    }
    [self.toButton setTitle:buttonString forState: UIControlStateNormal];
}

// USER PRESSED POST, FIND IF ABLE TO POST
- (void)attemptToPost {
    
    if (self.textView.text.length <=1 || self.textView.text.length>201) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid number of characters" message:@"Edit post to have valid number of characters" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    if ([[[PFUser currentUser] objectForKey:@"funds"] integerValue] >= 1){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Are you okay with funding $1?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesSelect = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self postToCloud];}];
        UIAlertAction *noSelect = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:yesSelect];
        [alertController addAction:noSelect];
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Not enough funds" message:@"Add funds or cancel" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *addFunds = [UIAlertAction actionWithTitle:@"Add Funds" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self addFunds];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){return;}];
        [alertController addAction:addFunds];
        [alertController addAction:cancel];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

// USER ABLE TO POST, POST TO CLOUD
- (void)postToCloud {
    
    PFObject *dare = [PFObject objectWithClassName:@"Dare"];
    dare[@"text"] = self.textView.text;
    dare[@"user"] = [PFUser currentUser];
    if (self.geoPoint) {
        dare[@"location"] = self.geoPoint;
    } else {
        dare[@"location"] = [PFGeoPoint geoPointWithLatitude:0 longitude:0];
    }
    
    dare[@"funders"] = [NSMutableArray arrayWithObject:[PFUser currentUser].objectId];
    dare[@"submissions"] = [NSMutableArray array];
    dare[@"phonenubmers"] = self.contactPhones;
    dare[@"facebookIds"] = self.facebookIds;
    dare[@"toWorld"] = [NSNumber numberWithBool:self.world];
    dare[@"target"] = self.targetId;
    [dare saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            int fundsRemaining = (int) [[[PFUser currentUser] objectForKey:@"funds"] integerValue] - 1;
            [[PFUser currentUser] setObject:@(fundsRemaining) forKey:@"funds"];
            [[PFUser currentUser] saveEventually];
            
            for (NSString *phoneNumber in self.contactPhones) {
                [PFCloud callFunctionInBackground:@"sendSmsPlivo" withParameters:@{ @"phonenumber" : phoneNumber, @"messagebody" : [NSString stringWithFormat:@"%@ tagged you in a dare. Download Dare Devil and add '%@' to the side menu", [[PFUser currentUser] objectForKey:@"name"], phoneNumber]}];
            }
            // TODO(0) Push notifiaction to all people in self.facebookIds
            if ([[self.targetId substringToIndex:1] isEqualToString:@"+"]) {
                [PFCloud callFunctionInBackground:@"sendSmsPlivo" withParameters:@{ @"phonenumber" : self.targetId, @"messagebody" : [NSString stringWithFormat:@"%@ tagged you in a dare. Download Dare Devil and add '%@' to the side menu", [[PFUser currentUser] objectForKey:@"name"], self.targetId]}];
            } else {
                // TODO(0): Notification targeted in dare - to single user
            }
            // TODO(3): Reload the root view controller
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error uploading dare." message:error.description preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
    }];
}

- (void) addFunds {
    MOAddFundsViewController *addFundsViewController = [[MOAddFundsViewController alloc] init];
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController pushViewController:addFundsViewController animated:YES];
}
@end
