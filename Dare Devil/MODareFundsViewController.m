//
//  MODareFundsViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 1/13/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import "MODareFundsViewController.h"

@interface MODareFundsViewController ()
@property(nonatomic) STPPaymentCardTextField *paymentTextField;
@end

@implementation MODareFundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = NO;
    [self.view setBackgroundColor:[UIColor whiteColor]];

    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 95, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    [self.view addSubview:self.paymentTextField];
    [self.view bringSubviewToFront:self.paymentTextField];

}

@end
