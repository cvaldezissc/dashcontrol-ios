//
//  ProposalsViewController.m
//  DashControl
//
//  Created by Manuel Boyer on 23/08/2017.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "ProposalsViewController.h"
#import "ProposalCell.h"
#import "ProposalDetailViewController.h"

@interface ProposalsViewController ()
@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;
@end

@implementation ProposalsViewController
@synthesize managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;

static NSString *CellIdentifier = @"ProposalCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    managedObjectContext = [[ProposalsManager sharedManager] managedObjectContext];
    
    [self cfgSearchController];
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.fetchedResultsController = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // restore the searchController's active state
    if (self.searchControllerWasActive) {
        self.searchController.active = self.searchControllerWasActive;
        _searchControllerWasActive = NO;
        
        if (self.searchControllerSearchFieldWasFirstResponder) {
            [self.searchController.searchBar becomeFirstResponder];
            _searchControllerSearchFieldWasFirstResponder = NO;
        }
    }
    
    Budget *budget = [[[ProposalsManager sharedManager] fetchAllObjectsForEntity:@"Budget" inContext:self.managedObjectContext] firstObject];
    [budget allotedAmount];
    NSLog(@"Budget:%@", budget);
    /*
    NSArray *proposals = [[ProposalsManager sharedManager] fetchAllObjectsForEntity:@"Proposal" inContext:self.managedObjectContext];
    NSLog(@"All proposals count:%lu", (unsigned long)[proposals count]);
    for (Proposal *proposal in proposals) {
        NSLog(@"Proposal:%@\rThe proposal has %tu comments", proposal.title, proposal.comments.count);
    }
     */
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id  sectionInfo =
    [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Proposal *proposal = [_fetchedResultsController objectAtIndexPath:indexPath];
    [(ProposalCell*)cell setCurrentProposal:proposal];
    [(ProposalCell*)cell cfgViews];
    [(ProposalCell*)cell progressView].value = 0;
    /*
    CGFloat currentProgress =  (proposal.yes / (proposal.yes + proposal.remainingYesVotesUntilFunding)) * 100;
    CGFloat lastProgress = [[ProposalsManager sharedManager] lastProgressDisplayedForProposal:proposal];
    
    NSLog(@"%@ : %.2f - %.2f", proposal.title, currentProgress, lastProgress);
    
    if (lastProgress != currentProgress) {
        [UIView animateWithDuration:1.f animations:^{
            [(ProposalCell*)cell progressView].value = currentProgress;
        }];
    }
    else {
        [(ProposalCell*)cell progressView].value = currentProgress;
    }
     */
}

-(void) tableView:(UITableView *) tableView willDisplayCell:(UITableViewCell *) cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Proposal *proposal = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    CGFloat currentProgress =  (proposal.yes / (proposal.yes + proposal.remainingYesVotesUntilFunding)) * 100;
    CGFloat lastProgress = [[ProposalsManager sharedManager] lastProgressDisplayedForProposal:proposal];
    
    if (lastProgress != currentProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1.f delay:CGFLOAT_MIN options:UIViewAnimationOptionTransitionNone animations:^{
                [(ProposalCell*)cell progressView].value = currentProgress;
            } completion:^(BOOL finished) {
                [[ProposalsManager sharedManager] setLastProgressDisplayed:currentProgress forProposal:proposal];
            }];
        });
    }
    else {
        [(ProposalCell*)cell progressView].value = currentProgress;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProposalCell *cell = (ProposalCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
     if ([[segue identifier] isEqualToString:@"pushProposalDetail"])
     {
         //Get reference to the destination view controller
         ProposalDetailViewController *vc = [segue destinationViewController];
         [vc setCurrentProposal:[(ProposalCell*)sender currentProposal]];
     }
}

#pragma mark - fetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Proposal" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSString *searchString = self.searchController.searchBar.text;
    if (searchString.length > 0)
    {
        NSPredicate *titleP = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchString];
        NSPredicate *ownerP = [NSPredicate predicateWithFormat:@"ownerUsername CONTAINS[cd] %@", searchString];
        NSPredicate *orPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:titleP, ownerP, nil]];
        NSPredicate *finalPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:orPredicate, /*andPredicate,*/ nil]];
        [fetchRequest setPredicate:finalPred];
    }
    else
    {
        //[fetchRequest setPredicate:langP];
    }
    
    
    NSSortDescriptor *dateAddedSort = [[NSSortDescriptor alloc]
                                     initWithKey:@"dateAdded" ascending:NO];
    NSSortDescriptor *titleSort = [[NSSortDescriptor alloc]
                                   initWithKey:@"title" ascending:YES];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:dateAddedSort, titleSort, nil]];
    
    //[fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self configureCell:[tableView cellForRowAtIndexPath:newIndexPath] atIndexPath:indexPath];
            
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;
            
        case NSFetchedResultsChangeMove:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - UISearchController

-(void)cfgSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.fetchedResultsController = nil;
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [self.tableView reloadData];
}

@end
