//
//  MOAddFundsViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 9/22/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOAddFundsViewController.h"
#import "SWRevealViewController.h"
#import <Parse/Parse.h>

@interface MOAddFundsViewController ()

@property(nonatomic, strong) UITextField *moneyField;

@end

@implementation MOAddFundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    SWRevealViewController *revealController = [self revealViewController];
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    UITapGestureRecognizer *tap = [revealController tapGestureRecognizer];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    // FUNDS REMAINING LABEL
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    UILabel *currentFunds = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, [[UIScreen mainScreen] bounds].size.width, 40)];
    currentFunds.text = [NSString stringWithFormat:@"%@ %@", @"Current Funds Remaining:", [currencyFormatter stringFromNumber:[[PFUser currentUser] objectForKey:@"funds"]]];
    currentFunds.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:currentFunds];
    
    // DOLLAR SIGN LABEL
    UILabel *dollarSign = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/2-40, 120, 30, 40)];
    dollarSign.text = @"$";
    dollarSign.font = [dollarSign.font fontWithSize:40];
    [self.view addSubview:dollarSign];
    
    // MONEY TO ADD TEXT FIELD
    self.moneyField = [[UITextField alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/2-12, 120, 130, 40)];
    self.moneyField.font = [UIFont systemFontOfSize:40];
    self.moneyField.placeholder = @"10";
    self.moneyField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.moneyField setKeyboardType:UIKeyboardTypeNumberPad];
    self.moneyField.delegate = self;
    [self.view addSubview:self.moneyField];
    
    // DESCRIPTION LABEL
    UILabel *requirements = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, [[UIScreen mainScreen] bounds].size.width, 40)];
    requirements.text = @"Add funds or cash out. $10 minimum.";
    requirements.textColor = [UIColor lightGrayColor];
    requirements.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:requirements];
    
    // ADD FUNDS BUTTON
    UIButton *addFunds=[UIButton buttonWithType:UIButtonTypeCustom];
    addFunds.backgroundColor=[UIColor blueColor];
    addFunds.frame=CGRectMake(20,220,[[UIScreen mainScreen] bounds].size.width/2-21,40);
    [addFunds setTitle: @"Add Funds" forState: UIControlStateNormal];
    [addFunds addTarget:self action:@selector(addFundsPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addFunds];
    
    // CASH OUT BUTTON
    UIButton *cashOut=[UIButton buttonWithType:UIButtonTypeCustom];
    cashOut.backgroundColor=[UIColor blueColor];
    cashOut.frame=CGRectMake([[UIScreen mainScreen] bounds].size.width/2,220,[[UIScreen mainScreen] bounds].size.width/2-21,40);
    [cashOut setTitle: @"Cash Out" forState: UIControlStateNormal];
    [cashOut addTarget:self action:@selector(cashOutPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cashOut];
    
}

// SET MAXIMUM NUMBER OF CHARACTERS FOR MONEY TEXT FIELD
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 5;
}

// ADD FUNDS BUTTON PRESSED ACTION
- (void)addFundsPressed{
    float funds = [[NSDecimalNumber decimalNumberWithString:self.moneyField.text]floatValue];
    if (funds >= 10) {
        [self addFunds:funds];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid funding level" message:@"Enter at least $10" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
}

// ADD FUNDS
- (void)addFunds:(float)funds {
    // TODO(2): Make credit card processing
    int newTotal = [[[PFUser currentUser] objectForKey:@"funds"] integerValue] + funds;
    [[PFUser currentUser] setObject:@(newTotal) forKey:@"funds"];
    [[PFUser currentUser] saveEventually];
    [self.navigationController popViewControllerAnimated:YES];
}

// CASH OUT BUTTON PRESSED ACTION
- (void)cashOutPressed {
    float cash = [[NSDecimalNumber decimalNumberWithString:self.moneyField.text]floatValue];
    if (cash>=10 && cash<=[[[PFUser currentUser] objectForKey:@"funds"] integerValue]) {
        [self cashOut:cash];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid cash level" message:@"Enter at least $10 and at most your current funds remaining" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
}

// CASH OUT
- (void)cashOut:(float)cash {
    // TODO(2): Make credit card processing
    int newTotal = [[[PFUser currentUser] objectForKey:@"funds"] integerValue] - cash;
    [[PFUser currentUser] setObject:@(newTotal) forKey:@"funds"];
    [[PFUser currentUser] saveEventually];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
