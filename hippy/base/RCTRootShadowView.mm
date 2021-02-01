/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTRootShadowView.h"
#include "MTTLayout.h"
@implementation RCTRootShadowView

/**
 * Init the RCTRootShadowView with RTL status.
 * Returns a RTL CSS layout if isRTL is true (Default is LTR CSS layout).
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)applySizeConstraints
{
    switch (_sizeFlexibility) {
        case RCTRootViewSizeFlexibilityNone:
            break;
        case RCTRootViewSizeFlexibilityWidth:
            MTTNodeStyleSetWidth(self.nodeRef, NAN);
            break;
        case RCTRootViewSizeFlexibilityHeight:
            MTTNodeStyleSetHeight(self.nodeRef, NAN);
            break;
        case RCTRootViewSizeFlexibilityWidthAndHeight:
            MTTNodeStyleSetWidth(self.nodeRef, NAN);
            MTTNodeStyleSetHeight(self.nodeRef, NAN);
            break;
    }
}

- (NSSet<RCTShadowView *> *)collectViewsWithUpdatedFrames
{
    [self applySizeConstraints];
    MTTNodeDoLayout(self.nodeRef, NAN, NAN);
    
    NSMutableSet<RCTShadowView *> *viewsWithNewFrame = [NSMutableSet set];
    [self applyLayoutNode:self.nodeRef viewsWithNewFrame:viewsWithNewFrame absolutePosition:CGPointZero];
    return viewsWithNewFrame;
}

@end
