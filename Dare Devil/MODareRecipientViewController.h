//
//  MODareRecipientViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 12/18/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ParseUI/ParseUI.h>

@protocol senddataProtocol <NSObject>
-(void)sendDataToPostViewfacebook:(NSMutableArray *)facebookTags contacts:(NSMutableArray *)contactTags world:(BOOL)worldPost;
@end

@interface MODareRecipientViewController : UIViewController <UISearchResultsUpdating, UISearchBarDelegate,UINavigationControllerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic,assign)id delegate;
@property(nonatomic,strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *allContacts;
@property (nonatomic, strong) __block NSMutableArray *allFacebook;
@property (nonatomic, strong) NSMutableArray *allPeople;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *taggedContacts;
@property (nonatomic, strong) NSMutableArray *taggedFacebook;
@property (nonatomic, strong) UIButton *worldButton;
@property (nonatomic, strong) UIButton *friendsButton;
@property (nonatomic) BOOL toWorld;
- (void) reopenWithFacebook:(NSMutableArray*)facebookTags contacts:(NSMutableArray *)contactTags world:(BOOL)world;

@end
