/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>

#import <Foundation/Foundation.h>

/**
 * These block types can be used for mapping input event handlers from JS to view
 * properties. Unlike JS method callbacks, these can be called multiple times.
 */
typedef void (^RCTDirectEventBlock)(NSDictionary *body);
typedef void (^RCTBubblingEventBlock)(NSDictionary *body);

/**
 * Logical node in a tree of application components. Both `ShadowView` and
 * `UIView` conforms to this. Allows us to write utilities that reason about
 * trees generally.
 */
@protocol RCTComponent <NSObject>

@property (nonatomic, copy) NSNumber *reactTag;
@property (nonatomic, copy) NSNumber *rootTag;
@property (nonatomic, copy) NSString *viewName;
@property (nonatomic, copy) NSDictionary *props;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, weak) id <RCTComponent> parent;

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex;
- (void)removeReactSubview:(id<RCTComponent>)subview;
- (void)reactSetFrame:(CGRect)frame;
- (NSArray<id<RCTComponent>> *)reactSubviews;
- (id<RCTComponent>)reactSuperview;
- (NSNumber *)reactTagAtPoint:(CGPoint)point;

// View/ShadowView is a root view
- (BOOL)isReactRootView;

@optional

/**
 * Called each time props have been set.
 * Not all props have to be set - React can set only changed ones.
 * @param changedProps String names of all set props.
 */
- (void)didSetProps:(NSArray<NSString *> *)changedProps;

/**
 * Called each time subviews have been updated
 */
- (void)didUpdateReactSubviews;

// TODO: Deprecate this
// This method is called after layout has been performed for all views known
// to the RCTViewManager. It is only called on UIViews, not shadow views.
- (void)reactBridgeDidFinishTransaction;

@end

// TODO: this is kinda dumb - let's come up with a
// better way of identifying root React views please!
static inline BOOL RCTIsReactRootView(NSNumber *reactTag)
{
    return reactTag.integerValue % 10 == 0;
}
