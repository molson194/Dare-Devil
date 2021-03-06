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
#import "MOContractViewController.h"

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
    myLoginButton.frame=CGRectMake(10, self.view.frame.size.height/4, self.view.frame.size.width-20, 140);
    [myLoginButton setImage:btnImage forState:UIControlStateNormal];
    [myLoginButton addTarget:self action:@selector(loginButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myLoginButton];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"LoginBackground.jpg"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.backgroundColor=[UIColor colorWithPatternImage:image];
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
                [[PFUser currentUser] setObject:result[@"id"] forKey:@"fbId"];
                [[PFUser currentUser] setObject:result[@"name"] forKey:@"name"];
                [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"isAdmin"];
                [[PFUser currentUser] saveInBackground];
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                [currentInstallation addUniqueObject:[PFUser currentUser].objectId forKey:@"userObject"];
                [currentInstallation addUniqueObject:[[PFUser currentUser] objectForKey:@"fbId"] forKey:@"facebook"];
                [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    MOContractViewController *view = [[MOContractViewController alloc] init];
                    UIViewController *contractView =  [[UINavigationController alloc] initWithRootViewController:view];
                    [self presentViewController:contractView animated:YES completion:nil];
                }];
            }];

        } else if (user) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation addUniqueObject:[PFUser currentUser].objectId forKey:@"userObject"];
            [currentInstallation addUniqueObject:[[PFUser currentUser] objectForKey:@"fbId"] forKey:@"facebook"];
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBar];
            }];
        } else if (error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Facebook Login Error" message:@"Try again" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }}];
}


@end
