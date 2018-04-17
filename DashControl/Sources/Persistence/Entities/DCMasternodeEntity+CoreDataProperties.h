//
//  DCMasternodeEntity+CoreDataProperties.h
//  DashControl
//
//  Created by Sam Westrich on 10/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//
//

#import "DCMasternodeEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DCMasternodeEntity (CoreDataProperties)

+ (NSFetchRequest<DCMasternodeEntity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *address;
@property (nonatomic) int64_t amount;
@property (nullable, nonatomic, copy) NSString *secureVotingKeyPath;
@property (nullable, nonatomic, retain) NSSet<DCMasternodePaymentEntity *> *payments;

@end

@interface DCMasternodeEntity (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(DCMasternodePaymentEntity *)value;
- (void)removePaymentsObject:(DCMasternodePaymentEntity *)value;
- (void)addPayments:(NSSet<DCMasternodePaymentEntity *> *)values;
- (void)removePayments:(NSSet<DCMasternodePaymentEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
