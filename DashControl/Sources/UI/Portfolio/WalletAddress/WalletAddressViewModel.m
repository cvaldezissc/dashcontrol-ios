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

#import "WalletAddressViewModel.h"

#import "DCWalletAddressEntity+CoreDataClass.h"
#import "NSManagedObjectContext+DCExtensions.h"
#import "NSString+Dash.h"
#import "AddressTextFieldFormCellModel.h"
#import "ButtonFormCellModel.h"
#import "DCPersistenceStack.h"
#import "SwitcherFormCellModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WalletAddressType) {
    WalletAddressType_Address,
    WalletAddressType_Name,
    WalletAddressType_AddButton,
};

@interface WalletAddressViewModel ()

@property (nullable, strong, nonatomic) DCWalletAddressEntity *walletAddress;
@property (strong, nonatomic) AddressTextFieldFormCellModel *addressDetail;
@property (strong, nonatomic) TextFieldFormCellModel *nameDetail;

@end

@implementation WalletAddressViewModel

- (instancetype)initWithWalletAddress:(nullable DCWalletAddressEntity *)walletAddress {
    self = [super init];
    if (self) {
        _walletAddress = walletAddress;

        NSMutableArray *items = [NSMutableArray array];
        {
            _addressDetail = [[AddressTextFieldFormCellModel alloc] initWithTitle:NSLocalizedString(@"Address", nil)
                                                                      placeholder:NSLocalizedString(@"Wallet Address", nil)];
            _addressDetail.tag = WalletAddressType_Address;
            _addressDetail.text = _walletAddress.address;
            _addressDetail.returnKeyType = UIReturnKeyNext;
            [items addObject:_addressDetail];
        }
        {
            _nameDetail = [[TextFieldFormCellModel alloc] initWithTitle:NSLocalizedString(@"Name", nil)
                                                            placeholder:NSLocalizedString(@"Wallet name (optional)", nil)];
            _nameDetail.tag = WalletAddressType_Name;
            _nameDetail.text = _walletAddress.name;
            _nameDetail.returnKeyType = UIReturnKeyDone;
            [items addObject:_nameDetail];
        }
        {
            NSString *title = _walletAddress ? NSLocalizedString(@"SAVE", nil) : NSLocalizedString(@"ADD", nil);
            ButtonFormCellModel *detail = [[ButtonFormCellModel alloc] initWithTitle:title];
            detail.tag = WalletAddressType_AddButton;
            [items addObject:detail];
        }
        _items = [items copy];
    }
    return self;
}

- (BOOL)deleteAvailable {
    return (self.walletAddress != nil);
}

- (void)updateAddress:(NSString *)address {
    self.addressDetail.text = address;
}

- (void)deleteCurrentWithCompletion:(void (^)(void))completion {
    NSParameterAssert(self.walletAddress);

    NSManagedObjectID *objectID = self.walletAddress.objectID;
    weakify;
    [self.stack.persistentContainer performBackgroundTask:^(NSManagedObjectContext *_Nonnull context) {
        strongify;

        NSManagedObject *object = [context objectWithID:objectID];
        [context deleteObject:object];

        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        [context dc_saveIfNeeded];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    }];
}

- (NSInteger)indexOfInvalidDetail {
    for (NSInteger index = 0; index < self.items.count - 1; index++) {
        BaseFormCellModel *detail = self.items[index];
        if ([detail isKindOfClass:AddressTextFieldFormCellModel.class]) {
            NSString *text = [(AddressTextFieldFormCellModel *)detail text];
            if (text.length == 0 || ![text isValidDashAddressOnChain:self.chain]) {
                return index;
            }
        }
    }

    return NSNotFound;
}

- (void)saveCurrentWithCompletion:(void (^)(void))completion {
    NSAssert([self indexOfInvalidDetail] == NSNotFound, @"Validate data before saving");

    NSManagedObjectID * _Nullable objectID = self.walletAddress.objectID;
    
    weakify;
    [self.stack.persistentContainer performBackgroundTask:^(NSManagedObjectContext *_Nonnull context) {
        strongify;

        DCWalletAddressEntity *walletAddress = nil;
        if (objectID) {
            walletAddress = [context objectWithID:objectID];
        }
        else {
            walletAddress = [[DCWalletAddressEntity alloc] initWithContext:context];
        }
        walletAddress.address = self.addressDetail.text;
        NSString *trimmedName = [self.nameDetail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        walletAddress.name = trimmedName.length > 0 ? trimmedName : nil;

        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        [context dc_saveIfNeeded];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    }];
}

@end

NS_ASSUME_NONNULL_END
