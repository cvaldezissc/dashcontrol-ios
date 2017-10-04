//
//  PortfolioManager.m
//  DashControl
//
//  Created by Sam Westrich on 10/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "PortfolioManager.h"
#import "DCCoreDataManager.h"
#import "NSArray+SWAdditions.h"
#import <AFNetworking/AFNetworking.h>
#import "WalletAddress+CoreDataClass.h"

@implementation PortfolioManager

+ (id)sharedManager {
    static PortfolioManager *sharedPortfolioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPortfolioManager = [[self alloc] init];
    });
    return sharedPortfolioManager;
}


-(uint64_t)totalWorthInContext:(NSManagedObjectContext* _Nullable)context error:(NSError*_Nullable* _Nullable)error {
    uint64_t total = 0;
    NSArray * walletAddresses = [[DCCoreDataManager sharedManager] walletAddressesInContext:context error:error];
    if (*error) return 0;
    NSNumber * walletSum =  [walletAddresses valueForKeyPath:@"@sum.amount"];
    total += [walletSum longLongValue];

    NSArray * masternodes = [[DCCoreDataManager sharedManager] masternodesInContext:context error:error];
    if (*error) return 0;
    NSNumber * masternodeSum =  [masternodes valueForKeyPath:@"@sum.amount"];
    total += [masternodeSum longLongValue];
    
    return total;
}

-(void)updateAmounts {
    NSPersistentContainer *container = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentContainer];
    [container performBackgroundTask:^(NSManagedObjectContext *context) {
        NSError * error = nil;
        NSArray * walletAddresses = [[DCCoreDataManager sharedManager] walletAddressesInContext:context error:&error];
        if (error) return;
        
        NSArray * masternodes = [[DCCoreDataManager sharedManager] masternodesInContext:context error:&error];
        if (error) return;

        
        NSArray * addresses = [[walletAddresses arrayReferencedByKeyPath:@"address"] arrayByAddingObjectsFromArray:[masternodes arrayReferencedByKeyPath:@"address"]];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSString * addr = [NSString stringWithFormat:@"https://insight.dash.org/insight-api-dash/addrs/%@/utxo",[addresses componentsJoinedByString:@":"]];
        [manager GET:addr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
            NSDictionary * addressAmountDictionary = [((NSArray*)responseObject) dictionaryReferencedByKeyPath:@"address" objectPath:@"@sum.amount"];
            BOOL updatedAmounts = FALSE;
            for (WalletAddress * address in walletAddresses) {
                if ([addressAmountDictionary objectForKey:address.address]) {
                    updatedAmounts = TRUE;
                    [address setAmount:[[addressAmountDictionary objectForKey:address.address] longLongValue]];
                }
            }
            context.automaticallyMergesChangesFromParent = TRUE;
            context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Failure to save context: %@\n%@", [error localizedDescription], [error userInfo]);
                abort();
            }
            else {
                
                if (updatedAmounts) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                        [notificationCenter postNotificationName:PORTFOLIO_DID_UPDATE_NOTIFICATION
                                                          object:nil
                                                        userInfo:nil];
                    });
                }
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
    }];
}

@end
