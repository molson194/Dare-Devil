//
//  MODareTableViewCell.h
//  Dare Devil
//
//  Created by Matthew Olson on 10/11/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface MODareTableViewCell: PFTableViewCell

@property (nonatomic, strong) UITextView *dareLabel;
@property (nonatomic, strong) UIButton *fundsButton;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) UILabel *timeLeft;

@end
