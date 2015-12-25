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

@property(nonatomic, strong) UILabel *currentFunds;
@property(nonatomic, strong) NSNumberFormatter *currencyFormatter;
@property(nonatomic) STPPaymentCardTextField *paymentTextField;
@property(nonatomic, strong) UIButton *addFunds;
@property(nonatomic, strong) UIButton *cashOut;

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
    self.currencyFormatter = [[NSNumberFormatter alloc] init];
    [self.currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    self.currentFunds = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, [[UIScreen mainScreen] bounds].size.width, 40)];
    self.currentFunds.text = [NSString stringWithFormat:@"%@ %@", @"Current Funds Remaining:", [self.currencyFormatter stringFromNumber:[[PFUser currentUser] objectForKey:@"funds"]]];
    self.currentFunds.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.currentFunds];
    
    
    // ADD FUNDS BUTTON
    self.addFunds=[UIButton buttonWithType:UIButtonTypeCustom];
    self.addFunds.backgroundColor=[UIColor lightGrayColor];
    self.addFunds.frame=CGRectMake(20,145,[[UIScreen mainScreen] bounds].size.width/2-21,40);
    [self.addFunds setTitle: @"Add $10" forState: UIControlStateNormal];
    [self.addFunds addTarget:self action:@selector(addFundsPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addFunds];
    
    // CASH OUT BUTTON
    self.cashOut=[UIButton buttonWithType:UIButtonTypeCustom];
    self.cashOut.backgroundColor=[UIColor lightGrayColor];
    self.cashOut.frame=CGRectMake([[UIScreen mainScreen] bounds].size.width/2,145,[[UIScreen mainScreen] bounds].size.width/2-21,40);
    [self.cashOut setTitle: @"Cash Out $10" forState: UIControlStateNormal];
    [self.cashOut addTarget:self action:@selector(cashOutPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cashOut];
    
    //TODO
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 95, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    [self.view addSubview:self.paymentTextField];
    [self.view bringSubviewToFront:self.paymentTextField];
    
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
    if (self.addFunds.backgroundColor != [UIColor lightGrayColor]) {
        [self createToken:^(STPToken *token, NSError *error) {
            if (error) {
                //TODO
            } else {
                [self charge:token];
            }
    }];
    }
    
}

// CASH OUT BUTTON PRESSED ACTION
- (void)cashOutPressed {
    //TODO and greater than 10 current funds
    if (self.cashOut.backgroundColor != [UIColor lightGrayColor]) {
        long newTotal = [[[PFUser currentUser] objectForKey:@"funds"] integerValue] - 10;
        [[PFUser currentUser] setObject:@((int) newTotal) forKey:@"funds"];
        [[PFUser currentUser] saveEventually];
        self.currentFunds.text = [NSString stringWithFormat:@"%@ %@", @"Current Funds Remaining:", [self.currencyFormatter stringFromNumber:[[PFUser currentUser] objectForKey:@"funds"]]];
    }
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    // Toggle navigation, for example
    if(textField.isValid) {
        self.addFunds.backgroundColor = [UIColor blueColor];
        self.cashOut.backgroundColor = [UIColor blueColor];
    }
}

- (void)charge:(STPToken *)token {
    
    NSDictionary *info = @{ @"cardToken": token.tokenId, };
    [PFCloud callFunctionInBackground:@"addFunds" withParameters:info block:^(id object, NSError *error) {
                                    if (error) {
                                        //TODO(2): Error
                                    } else {
                                        long newTotal = [[[PFUser currentUser] objectForKey:@"funds"] integerValue] + 10;
                                        [[PFUser currentUser] setObject:@((int)newTotal) forKey:@"funds"];
                                        [[PFUser currentUser] saveEventually];
                                        self.currentFunds.text = [NSString stringWithFormat:@"%@ %@", @"Current Funds Remaining:", [self.currencyFormatter stringFromNumber:[[PFUser currentUser] objectForKey:@"funds"]]];
                                    }
                                }];
}

- (void)createToken:(STPCheckoutTokenBlock)block
{
    
    if ( ![self.paymentTextField isValid] ) {
        NSError* error = [[NSError alloc] initWithDomain:StripeDomain
                                                    code:STPCardError
                                                userInfo:@{NSLocalizedDescriptionKey: STPCardErrorUserMessage}];
        
        block(nil, error);
        return;
    }
    
    
    STPCardParams* card = self.paymentTextField.card;
    STPCardParams* scard = [[STPCard alloc] init];
    
    scard.number = card.number;
    scard.expMonth = card.expMonth;
    scard.expYear = card.expYear;
    scard.cvc = card.cvc;
    
    [[STPAPIClient sharedClient] createTokenWithCard:scard
                                          completion:^(STPToken *token, NSError *error) {
                                              block(token, error);
                                          }];
    
}

@end
