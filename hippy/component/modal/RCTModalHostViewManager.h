/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTViewManager.h"
#import "RCTModalHostView.h"
#import "RCTInvalidating.h"

#define RCTModalHostViewDismissNotification     @"RCTModalHostViewDismissNotification"
@protocol RCTModalHostViewInteractor;
typedef void (^RCTModalViewInteractionBlock)(UIViewController *reactViewController, UIViewController *viewController, BOOL animated, dispatch_block_t completionBlock);

@interface RCTModalHostViewManager : RCTViewManager <RCTInvalidating>
@property (nonatomic, strong) NSHashTable *hostViews;
@property (nonatomic, strong) id<RCTModalHostViewInteractor, UIViewControllerTransitioningDelegate> transitioningDelegate;

@end


