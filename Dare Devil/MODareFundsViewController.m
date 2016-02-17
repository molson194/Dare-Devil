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
@property(nonatomic) BOOL doAdd;
@property(nonatomic) BOOL keepPrevious;
@property (nonatomic, strong) UIButton *amount;
@property (nonatomic,strong) NSString* fundingAmount;
@property (nonatomic,strong) PFObject* currDare;
@end

@implementation MODareFundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    [cancelButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton setTintColor:[UIColor whiteColor]];
    
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 95, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    
    if ([[PFUser currentUser] objectForKey:@"CustomerId"]) {
        UIButton* changeCard=[UIButton buttonWithType:UIButtonTypeCustom];
        changeCard.backgroundColor=[UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
        changeCard.frame=CGRectMake(0,66,[[UIScreen mainScreen] bounds].size.width,30);
        changeCard.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [changeCard setTitle:@"Change card?" forState: UIControlStateNormal];
        [changeCard addTarget:self action:@selector(changeCard:) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-30, 3, 30, 24)];
        UIImage *image = [UIImage imageNamed:@"rightArrow.png"];
        imageHolder.image = image;
        [changeCard addSubview:imageHolder];
        [self.view addSubview:changeCard];
        self.keepPrevious= true;
    } else {
        [self.view addSubview:self.paymentTextField];
        [self.view bringSubviewToFront:self.paymentTextField];
        self.keepPrevious = false;
    }

    if (self.doAdd) {
        self.amount=[UIButton buttonWithType:UIButtonTypeCustom];
        self.amount.backgroundColor=[UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1];
        self.amount.frame=CGRectMake(0,150,[[UIScreen mainScreen] bounds].size.width,30);
        self.amount.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.amount setTitle: @"Add Funds: $0" forState: UIControlStateNormal];
        [self.amount addTarget:self action:@selector(amountPressed) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-25, 3, 30, 24)];
        UIImage *image = [UIImage imageNamed:@"rightArrow.png"];
        imageHolder.image = image;
        [self.amount addSubview:imageHolder];
        [self.view addSubview:self.amount];
    
        self.fundingAmount = @"";
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)insertText:(NSString *)theText {
    self.fundingAmount = [NSString stringWithFormat:@"%@%@",self.fundingAmount,theText];
    [self.amount setTitle: [NSString stringWithFormat:@"Add Fund: $%@",self.fundingAmount] forState: UIControlStateNormal];
}

- (void)deleteBackward {
    self.fundingAmount = [self.fundingAmount substringToIndex:[self.fundingAmount length] - 1];
    [self.amount setTitle: [NSString stringWithFormat:@"Add Funds: $%@",self.fundingAmount] forState: UIControlStateNormal];
}

-(void)dismissKeyboard {
    [self resignFirstResponder];
}

- (void)amountPressed {
    self.fundingAmount = @"";
    [self becomeFirstResponder];
}

- (UIKeyboardType) keyboardType {
    return UIKeyboardTypeNumberPad;
}

- (BOOL)canBecomeFirstResponder { return true; }

- (BOOL)hasText {
    return YES;
}

- (void)addFunds:(BOOL)addFunds forDare:(PFObject *)dare {
    self.doAdd = addFunds;
    self.currDare = dare;
}

// USER PRESSED CANCEL BUTTON
- (void)cancel{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changeCard:(UIButton *)sender{
    [sender removeFromSuperview];
    [self.view addSubview:self.paymentTextField];
    [self.view bringSubviewToFront:self.paymentTextField];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.canSave = textField.isValid;
    self.keepPrevious = false;
}

-(void) donePressed {
    if (self.keepPrevious && self.doAdd) {
        [PFCloud callFunctionInBackground:@"chargeCustomer" withParameters:@{@"customerId":[[PFUser currentUser] objectForKey:@"CustomerId"], @"amount":[NSNumber numberWithInt:self.fundingAmount.intValue*100], } block:^(id object, NSError *error) {
            if (error) {
                
            } else {
                NSMutableDictionary* funders =  [self.currDare objectForKey:@"funders"];
                NSNumber *totalFunding = [self.currDare objectForKey:@"totalFunding"];
                
                totalFunding = [NSNumber numberWithInt:(self.fundingAmount.intValue + totalFunding.intValue)];
                [self.currDare setObject:totalFunding forKey:@"totalFunding"];
                
                if ([funders objectForKey:[PFUser currentUser].objectId]) {
                    NSNumber* myFunds = [funders objectForKey:[PFUser currentUser].objectId];
                    [funders setObject:[NSNumber numberWithInt:(self.fundingAmount.intValue + myFunds.intValue)] forKey:[PFUser currentUser].objectId];
                } else {
                    [funders setObject:[NSNumber numberWithInt:self.fundingAmount.intValue] forKey:[PFUser currentUser].objectId];
                }
                [self.currDare setObject:funders forKey:@"funders"];
                [self.currDare saveInBackground];
                [self.navigationController popViewControllerAnimated:YES];
                
            }
        }];
    } else if (self.keepPrevious) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.canSave) {
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
                            
                            if (self.doAdd) {
                                [PFCloud callFunctionInBackground:@"chargeCustomer" withParameters:@{@"customerId":customer, @"amount":[NSNumber numberWithInt:self.fundingAmount.intValue*100], } block:^(id object, NSError *error) {
                                    if (error) {
                                        
                                    } else {
                                        NSMutableDictionary* funders =  [self.currDare objectForKey:@"funders"];
                                        NSNumber *totalFunding = [self.currDare objectForKey:@"totalFunding"];
                                        
                                        totalFunding = [NSNumber numberWithInt:(self.fundingAmount.intValue + totalFunding.intValue)];
                                        [self.currDare setObject:totalFunding forKey:@"totalFunding"];
                                        
                                        if ([funders objectForKey:[PFUser currentUser].objectId]) {
                                            NSNumber* myFunds = [funders objectForKey:[PFUser currentUser].objectId];
                                            [funders setObject:[NSNumber numberWithInt:(self.fundingAmount.intValue + myFunds.intValue)] forKey:[PFUser currentUser].objectId];
                                        } else {
                                            [funders setObject:[NSNumber numberWithInt:self.fundingAmount.intValue] forKey:[PFUser currentUser].objectId];
                                        }
                                        [self.currDare setObject:funders forKey:@"funders"];
                                        [self.currDare saveInBackground];
                                        
                                    }
                                }];
                            }
                        }
                    }];
                    
                    NSString *firstName = [[[PFUser currentUser] objectForKey:@"name"]componentsSeparatedByString:@" "][0];
                    NSString *lastName = [[[PFUser currentUser] objectForKey:@"name"]componentsSeparatedByString:@" "][1];
                    NSDictionary *info = @{ @"cardToken": token.tokenId, @"firstName":firstName, @"lastName":lastName};
                    [PFCloud callFunctionInBackground:@"recipient" withParameters:info block:^(id object, NSError *error) {
                        NSString *stringData = (NSString*) object;
                        NSData *data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
                        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        NSLog(@"%@",[json objectForKey:@"id"]);

                        [[PFUser currentUser] setObject:[json objectForKey:@"id"] forKey:@"recipient"];
                        [[PFUser currentUser] setObject:[json objectForKey:@"default_card"] forKey:@"card"];
                        [[PFUser currentUser] saveInBackground];
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
