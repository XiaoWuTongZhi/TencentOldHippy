/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "RCTInvalidating.h"

#import "RCTView.h"


@class RCTBridge;
@class RCTTouchHandler;
@class RCTModalHostViewController;

@protocol RCTModalHostViewInteractor;

@interface RCTModalHostView : UIView <RCTInvalidating>

@property (nonatomic, copy) NSString *animationType;
@property (nonatomic, copy) NSString *primaryKey;
@property (nonatomic, assign, getter=isTransparent) BOOL transparent;
@property (nonatomic, assign) BOOL darkStatusBarText;

@property (nonatomic, copy) RCTDirectEventBlock onShow;
@property (nonatomic, copy) RCTDirectEventBlock onRequestClose;

@property (nonatomic, weak) id<RCTModalHostViewInteractor, UIViewControllerTransitioningDelegate> delegate;

@property (nonatomic, strong) NSArray<NSString *> *supportedOrientations;
@property (nonatomic, copy) RCTDirectEventBlock onOrientationChange;
@property (nonatomic, strong) NSNumber *hideStatusBar;
@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, assign) BOOL isPresented;
@property (nonatomic, strong) RCTModalHostViewController *modalViewController;
@property (nonatomic, strong) RCTTouchHandler *touchHandler;

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;
- (void)notifyForBoundsChange:(CGRect)newBounds;
@end

