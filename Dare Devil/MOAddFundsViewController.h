//
//  MOAddFundsViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 9/22/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stripe/Stripe.h>

#define STPCardErrorUserMessage NSLocalizedString(@"Your card is invalid", @"Error when the card is not valid")

@interface MOAddFundsViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate,STPPaymentCardTextFieldDelegate>

typedef void (^STPCheckoutTokenBlock)(STPToken* token, NSError* error);

@end
