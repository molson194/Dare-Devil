//
//  MODareTableViewCell.m
//  Dare Devil
//
//  Created by Matthew Olson on 10/11/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MODareTableViewCell.h"

@interface MODareTableViewCell ()

@end

@implementation MODareTableViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // SPECIFIC DARE
        self.dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, 7*self.bounds.size.width/8, 70)];
        self.dareLabel.textColor = [UIColor blackColor];
        [self.dareLabel setFont:[UIFont systemFontOfSize:15]];
        self.dareLabel.scrollEnabled = false;
        self.dareLabel.editable = false;
        
        // ADD FUNDS BUTTON
        self.fundsButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 80, self.bounds.size.width/8, 12)];
        [self.fundsButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [self.fundsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.fundsButton.titleLabel.font = [UIFont systemFontOfSize:18];
        
        // UPLOAD A SUBMISSION BUTTON
        self.uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(7*self.bounds.size.width/8-5, 80, self.bounds.size.width/8, 12)];
        [self.uploadButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [self.uploadButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.uploadButton.titleLabel.font = [UIFont systemFontOfSize:18];
        
        // TIME LEFT LABEL
        self.timeLeft = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width-35, 5, 30, 12)];
        self.timeLeft.textColor = [UIColor lightGrayColor];
        [self.timeLeft setTextAlignment:NSTextAlignmentCenter];
        self.timeLeft.font = [UIFont systemFontOfSize:13];
    }
    
    return self;
}

@end
