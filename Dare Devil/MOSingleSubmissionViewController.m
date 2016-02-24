//
//  MOSingleSubmissionViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 2/16/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import "MOSingleSubmissionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"

@interface MOSingleSubmissionViewController ()
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic, strong) MBProgressHUD *hud;
@end

@implementation MOSingleSubmissionViewController

-(void)viewDidLoad {
    self.tableView.delegate = self;
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Submission";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)setObject:(PFObject *)object {
    self.obj = object;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// HEIGHT OF CELL
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.obj fetchInBackground];
    if (self.obj[@"isVertical"] == [NSNumber numberWithBool:YES]){
        return self.view.bounds.size.width + 150;
    } else {
        return self.view.bounds.size.width-20;
    }
}

// SETUP CELL WITH PARSE DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFObject *dareObject = [self.obj objectForKey:@"dare"];
    [dareObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        UITextView *dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(3, 5, self.view.bounds.size.width-6, 50)];
        dareLabel.textColor = [UIColor blackColor];
        [dareLabel setFont:[UIFont systemFontOfSize:12]];
        dareLabel.scrollEnabled = false;
        dareLabel.editable = false;
        dareLabel.text = [object objectForKey:@"text"];
        [dareLabel setUserInteractionEnabled:NO];
        [cell.contentView addSubview:dareLabel];
        UILabel *moneyRaised = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-60, 15, 50, 15)];
        moneyRaised.textColor = [UIColor blackColor];
        [moneyRaised setTextAlignment:NSTextAlignmentRight];
        [moneyRaised setFont:[UIFont systemFontOfSize:15]];
        [cell.contentView addSubview:moneyRaised];
        NSNumber *funding = [object objectForKey:@"totalFunding"];
        moneyRaised.text = [NSString stringWithFormat:@"$ %d", funding.intValue ];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    if (self.obj[@"video"]) {
        PFFile *video = [self.obj objectForKey:@"video"];
        [video getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            [self.hud removeFromSuperview];
            self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
            AVPlayerLayer *videoView = nil;
            videoView = [AVPlayerLayer playerLayerWithPlayer:self.player];
            videoView.frame = CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width+60);
            videoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
            videoView.needsDisplayOnBoundsChange = YES;
            [self.view.layer addSublayer:videoView];
            [self.player play];
        } progressBlock:^(int percentDone) {
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            self.hud.mode = MBProgressHUDModeIndeterminate;
            self.hud.labelText = @"Loading";
        }];
    } else if (self.obj[@"image"]) {
        PFImageView *imageView = nil;
        if (self.obj[@"isVertical"] == [NSNumber numberWithBool:YES]) {
            imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width+60)];
        } else {
            imageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width-100)];
        }
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        imageView.file = [self.obj objectForKey:@"image"];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        [imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [cell.contentView addSubview:imageView];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = self.view.layer.sublayers;
    AVPlayerLayer *myLayer = nil;
    for (CALayer *layer in array) {
        if ([layer class] == [AVPlayerLayer class]){
            myLayer = (AVPlayerLayer*)layer;
        }
    }
    if (myLayer != nil) {
        [myLayer removeFromSuperlayer];
    }
    if (self.obj[@"video"]) {
        NSArray *array = self.view.layer.sublayers;
        CALayer *removeLayer = nil;
        for (CALayer *layer in array) {
            if ([layer class] == [AVPlayerLayer class]){
                removeLayer = layer;
            }
        }
        if (removeLayer!= nil){
            [removeLayer removeFromSuperlayer];
        }
        
        PFFile *video = [self.obj objectForKey:@"video"];
        AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:video.url]];
        AVPlayerLayer *videoView = nil;
        videoView = [AVPlayerLayer playerLayerWithPlayer:player];
        videoView.frame = CGRectMake(0, 80, self.view.bounds.size.width, self.view.bounds.size.width+60);
        videoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
        videoView.needsDisplayOnBoundsChange = YES;
        [self.view.layer addSublayer:videoView];
        [player play];
    }
    //TODO check functionality
}



@end
