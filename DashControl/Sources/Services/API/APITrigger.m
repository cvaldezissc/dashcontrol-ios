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

#import "APITrigger.h"

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "DCExchangeEntity+Extensions.h"
#import "DCMarketEntity+Extensions.h"
#import "NSManagedObject+DCExtensions.h"
#import "NSManagedObjectContext+DCExtensions.h"
#import "DCEnvironment.h"
#import "DCPersistenceStack.h"
#import "DCTrigger.h"
#import "Networking.h"

NS_ASSUME_NONNULL_BEGIN

#define USE_PRODUCTION 1

#ifdef USE_PRODUCTION
static NSString *const API_BASE_URL = @"https://dashpay.info/api/v0/";
#else
static NSString *const API_BASE_URL = @"https://dev.dashpay.info/api/v0/";
#endif

@interface APITrigger ()

@property (nullable, copy, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) NSMutableArray<void (^)(BOOL)> *registerCompletionBlocks;
@property (weak, nonatomic) id<HTTPLoaderOperationProtocol> registerRequest;

@end

@implementation APITrigger

- (instancetype)init {
    self = [super init];
    if (self) {
        _registerCompletionBlocks = [NSMutableArray array];
    }
    return self;
}

- (void)performRegisterWithDeviceToken:(NSString *)deviceToken {
    self.deviceToken = deviceToken;

    self.registerRequest = [self registerWithCompletion:nil];
}

- (nullable id<HTTPLoaderOperationProtocol>)registerWithCompletion:(void (^_Nullable)(BOOL success))completion {
    if (completion) {
        [self.registerCompletionBlocks addObject:[completion copy]];
    }

    // token hasn't received yet
    if (!self.deviceToken) {
        return nil;
    }

    // token api request is in progress, just wait
    if (self.registerRequest) {
        return self.registerRequest;
    }

    NSString *urlString = [API_BASE_URL stringByAppendingString:@"device"];
    NSURL *url = [NSURL URLWithString:urlString];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    NSMutableDictionary *parameters = [@{
        @"version" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
        @"model" : deviceName,
        @"os" : @"ios",
        @"device_id" : [[DCEnvironment sharedInstance] deviceId],
        @"password" : [[DCEnvironment sharedInstance] devicePassword],
        @"os_version" : [[UIDevice currentDevice] systemVersion],
        @"app_name" : @"dashcontrol",
    } mutableCopy];

    parameters[@"token"] = self.deviceToken;

    HTTPRequest *request = [HTTPRequest requestWithURL:url method:HTTPRequestMethod_POST parameters:parameters];
    request.maximumRetryCount = 2; // this request is important
    id<HTTPLoaderOperationProtocol> registerRequest = [self.httpManager sendRequest:request completion:^(id _Nullable parsedData, NSDictionary *_Nullable responseHeaders, NSInteger statusCode, NSError *_Nullable error) {
        if (error) {
            DCDebugLog([self class], error);
        }

        BOOL success = (error == nil);
        if (success) {
            [[DCEnvironment sharedInstance] setHasRegistered];
        }

        for (void (^completionBlock)(BOOL) in self.registerCompletionBlocks) {
            completionBlock(success);
        }
        [self.registerCompletionBlocks removeAllObjects];
        self.registerRequest = nil;
    }];

    self.registerRequest = registerRequest;

    return registerRequest;
}

- (id<HTTPLoaderOperationProtocol>)getTriggersCompletion:(void (^)(BOOL success))completion {
    NSString *urlString = [API_BASE_URL stringByAppendingString:@"trigger"];
    NSURL *url = [NSURL URLWithString:urlString];

    HTTPRequest *request = [HTTPRequest requestWithURL:url method:HTTPRequestMethod_GET parameters:nil];
    return [self sendAuthorizedRequest:request completion:^(id _Nullable parsedData, NSDictionary *_Nullable responseHeaders, NSInteger statusCode, NSError *_Nullable error) {
        if ([parsedData isKindOfClass:[NSArray class]]) {
            NSPersistentContainer *container = self.stack.persistentContainer;
            [container performBackgroundTask:^(NSManagedObjectContext *context) {
                NSDictionary *triggerIdentifiers = [parsedData dictionaryReferencedByKeyPath:@"identifier"];
                NSDictionary *knownTriggerIdentifiers = [[DCTriggerEntity dc_objectsInContext:context] dictionaryReferencedByKeyPath:@"identifier"] ?: @{};

                NSArray *triggerIdentifierKeys = triggerIdentifiers.allKeys;
                NSArray *knownTriggerIdentifierKeys = knownTriggerIdentifiers.allKeys;
                NSArray *novelTriggerIdentifiers = [triggerIdentifierKeys arrayByRemovingObjectsFromArray:knownTriggerIdentifierKeys];
                for (NSString *identifier in novelTriggerIdentifiers) {
                    NSDictionary *triggerToAdd = triggerIdentifiers[identifier];
                    DCTriggerEntity *trigger = [[DCTriggerEntity alloc] initWithContext:context];
                    trigger.identifier = [triggerToAdd[@"identifier"] longLongValue];
                    trigger.value = [triggerToAdd[@"value"] doubleValue];
                    trigger.type = [DCTrigger typeForNetworkString:triggerToAdd[@"type"]];
                    trigger.consume = [triggerToAdd[@"consume"] boolValue];
                    trigger.ignoreFor = [triggerToAdd[@"ignoreFor"] longLongValue];
                    NSString *exchangeName = triggerToAdd[@"exchange"];
                    if (exchangeName) {
                        trigger.exchangeNamed = exchangeName;
                        trigger.exchange = [DCExchangeEntity exchangeForName:exchangeName inContext:context];
                    }
                    NSString *marketName = triggerToAdd[@"market"];
                    trigger.marketNamed = marketName;
                    trigger.market = [DCMarketEntity marketForName:marketName inContext:context];
                }
                NSArray *deleteTriggerIdentifiers = [knownTriggerIdentifierKeys arrayByRemovingObjectsFromArray:triggerIdentifierKeys];
                for (NSString *identifier in deleteTriggerIdentifiers) {
                    DCTriggerEntity *trigger = [knownTriggerIdentifiers objectForKey:identifier];
                    [context deleteObject:trigger];
                }

                context.automaticallyMergesChangesFromParent = YES;
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
                [context dc_saveIfNeeded];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(YES);
                    }
                });
            }];
        }
        else {
            if (completion) {
                completion(NO);
            }
        }
    }];
}

