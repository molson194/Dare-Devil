//
//  MOLoginViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/19/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOLoginViewController.h"
#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <Parse/Parse.h>

@interface MOLoginViewController ()

@end

@implementation MOLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationItem.hidesBackButton = YES;
    
    // FACEBOOK BUTTON SETUP
    UIImage *btnImage = [UIImage imageNamed:@"facebook.png"];
    UIButton *myLoginButton=[UIButton buttonWithType:UIButtonTypeCustom];
    myLoginButton.frame=CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height/3, 200, 40);
    [myLoginButton setImage:btnImage forState:UIControlStateNormal];
    [myLoginButton addTarget:self action:@selector(loginButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myLoginButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

// LOGIN USER WITH FACEBOOK
- (void)loginButtonClicked {
    NSArray *permissionsArray = @[ @"public_profile",@"user_friends"];
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (user.isNew) {
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name"}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",result[@"id"]]];
                NSData  *data = [NSData dataWithContentsOfURL:url];
                UIImage *image = [UIImage imageWithData:data];
                PFFile *profilePic = [PFFile fileWithName:@"profilePic.png" data:UIImagePNGRepresentation(image)];
                [[PFUser currentUser] setObject:profilePic forKey:@"profilePic"];
                [[PFUser currentUser] setObject:@0 forKey:@"funds"];
                [[PFUser currentUser] setObject:result[@"id"] forKey:@"fbId"];
                [[PFUser currentUser] setObject:result[@"name"] forKey:@"name"];
                [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"isAdmin"];
                [[PFUser currentUser] saveInBackground];
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                [currentInstallation addUniqueObject:[PFUser currentUser].objectId forKey:@"userObject"];
                [currentInstallation addUniqueObject:[[PFUser currentUser] objectForKey:@"fbId"] forKey:@"facebook"];
                [currentInstallation saveInBackground];
                [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBar];
            }];

        }
        if (user) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation addUniqueObject:[PFUser currentUser].objectId forKey:@"userObject"];
            [currentInstallation addUniqueObject:[[PFUser currentUser] objectForKey:@"fbId"] forKey:@"facebook"];
            [currentInstallation saveInBackground];
            [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBar];
        } else if (error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Facebook Login Error" message:@"Try again" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }}];
}


@end
