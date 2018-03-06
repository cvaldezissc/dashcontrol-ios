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

#import <Foundation/Foundation.h>

#import "DCBudgetInfoEntity+CoreDataClass.h"
#import "DCBudgetProposalEntity+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@class DCPersistenceStack;
@class APIBudget;

@interface ProposalsViewModel : NSObject

@property (strong, nonatomic) InjectedClass(DCPersistenceStack) stack;
@property (strong, nonatomic) InjectedClass(APIBudget) api;

@property (readonly, strong, nonatomic) NSFetchedResultsController<DCBudgetProposalEntity *> *fetchedResultsController;
@property (readonly, nullable, strong, nonatomic) NSFetchedResultsController<DCBudgetProposalEntity *> *searchFetchedResultsController;

- (void)reloadWithCompletion:(void (^)(BOOL success))completion;

- (BOOL)searchWithQuery:(NSString *)query;

@end

NS_ASSUME_NONNULL_END
