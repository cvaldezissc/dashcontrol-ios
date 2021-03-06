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

#import "DCPersistenceStack.h"

#import "NSData+Hash.h"
#import "NSManagedObjectContext+DCExtensions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Generates unique database name per iCloud user or uses "default" if not available
 */
static NSURL *StoreURL() {
    id token = [NSFileManager defaultManager].ubiquityIdentityToken;
    NSData *tokenData = nil;
    if (token) {
        tokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
    }
    else {
        tokenData = [@"default" dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSString *fileName = [tokenData SHA1String];
    NSString *fullFileName = [fileName stringByAppendingPathExtension:@"db"];
    NSURL *directoryURL = [NSPersistentContainer defaultDirectoryURL];
    NSURL *storeURL = [directoryURL URLByAppendingPathComponent:fullFileName];

    return storeURL;
}

@interface DCPersistenceStack ()

@property (strong, nonatomic) NSURL *storeURL;

@end

@implementation DCPersistenceStack

- (instancetype)init {
    self = [super init];
    if (self) {
        _storeURL = StoreURL();

        NSPersistentStoreDescription *storeDescription = [[NSPersistentStoreDescription alloc] initWithURL:_storeURL];
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"DashControl"];
        _persistentContainer.persistentStoreDescriptions = @[ storeDescription ];
    }

    return self;
}

- (void)loadStack:(void (^_Nullable)(DCPersistenceStack *stack))completion {
    [self loadStack:completion cleanStart:NO];
}

#pragma mark Private

- (void)loadStack:(void (^_Nullable)(DCPersistenceStack *stack))completion cleanStart:(BOOL)cleanStart {
    weakify;
    [self.persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *_Nullable error) {
        strongify;

        if (error != nil) {
            DCDebugLog([self class], error);
            
            if (cleanStart) {
                // TODO: handle more gently

                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */

                abort();
            }

            // remove existing database
            NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:nil];
            NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
            [psc destroyPersistentStoreAtURL:self.storeURL withType:NSSQLiteStoreType options:nil error:nil];

            // try again
            [self loadStack:completion cleanStart:YES];
        }
        else {
            self.persistentContainer.viewContext.undoManager = nil;
            self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
            self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = YES;

            if (completion) {
                RunOnMainThread(^{
                    completion(self);
                });
            }
        }
    }];
}

- (void)saveViewContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    [context dc_saveIfNeeded];
}

@end

NS_ASSUME_NONNULL_END
