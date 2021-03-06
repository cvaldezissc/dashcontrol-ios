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

#import <KVO-MVVM/KVONSObject.h>

#import "BaseFormCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@class DCMasternodeEntity;
@class DCPersistenceStack;
@class APIPortfolio;
@class DSChain;
@class DSSimplifiedMasternodeEntryEntity;

@interface MasternodeViewModel : KVONSObject

@property (strong, nonatomic) InjectedClass(DCPersistenceStack) stack;
@property (strong, nonatomic) InjectedClass(APIPortfolio) apiPortfolio;
@property (strong, nonatomic) InjectedClass(DSChain) chain;

@property (readonly, strong, nonatomic) NSArray<BaseFormCellModel *> *items;
@property (readonly, assign, nonatomic) BOOL deleteAvailable;

- (instancetype)initWithMasternode:(nullable DSSimplifiedMasternodeEntryEntity *)masternode;

- (void)updateAddress:(NSString *)address;

- (void)deleteCurrentWithCompletion:(void (^)(void))completion;

- (NSInteger)indexOfInvalidDetail;

- (void)registerMasternodeCompletion:(void (^)(NSString *_Nullable errorMessage, NSInteger indexOfInvalidDetail))completion;

@end

NS_ASSUME_NONNULL_END
