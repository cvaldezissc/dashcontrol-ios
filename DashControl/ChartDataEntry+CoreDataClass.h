//
//  ChartDataEntry+CoreDataClass.h
//  DashControl
//
//  Created by Sam Westrich on 9/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Exchange, Market;

NS_ASSUME_NONNULL_BEGIN

@interface ChartDataEntry : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "ChartDataEntry+CoreDataProperties.h"
