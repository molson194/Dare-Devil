//
//  MODareFundsViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 1/13/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import "MODareFundsViewController.h"
#import <Parse/Parse.h>

@interface MODareFundsViewController ()
@property(nonatomic) STPPaymentCardTextField *paymentTextField;
@property(nonatomic) BOOL canSave;
@end

@implementation MODareFundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = NO;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton setTintColor:[UIColor whiteColor]];
    
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 95, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    
    if ([[PFUser currentUser] objectForKey:@"CustomerId"]) {
        UIButton* changeCard=[UIButton buttonWithType:UIButtonTypeCustom];
        changeCard.backgroundColor=[UIColor colorWithRed:0.9 green:0.50 blue:0.50 alpha:1.0];
        changeCard.frame=CGRectMake(0,66,[[UIScreen mainScreen] bounds].size.width,30);
        changeCard.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [changeCard setTitle:[NSString stringWithFormat:@"Change card ending in %@?", [[PFUser currentUser] objectForKey:@"Last4"]] forState: UIControlStateNormal];
        [changeCard addTarget:self action:@selector(changeCard:) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-30, 3, 30, 24)];
        UIImage *image = [UIImage imageNamed:@"rightArrow.png"];
        imageHolder.image = image;
        [changeCard addSubview:imageHolder];
        [self.view addSubview:changeCard];
    } else {
        [self.view addSubview:self.paymentTextField];
        [self.view bringSubviewToFront:self.paymentTextField];
    }
}

- (void)changeCard:(UIButton *)sender{
    [sender removeFromSuperview];
    [self.view addSubview:self.paymentTextField];
    [self.view bringSubviewToFront:self.paymentTextField];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.canSave = textField.isValid;
}

-(void) donePressed {
    if (self.canSave) {
        [self createToken:^(STPToken *token, NSError *error) {
            if (error) {
                
            } else {
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
                            [self.navigationController popViewControllerAnimated:YES];
                        
                        //TODO do recipient also
                        }
                    }];
                }
            }
        }];
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

@end
