//
//  Created by Andrew Podkovyrin
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <KVO-MVVM/KVOUITableViewController.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface FetchedResultsTableViewController : KVOUITableViewController <NSFetchedResultsControllerDelegate>

@property (readonly, strong, nonatomic) NSMutableArray<NSIndexPath *> *deletedRowIndexPaths;
@property (readonly, strong, nonatomic) NSMutableArray<NSIndexPath *> *insertedRowIndexPaths;
@property (readonly, strong, nonatomic) NSMutableArray<NSIndexPath *> *updatedRowIndexPaths;

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(nullable NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath *)newIndexPath NS_REQUIRES_SUPER;
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END