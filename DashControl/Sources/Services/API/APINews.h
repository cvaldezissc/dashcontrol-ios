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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSInteger const APINEWS_PAGE_SIZE;

@class HTTPLoaderManager;
@class DCPersistenceStack;
@protocol HTTPLoaderOperationProtocol;

@interface APINews : NSObject

@property (strong, nonatomic) InjectedClass(DCPersistenceStack) stack;
@property (strong, nonatomic) InjectedClass(HTTPLoaderManager) httpManager;

@property (readonly, copy, nonatomic) NSString *langCode;

- (id<HTTPLoaderOperationProtocol>)fetchNewsForPage:(NSInteger)page completion:(void(^)(BOOL success, BOOL isLastPage))completion;

@end

NS_ASSUME_NONNULL_END
