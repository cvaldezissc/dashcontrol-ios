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

#import "IntrinsicTextView.h"

@implementation IntrinsicTextView

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!CGSizeEqualToSize(self.bounds.size, [self intrinsicContentSize])) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = self.contentSize;
    intrinsicContentSize.width += (self.textContainerInset.left + self.textContainerInset.right) / 2.0;
    intrinsicContentSize.height += (self.textContainerInset.top + self.textContainerInset.bottom) / 2.0;
    return intrinsicContentSize;
}

@end
