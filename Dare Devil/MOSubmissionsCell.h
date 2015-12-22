//
//  MOSubmissionsCell.h
//  Dare Devil
//
//  Created by Matthew Olson on 10/26/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <ParseUI/ParseUI.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MOSubmissionsCell : PFTableViewCell

@property (nonatomic, strong) UITextView *dareLabel;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UILabel *personSubmitted;
@property (nonatomic, strong) UILabel *moneyRaised;
@property (nonatomic, strong) PFImageView *imageView;
@property (nonatomic, strong) AVPlayerLayer *videoView;
@property (nonatomic, strong) AVPlayer *player;

@end
