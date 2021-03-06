//
//  AppDelegate.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/18/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "AppDelegate.h"
#import "MOLoginViewController.h"
#import "MOMainViewController.h"
#import "MOCompletedDaresViewController.h"
#import "SideViewController.h"
#import "SWRevealViewController.h"
#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "MOActivityViewController.h"
#import <Stripe/Stripe.h>

@interface AppDelegate () <SWRevealViewControllerDelegate>
@property (nonatomic) BOOL notificationRecieved;
@end

@implementation AppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // PARSE SET UP
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"APP_ID" clientKey:@"CLIENT_KEY"];
    
    // FACEBOOK SETUP
    [FBSDKAppEvents activateApp];
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    // STRIPE SETUP
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    [[PFUser currentUser] fetchInBackground];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    // WINDOW SET UP
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //ROOT VIEW CONTROLLER SET UP/LOGIN
    if (![PFUser currentUser]) {
        self.window.rootViewController = [[MOLoginViewController alloc] init];
    } else {
        [self presentTabBar];
    }
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

// FACEBOOK SETUP
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

// TAB BAR SETUP
- (void)presentTabBar{
    UINavigationController *frontViewController;
    if (self.notificationRecieved) {
        frontViewController = [[UINavigationController alloc] initWithRootViewController:[[MOActivityViewController alloc] initWithStyle:UITableViewStylePlain]];
    } else {
        frontViewController = [[UINavigationController alloc] initWithRootViewController:[[MOCompletedDaresViewController alloc] initWithStyle:UITableViewStylePlain]];
    }
    SideViewController *sideViewController = [[SideViewController alloc] init];
    
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc] initWithRearViewController:sideViewController frontViewController:frontViewController];
    mainRevealController.delegate = self;
    
    self.window.rootViewController = mainRevealController;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        // Track app opens due to a push notification being acknowledged while the app wasn't active.
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
        self.notificationRecieved = YES;
    }

    if (application.applicationState != UIApplicationStateActive) {
        UINavigationController *currentDaresViewController = [[UINavigationController alloc] initWithRootViewController:[[MOActivityViewController alloc] initWithStyle:UITableViewStylePlain]];
        SWRevealViewController *vc = (SWRevealViewController *)self.window.rootViewController;
        [vc setFrontViewController: currentDaresViewController];
    } else {
      [PFPush handlePush:userInfo];  
    }
}

@end
