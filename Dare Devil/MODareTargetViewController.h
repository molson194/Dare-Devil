//
//
//  Dare Devil
//
//  Created by Matthew Olson on 12/18/15.
//  Copyright © 2015 Molson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ParseUI/ParseUI.h>

@protocol sendData <NSObject>
-(void)sendPerson:(NSArray *)person;
@end

@interface MODareTargetViewController : UIViewController <UINavigationControllerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic,assign)id delegate;
@property(nonatomic,strong) UITableView *tableView;
@property (nonatomic, strong) __block NSMutableArray *allFacebook;

@end
