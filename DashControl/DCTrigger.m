//
//  DCTrigger.m
//  DashControl
//
//  Created by Sam Westrich on 11/5/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DCTrigger.h"

@implementation DCTrigger

-(id)initWithType:(DCTriggerType)type value:(NSNumber*)value market:(NSString*)market {
    if (self = [super init]) {
        self.type = type;
        self.value = value;
        self.market = market;
        self.exchange = @"any";
        self.standardizeTether = TRUE;
    }
    return self;
}

+(NSString*)networkStringForType:(DCTriggerType)triggerType {
    switch (triggerType) {
        case DCTriggerAbove:
            return @"above";
            break;
        case DCTriggerBelow:
            return @"below";
            break;
        case DCTriggerAboveFor:
            return @"above_for";
            break;
        case DCTriggerBelowFor:
            return @"below_for";
            break;
        case DCTriggerSpikeUp:
            return @"spike_up";
            break;
        case DCTriggerSpikeDown:
            return @"spike_down";
            break;
        default:
            break;
    }
    return nil;
}

+(DCTriggerType)typeForNetworkString:(NSString* _Nonnull)networkString {
    if ([networkString isEqualToString:@"above"]) {
        return DCTriggerAbove;
    } else if ([networkString isEqualToString:@"below"]) {
        return DCTriggerBelow;
    } else if ([networkString isEqualToString:@"above_for"]) {
        return DCTriggerAboveFor;
    } else if ([networkString isEqualToString:@"below_for"]) {
        return DCTriggerBelowFor;
    } else if ([networkString isEqualToString:@"spike_up"]) {
        return DCTriggerSpikeUp;
    } else if ([networkString isEqualToString:@"spike_down"]) {
        return DCTriggerSpikeDown;
    }
    return DCTriggerUnknown;
}

@end
