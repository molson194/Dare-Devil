//
//  MOContractViewController.m
//  Dare Devil
//
//  Created by Matthew Olson on 2/25/16.
//  Copyright © 2016 Molson. All rights reserved.
//

#import "MOContractViewController.h"

@interface MOContractViewController ()

@end

@implementation MOContractViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor =  [UIColor colorWithRed:1 green:.2 blue:0.35 alpha:1.0];
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationController.navigationBar.hidden = NO;
    UITextView *dareLabel = [[UITextView alloc] initWithFrame:CGRectMake(3, 3, self.view.bounds.size.width-6, self.view.bounds.size.height-6)];
    dareLabel.textColor = [UIColor blackColor];
    [dareLabel setFont:[UIFont systemFontOfSize:12]];
    dareLabel.scrollEnabled = true;
    dareLabel.editable = false;
    dareLabel.text = @"Contract TEXT TODOadslf;kja;sldkfj;allka;sdfj;alksdjf;alksdjf;laksdjf;alskdjfa;lksdfj a;slkdfjals;dkf jasdl;kfj as;dlkfjasd;lkfjasd;lkfjasd;lkfja;lakdsfja;lksdjf;alksdjf;alksdjf;laksdjf;alksdjf;laksdjf;laksdjf;laksdjf;laksdjf;laksdjf;lkasdjf;laksdjf;laksdjf;alskdjf;alksdjf;alskdjf;alskdfj;alsdkfja;sldkfja;sdlkfjadls;kfjasd;fklaj sdf;lkasdj f;lkasdjf ;laksdfjas;ldkf jasdkl;fajsdf;lkasjdf ;lkasdjf als;kdfjas;dlkfjas d;lkfj as;ldkfjasd;klfj as;dlkfja sd;lkfj asd;lkf jasd;lkfjasd;lfkj asd;lkfjasd;lkfajsd;flkajs df;lkajsdf;lkajs d;flkasdjf;lkasdjf;l aksdfj;alskdfj;asdlkfj a;sdlkfjasd;lkfj as;dlkfjasd;lkfjasd;lkfj asd;lkfjasd;lkfjasd;lfkj asd;lkfj asd;lkfjasd;lkfjasd;lkfjas;dlkfjas;d lfkjasd;lkfjasd;lkfjasd;lkfjasd;lkfjs;dlkf jas;dlkfja;sldkfjas;dlkfja; sldkjf;alsdkfj;alskdfj;alskdjfa;lksdfja;lksdfj as;dlfjasd;lkfja;lskdfj;asdlkfj;alskd;qasdjfapsdjkf;asdjf;lkajsdf;lkasjdfl;kasdjf l;asdjfa;lksdjfa;lskdjfa;lskdfjas;dlkfjasd ;flkasjdf;lkasjdf;lkasdjf;lkasjdf;lkasdjf;lkasjdf;lkasdjf;laksdjfl;kasdjfal;sd f;alksdjf alsdkf jsadlkfjas ;dlkfajsdl;f kasdj;flk jasd;lfkjasd ;lfkas df;laskdf jas;dlkf jas;dlkf jasd;jf asdlfj asld;k fa;lsdj f;lasd jfl;kas df;lkajsdf;lkajsd;fjpoweiqjfpoasejfaposedjf;lkasdjf;la sd;fj a;lskdfj a;sldkf ja;sldkjf;alsdkfja;lksdfja;lskdfjal;ksd f;lkasdjfa ;lsdjaf;lkdjsf a;lsdkfja;sdlkf jasd;lkfjasd;lkfj as;dlkfj a;sldkfjal;k sdfj;aksldfj ;alskdjf ;alskdj f;alksdjfas;dlkjf a;lskdfja;sldkfj as;ldkfjasd;lk fas;dlkfja;lksdfj a;sdklfjas;dlkf ;la ksdjf;lkasd jf;laskedfj;asdlkfj asd;lfkjasd;lkf as;dlkjfas;dlkf as;dlkfjas;dlkfja ;sdkfja;sldkfj a;sldkfj as;dlkfj a;sldkfj as;dlkf asdk;lfjas ;dlkfasd; df;klasd jf;alksdjf ;alskdjf a;slkd f;lkasdjf as;dlkfj as;dlkf asd;fj a;slkdfas jd;lafj a;s ffj";
    [dareLabel setUserInteractionEnabled:YES];
    [self.view addSubview:dareLabel];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.title = @"Terms+Conditions";
    
    UIButton *disagreeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
    [disagreeButton setTitle:@"Disagree" forState:UIControlStateNormal];
    disagreeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [disagreeButton addTarget:self action:@selector(disagree) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *disagree = [[UIBarButtonItem alloc] initWithCustomView:disagreeButton];
    [disagree setTintColor:[UIColor whiteColor]];
    self.navigationItem.leftBarButtonItem = disagree;
    
    UIButton *agreeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
    [agreeButton setTitle:@"Agree" forState:UIControlStateNormal];
    agreeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [agreeButton addTarget:self action:@selector(agree) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *agree = [[UIBarButtonItem alloc] initWithCustomView:agreeButton];
    [agreeButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.rightBarButtonItem = agree;
}

// TODO agree and disagree buttons

@end