- (id<HTTPLoaderOperationProtocol>)postTrigger:(DCTrigger *)trigger completion:(void (^)(NSError *_Nullable error))completion {
    NSString *urlString = [API_BASE_URL stringByAppendingString:@"trigger"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *parameters = @{
        @"value" : trigger.value,
        @"type" : [DCTrigger networkStringForType:trigger.type],
        @"market" : trigger.market,
        @"exchange" : trigger.exchange ?: @"any",
        @"standardize_tether" : @(trigger.standardizeTether),
    };

    HTTPRequest *request = [HTTPRequest requestWithURL:url method:HTTPRequestMethod_POST parameters:parameters];
    return [self sendAuthorizedRequest:request completion:^(id _Nullable parsedData, NSDictionary *_Nullable responseHeaders, NSInteger statusCode, NSError *_Nullable error) {
        if ([parsedData isKindOfClass:NSDictionary.class]) {
            NSPersistentContainer *container = self.stack.persistentContainer;
            [container performBackgroundTask:^(NSManagedObjectContext *context) {
                NSDictionary *dictionary = (NSDictionary *)parsedData;
                DCTriggerEntity *trigger = [[DCTriggerEntity alloc] initWithContext:context];
                trigger.identifier = [dictionary[@"identifier"] unsignedLongLongValue];
                trigger.value = [dictionary [@"value"] doubleValue];
                trigger.type = [DCTrigger typeForNetworkString:dictionary[@"type"]];
                trigger.ignoreFor = [dictionary [@"ignoreFor"] unsignedLongLongValue];
                NSString *marketName = dictionary[@"market"];
                trigger.marketNamed = marketName;
                trigger.market = [DCMarketEntity marketForName:marketName inContext:context];
                NSString *exchangeName = dictionary [@"exchange"];
                if (![exchangeName isEqualToString:@"any"]) {
                    trigger.exchangeNamed = exchangeName;
                    trigger.exchange = [DCExchangeEntity exchangeForName:exchangeName inContext:context];
                }
                
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
                [context dc_saveIfNeeded];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(nil);
                    }
                });
            }];
        }
        else {
            if (completion) {
                completion(error);
            }
        }
    }];
}

- (id<HTTPLoaderOperationProtocol>)deleteTriggerWithId:(u_int64_t)triggerId completion:(void (^_Nullable)(NSError *_Nullable error))completion {
    NSString *triggerIdParam = [NSString stringWithFormat:@"/%llu", triggerId];
    NSString *urlString = [[API_BASE_URL stringByAppendingString:@"trigger"] stringByAppendingString:triggerIdParam];
    NSURL *url = [NSURL URLWithString:urlString];

    HTTPRequest *request = [HTTPRequest requestWithURL:url method:HTTPRequestMethod_DELETE parameters:nil];
    return [self sendAuthorizedRequest:request completion:^(id _Nullable parsedData, NSDictionary *_Nullable responseHeaders, NSInteger statusCode, NSError *_Nullable error) {
        if (error) {
            if (completion) {
                completion(error);
            }
        }
        else {
            NSPersistentContainer *container = self.stack.persistentContainer;
            [container performBackgroundTask:^(NSManagedObjectContext *context) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %llu", triggerId];
                DCTriggerEntity *trigger = [DCTriggerEntity dc_objectWithPredicate:predicate inContext:context];
                if (trigger) {
                    [context deleteObject:trigger];
                }
                
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
                [context dc_saveIfNeeded];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(nil);
                    }
                });
            }];
        }
    }];
}

#pragma mark - Private

- (id<HTTPLoaderOperationProtocol>)sendAuthorizedRequest:(HTTPRequest *)request completion:(HTTPLoaderCompletionBlock)completion {
    NSString *username = [[DCEnvironment sharedInstance] deviceId];
    NSString *password = [[DCEnvironment sharedInstance] devicePassword];
    NSData *basicAuthCredentials = [[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [basicAuthCredentials base64EncodedStringWithOptions:kNilOptions];
    [request addValue:[NSString stringWithFormat:@"Basic %@", base64AuthCredentials] forHeader:@"Authorization"];
    return [self.httpManager sendRequest:request completion:completion];
}

@end

NS_ASSUME_NONNULL_END