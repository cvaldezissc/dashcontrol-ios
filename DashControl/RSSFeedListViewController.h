//
//  RSSFeedListViewController.h
//  DashControl
//
//  Created by Manuel Boyer on 09/08/2017.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

@interface RSSFeedListViewController : UIViewController <NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, SFSafariViewControllerDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;

//3D Touch
@property (nonatomic, strong) id previewingContext;

-(void)simulateNavitationToPostWithGUID:(NSString*)guid;

@end
