//
//  DCWalletManager.m
//  DashControl
//
//  Created by Sam Westrich on 10/23/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DCWalletManager.h"

#import <DashSync/DashSync.h>

#import "DCWalletAccountEntity+CoreDataClass.h"
#import "DCWalletAccountEntity+Extensions.h"
#import "DCWalletAddressEntity+CoreDataClass.h"
#import "DCWalletEntity+CoreDataClass.h"
#import "DCWalletEntity+Extensions.h"
#import "NSData+Dash.h"
#import "NSManagedObject+DCExtensions.h"
#import "NSManagedObjectContext+DCExtensions.h"
#import "APIPortfolio.h"
#import "DCPersistenceStack.h"
#import "DCServerBloomFilter.h"
#import "DCWalletAccount.h"

static NSString *const SERVER_BLOOM_FILTER_HASH = @"SERVER_BLOOM_FILTER_HASH";

NSString *Hash160String(NSData *data) {
       UInt160 hash160 = data.hash160;
       NSMutableData *d = [NSMutableData secureDataWithCapacity:160/8 + 1];
       [d appendBytes:&hash160 length:sizeof(hash160)];
       return [NSString base58checkWithData:d];
}

@interface DCWalletManager ()

@property (nonatomic, strong) NSMutableSet<DCWalletAccount *> *wallets;

@end

@implementation DCWalletManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _wallets = [NSMutableSet set];
        
        NSAssert(self.chain, @"Chain should be set after initializing DashSync");
        
        [self.stack.persistentContainer performBackgroundTask:^(NSManagedObjectContext *context) {
            NSArray<DCWalletAccountEntity *> *accountEntities = [DCWalletAccountEntity dc_objectsInContext:context];
            for (DCWalletAccountEntity *accountEntity in accountEntities) {
                NSString *locationInKeyValueStore = accountEntity.hash160Key;
                NSString *pubkeyString = [[NSUserDefaults standardUserDefaults] stringForKey:locationInKeyValueStore];
                DCWalletAccount *walletAccount = [[DCWalletAccount alloc] initWithAccountPublicKey:pubkeyString
                                                                                              hash:locationInKeyValueStore
                                                                                         inContext:context
                                                                                           onChain:self.chain];
                [self.wallets addObject:walletAccount];
                [walletAccount startUpWithWalletAccountEntity:accountEntity];
            }
            [self updateBloomFilterInContext:context];
        }];
    }
    return self;
}

