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

#import <UIKit/UIKit.h>

#import "BaseFormCellModel.h"
#import "NamedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class FormTableViewController;
@class SelectorFormCellModel;

@protocol FormTableViewControllerDelegate <NSObject>

- (nullable NSArray<id<NamedObject>> *)formTableViewController:(FormTableViewController *)controller
                                   availableValuesForCellModel:(SelectorFormCellModel *)cellModel;
- (void)formTableViewController:(FormTableViewController *)controller
                    selectValue:(id<NamedObject>)value
                      forCellModel:(SelectorFormCellModel *)cellModel;

- (NSInteger)formTableViewControllerIndexOfInvalidDetail:(FormTableViewController *)controller;
- (void)formTableViewControllerDone:(FormTableViewController *)controller;

@end

@interface FormTableViewController : UITableViewController

@property (nullable, strong, nonatomic) NSArray<BaseFormCellModel *> *items;
@property (nullable, weak, nonatomic) id<FormTableViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
