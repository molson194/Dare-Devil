//
//  MOSubmissionsCell.m
//  Dare Devil
//
//  Created by Matthew Olson on 10/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import "MOSubmissionsCell.h"

@implementation MOSubmissionsCell

@synthesize imageView;
@synthesize videoView;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // SPECIFIC DARE
        self.dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(3, 30, self.bounds.size.width-6, 50)];
        self.dareLabel.textColor = [UIColor blackColor];
        [self.dareLabel setFont:[UIFont systemFontOfSize:12]];
        self.dareLabel.scrollEnabled = false;
        self.dareLabel.editable = false;
        
        // PERSON SUBMITTED LABEL
        self.personSubmitted = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, self.bounds.size.width-80, 15)];
        self.personSubmitted.textColor = [UIColor blackColor];
        [self.personSubmitted setFont:[UIFont systemFontOfSize:15]];
        [self addSubview:self.personSubmitted];
        
        // MONEY RAISED LABEL
        self.moneyRaised = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width-60, 15, 50, 15)];
        self.moneyRaised.textColor = [UIColor blackColor];
        [self.moneyRaised setTextAlignment:NSTextAlignmentRight];
        [self.moneyRaised setFont:[UIFont systemFontOfSize:15]];
        [self addSubview:self.moneyRaised];
        
    }
    return self;
}

@end
