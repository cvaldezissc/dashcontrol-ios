//
//  HTTPLoaderManager.m
//  DashPriceViewer
//
//  Created by Andrew Podkovyrin on 08/02/2018.
//  Copyright © 2018 Andrew Podkovyrin. All rights reserved.
//

#import "HTTPLoaderManager.h"

#import "HTTPLoaderOperation.h"
#import "HTTPLoaderFactory.h"
#import "HTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTTPLoaderManager ()

@property (strong, nonatomic) HTTPLoaderFactory *factory;

@end

@implementation HTTPLoaderManager

- (instancetype)initWithFactory:(HTTPLoaderFactory *)factory {
    self = [super init];
    if (self) {
        _factory = factory;
    }

    return self;
}

- (id<HTTPLoaderOperationProtocol>)sendRequest:(HTTPRequest *)httpRequest completion:(HTTPLoaderCompletionBlock)completion {
    return [self sendRequest:httpRequest factory:self.factory completion:completion];
}

- (id<HTTPLoaderOperationProtocol>)sendRequest:(HTTPRequest *)httpRequest rawCompletion:(HTTPLoaderRawCompletionBlock)rawCompletion {
    return [self sendRequest:httpRequest factory:self.factory rawCompletion:rawCompletion];
}

- (id<HTTPLoaderOperationProtocol>)sendRequest:(HTTPRequest *)httpRequest
                                       factory:(HTTPLoaderFactory *)factory
                                    completion:(HTTPLoaderCompletionBlock)completion {
    return [self sendRequest:httpRequest factory:factory rawCompletion:^(BOOL success, BOOL cancelled, HTTPResponse *_Nullable response) {
        NSAssert([NSThread isMainThread], nil);
        
        if (success) {
            NSError *_Nullable error = nil;
            id _Nullable parsedData = [self parseResponse:response.body statusCode:response.statusCode error:&error];
            NSAssert((!error && parsedData) || (error && !parsedData), nil); // sanity check

            if (completion) {
                completion(parsedData, response.responseHeaders, response.statusCode, error ?: response.error);
            }
        }
        else {
            if (completion) {
                if (cancelled) {
                    completion(nil, nil, HTTPResponseStatusCode_Invalid, [NSError errorWithDomain:NSURLErrorDomain
                                                                                             code:NSURLErrorCancelled
                                                                                         userInfo:nil]);
                }
                else {
                    completion(nil, response.responseHeaders, response.statusCode, response.error);
                }
            }
        }

    }];
}

- (id<HTTPLoaderOperationProtocol>)sendRequest:(HTTPRequest *)httpRequest
                                       factory:(HTTPLoaderFactory *)factory
                                 rawCompletion:(HTTPLoaderRawCompletionBlock)rawCompletion {
    HTTPLoaderOperation *operation = [[HTTPLoaderOperation alloc] initWithHTTPRequest:httpRequest httpLoaderFactory:factory];
    [operation performWithCompletion:rawCompletion];
    return operation;
}

#pragma mark Private

- (nullable id)parseResponse:(nullable NSData *)data statusCode:(NSInteger)statusCode error:(NSError *__autoreleasing *)error {
    NSError *statusCodeError = nil;
    if (statusCode < 200 || statusCode > 300) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSHTTPURLResponse localizedStringForStatusCode:statusCode]};
        statusCodeError = [NSError errorWithDomain:HTTPResponseErrorDomain
                                              code:statusCode
                                          userInfo:userInfo];
    }
    
    if (!data) {
        if (error) {
            *error = statusCodeError;
        }
        
        return nil;
    }
    
    NSError *parseError = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingAllowFragments
                                                             error:&parseError];
    if (parseError) {
        if (error) {
            *error = parseError;
        }
        
        return nil;
    }
    
    return parsed;
}

@end

NS_ASSUME_NONNULL_END