- (void)importWalletMasterAddressFromSource:(NSString *)source
                    withExtended32PublicKey:(NSString *_Nullable)extended32PublicKey
                        extended44PublicKey:(NSString *_Nullable)extended44PublicKey {
    NSAssert(self.chain, @"Chain should be set after initializing DashSync");
    
    BOOL valid = ([extended32PublicKey isValidDashExtendedPublicKeyOnChain:self.chain] ||
                  [extended44PublicKey isValidDashExtendedPublicKeyOnChain:self.chain]);
    if (!valid) {
        return;
    }

    [self.stack.persistentContainer performBackgroundTask:^(NSManagedObjectContext *context) {
        NSData *data32 = [DSDerivationPath deserializedExtendedPublicKey:extended32PublicKey onChain:self.chain];
        NSData *data44 = [DSDerivationPath deserializedExtendedPublicKey:extended44PublicKey onChain:self.chain];
        NSString *extended32PublicKeyHash = Hash160String(data32);
        NSString *extended44PublicKeyHash = Hash160String(data44);

        DCWalletAccountEntity *wallet32Account;
        BOOL has32Account = [DCWalletAccountEntity hasWalletAccountForPublicKeyHash:extended32PublicKeyHash inContext:context];
        if (!has32Account) {
            wallet32Account = [[DCWalletAccountEntity alloc] initWithContext:context];
            wallet32Account.hash160Key = extended32PublicKeyHash;
            [[NSUserDefaults standardUserDefaults] setObject:extended32PublicKey forKey:extended32PublicKeyHash];
        }

        DCWalletAccountEntity *wallet44Account;
        BOOL has44Account = [DCWalletAccountEntity hasWalletAccountForPublicKeyHash:extended44PublicKeyHash inContext:context];
        if (!has44Account) {
            wallet44Account = [[DCWalletAccountEntity alloc] initWithContext:context];
            wallet44Account.hash160Key = extended44PublicKeyHash;
            [[NSUserDefaults standardUserDefaults] setObject:extended44PublicKey forKey:extended44PublicKeyHash];
        }

        if (has44Account && has32Account) {
            //we already have both accounts
            return;
        }

        DCWalletEntity *wallet;
        if (has32Account || has44Account) {
            NSMutableArray<DCWalletAccountEntity *> *accounts = [NSMutableArray array];
            if (wallet32Account) {
                [accounts addObject:wallet32Account];
            }
            if (wallet44Account) {
                [accounts addObject:wallet44Account];
            }

            wallet = [DCWalletEntity walletHavingOneOfAccounts:accounts withIdentifier:source inContext:context];
            if (![wallet.accounts containsObject:wallet44Account]) {
                [wallet addAccountsObject:wallet44Account];
            }
            if (![wallet.accounts containsObject:wallet32Account]) {
                [wallet addAccountsObject:wallet32Account];
            }
        }

        if (!wallet) {
            wallet = [[DCWalletEntity alloc] initWithContext:context];
            [wallet addAccountsObject:wallet32Account];
            [wallet addAccountsObject:wallet44Account];
            wallet.dateAdded = [NSDate date];
            wallet.name = source;
            wallet.identifier = source;
        }

        context.automaticallyMergesChangesFromParent = YES;
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        [context dc_saveIfNeeded];

        if (!has32Account) {
            DCWalletAccount *data32Account = [[DCWalletAccount alloc] initWithAccountPublicKey:extended32PublicKey
                                                                                          hash:extended32PublicKeyHash
                                                                                     inContext:context
                                                                                       onChain:self.chain];
            [self.wallets addObject:data32Account];
            [data32Account startUpWithWalletAccountEntity:wallet32Account];
        }
        if (!has44Account) {
            DCWalletAccount *data44Account = [[DCWalletAccount alloc] initWithAccountPublicKey:extended44PublicKey
                                                                                          hash:extended44PublicKeyHash
                                                                                     inContext:context
                                                                                       onChain:self.chain];
            [self.wallets addObject:data44Account];
            [data44Account startUpWithWalletAccountEntity:wallet44Account];
        }

        [self updateBloomFilterInContext:context];
    }];
}

- (void)updateBloomFilterInContext:(NSManagedObjectContext *)context {
    NSArray<DCWalletAddressEntity *> *walletAddressEntities = [DCWalletAddressEntity dc_objectsInContext:context];
    if (walletAddressEntities.count > 0) {
        NSArray<NSString *> *walletAddresses = [walletAddressEntities arrayReferencedByKeyPath:@"address"];
        DCServerBloomFilter *bloomFilter = [self bloomFilterForAddresses:walletAddresses];
        NSData *bloomFilterHashData = [NSData dataWithUInt160:bloomFilter.filterHash];
        NSData *previousBloomFilterHashData = [[NSUserDefaults standardUserDefaults] dataForKey:SERVER_BLOOM_FILTER_HASH];
        if (!previousBloomFilterHashData || ![bloomFilterHashData isEqualToData:previousBloomFilterHashData]) {
            [self.api updateBloomFilter:bloomFilter completion:^(NSError *_Nullable error) {
                if (!error) {
                    [[NSUserDefaults standardUserDefaults] setObject:bloomFilterHashData forKey:SERVER_BLOOM_FILTER_HASH];
                }
            }];
        }
    }
}

- (DCServerBloomFilter *)bloomFilterForAddresses:(NSArray *)addresses {
    DCServerBloomFilter *filter = [[DCServerBloomFilter alloc] initWithFalsePositiveRate:BLOOM_REDUCED_FALSEPOSITIVE_RATE
                                                                         forElementCount:addresses.count];
    // double fpRate = [filter falsePositiveRate];
    for (NSString *addr in addresses) { // add addresses to watch for tx receiveing money to the wallet
        NSData *hash = addr.addressToHash160;
        if (hash && ![filter containsData:hash]) {
            [filter insertData:hash];
        }
    }
    return filter;
}

@end
