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
@property(nonatomic) BOOL changingCard;

@end

@implementation MOAddFundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // NAVIGATION BAR SETUP
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:0.88 green:0.40 blue:0.40 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
    SWRevealViewController *revealController = [self revealViewController];
    UIImage* menuImage = [UIImage imageNamed:@"menuicon.png"];
    UIButton *menuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [menuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
    [menuButton addTarget:revealController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
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
    
    
    // CASH OUT BUTTON
    self.cashOut=[UIButton buttonWithType:UIButtonTypeCustom];
    self.cashOut.backgroundColor=[UIColor blueColor];
    self.cashOut.frame=CGRectMake([[UIScreen mainScreen] bounds].size.width/2-60,145,120,40);
    [self.cashOut setTitle: @"Cash Out" forState: UIControlStateNormal];
    [self.cashOut addTarget:self action:@selector(cashOutPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cashOut];
    
    
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 95, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    
    if ([[PFUser currentUser] objectForKey:@"recipient"]){
        UIButton* changeCard=[UIButton buttonWithType:UIButtonTypeCustom];
        changeCard.backgroundColor=[UIColor colorWithRed:0.9 green:0.50 blue:0.50 alpha:1.0];
        changeCard.frame=CGRectMake(0,100,[[UIScreen mainScreen] bounds].size.width,30);
        changeCard.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [changeCard setTitle:@"Change card?" forState: UIControlStateNormal];
        [changeCard addTarget:self action:@selector(changeCard:) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-30, 3, 30, 24)];
        UIImage *image = [UIImage imageNamed:@"rightArrow.png"];
        imageHolder.image = image;
        [changeCard addSubview:imageHolder];
        [self.view addSubview:changeCard];
        self.changingCard = false;
    } else {
        [self.view addSubview:self.paymentTextField];
        [self.view bringSubviewToFront:self.paymentTextField];
        self.changingCard = true;
    }
    
}

- (void)changeCard:(UIButton *)sender{
    [sender removeFromSuperview];
    [self.view addSubview:self.paymentTextField];
    [self.view bringSubviewToFront:self.paymentTextField];
    self.changingCard = true;
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

// CASH OUT BUTTON PRESSED ACTION
- (void)cashOutPressed {
    if ([[PFUser currentUser] objectForKey:@"funds"] > 0){
        if (self.changingCard) {
            [self createToken:^(STPToken *token, NSError *error) {
                if (error) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Card Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    [self cashOut:token];
                }
            }];
        } else {
            NSNumber *amount = [[PFUser currentUser] objectForKey:@"funds"];
            NSDictionary *info = @{ @"id": [[PFUser currentUser] objectForKey:@"recipient"], @"cardId":[[PFUser currentUser] objectForKey:@"card"], @"amount":[NSNumber numberWithInt:amount.intValue*100]};
            
            [PFCloud callFunctionInBackground:@"cashOut" withParameters:info block:^(id object, NSError *error) {
                if (error) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cash Out Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    [[PFUser currentUser] setObject:@(0) forKey:@"funds"];
                    [[PFUser currentUser] saveEventually];
                    self.currentFunds.text = @"Current Funds Remaining: $0";
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }];
        }
    }
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

- (void)cashOut:(STPToken *)token {
    if (token.card.funding != STPCardFundingTypeDebit) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Card Error" message:@"Need to use debit card" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[PFUser currentUser] setObject:token.card.last4 forKey:@"Last4"];
        [[PFUser currentUser] saveInBackground];
        [PFCloud callFunctionInBackground:@"createCustomer" withParameters:@{@"tokenId":token.tokenId,} block:^(id object, NSError *error) {
            if (error) {
                
            } else {
                NSString* customer = (NSString *)object;
                [[PFUser currentUser] setObject:customer forKey:@"CustomerId"];
                [[PFUser currentUser] saveInBackground];
            }
        }];
        
        NSString *firstName = [[[PFUser currentUser] objectForKey:@"name"]componentsSeparatedByString:@" "][0];
        NSString *lastName = [[[PFUser currentUser] objectForKey:@"name"]componentsSeparatedByString:@" "][1];
        NSDictionary *info = @{ @"cardToken": token.tokenId, @"firstName":firstName, @"lastName":lastName};
        [PFCloud callFunctionInBackground:@"recipient" withParameters:info block:^(id object, NSError *error) {
            if (error) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Recipient Creation Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                NSString *stringData = (NSString*) object;
                NSData *data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSLog(@"%@",[json objectForKey:@"id"]);
                NSNumber *amount = [[PFUser currentUser] objectForKey:@"funds"];
                
                NSDictionary *newInfo = @{ @"id": [json objectForKey:@"id"], @"cardId":[json objectForKey:@"default_card"], @"amount":[NSNumber numberWithInt:amount.intValue*100]};
                [[PFUser currentUser] setObject:[json objectForKey:@"id"] forKey:@"recipient"];
                [[PFUser currentUser] setObject:[json objectForKey:@"default_card"] forKey:@"card"];
                [[PFUser currentUser] saveInBackground];
                
                [PFCloud callFunctionInBackground:@"cashOut" withParameters:newInfo block:^(id object, NSError *error) {
                    if (error) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cash Out Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                        [alertController addAction:ok];
                        [self presentViewController:alertController animated:YES completion:nil];
                    } else {
                        [[PFUser currentUser] setObject:@(0) forKey:@"funds"];
                        [[PFUser currentUser] saveEventually];
                        self.currentFunds.text = @"Current Funds Remaining: $0";
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }
                }];
            }
        }];
    }
}

@end
