//
//  MODareFundsViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 1/13/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stripe/Stripe.h>
#import <Parse/Parse.h>

#define STPCardErrorUserMessage NSLocalizedString(@"Your card is invalid", @"Error when the card is not valid")

@interface MODareFundsViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate,STPPaymentCardTextFieldDelegate, UIKeyInput>

typedef void (^STPCheckoutTokenBlock)(STPToken* token, NSError* error);

- (void)addFunds:(BOOL)addFunds forDare:(PFObject *)dare;

@end
