//
//  MODareTargetViewController.h
//  Dare Devil
//
//  Created by Matthew Olson on 12/21/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ParseUI/ParseUI.h>

@protocol sendDataProtocol <NSObject>
-(void)sendDataToPostView:(NSArray *)contact;
@end

@interface MODareTargetViewController : UIViewController <UISearchResultsUpdating, UISearchBarDelegate,UINavigationControllerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic,assign)id delegate;
@property(nonatomic,strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *allContacts;
@property (nonatomic, strong) __block NSMutableArray *allFacebook;
@property (nonatomic, strong) NSMutableArray *allPeople;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UIButton *someoneButton;
@property (nonatomic, strong) NSArray *finalTarget;


@end
