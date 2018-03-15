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
//

#import "DCBudgetInfoEntity+CoreDataProperties.h"

@implementation DCBudgetInfoEntity (CoreDataProperties)

+ (NSFetchRequest<DCBudgetInfoEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DCBudgetInfoEntity"];
}

@dynamic allotedAmount;
@dynamic paymentDate;
@dynamic superblock;
@dynamic totalAmount;

@end
