/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIView+React.h"

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTLog.h"
#import "RCTShadowView.h"
#import "RCTVirtualNode.h"

@interface RNWeakObject : NSObject
@property (nonatomic, weak) id <RCTComponent> parent;
@end

@implementation RNWeakObject

@end

#define RCTEventMethod(name, value, type) \
- (void)set##name:(type)value \
{ \
objc_setAssociatedObject(self, @selector(value), value, OBJC_ASSOCIATION_COPY_NONATOMIC);\
} \
- (type)value \
{ \
return objc_getAssociatedObject(self, _cmd); \
}

@implementation UIView (React)

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)rootTag
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setRootTag:(NSNumber *)rootTag
{
	objc_setAssociatedObject(self, @selector(rootTag), rootTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)onInterceptTouchEvent
{
	return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setOnInterceptTouchEvent:(BOOL)onInterceptTouchEvent
{
	objc_setAssociatedObject(self, @selector(onInterceptTouchEvent), @(onInterceptTouchEvent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)props
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setProps:(NSDictionary *)props
{
	objc_setAssociatedObject(self, @selector(props), props, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)viewName
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setViewName:(NSString *)viewName
{
	objc_setAssociatedObject(self, @selector(viewName),viewName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setParent:(id<RCTComponent>)parent
{
	RNWeakObject *object = [[RNWeakObject alloc] init];
	object.parent = parent;
	objc_setAssociatedObject(self, @selector(parent), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<RCTComponent>)parent
{
	RNWeakObject *object = objc_getAssociatedObject(self, @selector(parent));
	return object.parent;
}

RCTEventMethod(OnClick, onClick, RCTDirectEventBlock)
RCTEventMethod(OnPressIn, onPressIn, RCTDirectEventBlock)
RCTEventMethod(OnPressOut, onPressOut, RCTDirectEventBlock)
RCTEventMethod(OnLongClick, onLongClick, RCTDirectEventBlock)

RCTEventMethod(OnTouchDown, onTouchDown, RCTDirectEventBlock)
RCTEventMethod(OnTouchMove, onTouchMove, RCTDirectEventBlock)
RCTEventMethod(OnTouchCancel, onTouchCancel, RCTDirectEventBlock)
RCTEventMethod(OnTouchEnd, onTouchEnd, RCTDirectEventBlock)
RCTEventMethod(OnAttachedToWindow, onAttachedToWindow, RCTDirectEventBlock)
RCTEventMethod(OnDetachedFromWindow, onDetachedFromWindow, RCTDirectEventBlock)

#if RCT_DEV

- (RCTShadowView *)_DEBUG_reactShadowView
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)_DEBUG_setReactShadowView:(RCTShadowView *)shadowView
{
  // Use assign to avoid keeping the shadowView alive it if no longer exists
  objc_setAssociatedObject(self, @selector(_DEBUG_reactShadowView), shadowView, OBJC_ASSOCIATION_ASSIGN);
}

#endif

- (void)sendAttachedToWindowEvent
{
  if (self.onAttachedToWindow)
  {
    self.onAttachedToWindow(nil);
  }
}

- (void)sendDetachedFromWindowEvent
{
  if (self.onDetachedFromWindow)
  {
    self.onDetachedFromWindow(nil);
  }
}

- (BOOL)isReactRootView
{
  return RCTIsReactRootView(self.reactTag);
}

- (NSNumber *)reactTagAtPoint:(CGPoint)point
{
  UIView *view = [self hitTest:point withEvent:nil];
  while (view && !view.reactTag) {
    view = view.superview;
  }
  return view.reactTag;
}

- (NSArray<UIView *> *)reactSubviews
{
  return objc_getAssociatedObject(self, _cmd);
}

- (UIView *)reactSuperview
{
  return self.superview;
}

- (void)insertReactSubview:(UIView *)subview atIndex:(NSInteger)atIndex
{
  // We access the associated object directly here in case someone overrides
  // the `reactSubviews` getter method and returns an immutable array.
  NSMutableArray *subviews = objc_getAssociatedObject(self, @selector(reactSubviews));
  if (!subviews) {
    subviews = [NSMutableArray new];
    objc_setAssociatedObject(self, @selector(reactSubviews), subviews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  
#if !RCT_DEV
  if ((NSInteger)subviews.count >= atIndex)
  {
#endif
    [subviews insertObject:subview atIndex:atIndex];
#if !RCT_DEV
  }
#endif
}

- (void)removeReactSubview:(UIView *)subview
{
  // We access the associated object directly here in case someone overrides
  // the `reactSubviews` getter method and returns an immutable array.
  NSMutableArray *subviews = objc_getAssociatedObject(self, @selector(reactSubviews));
  [subviews removeObject:subview];
  [subview sendDetachedFromWindowEvent];
  [subview removeFromSuperview];
}

- (NSInteger)reactZIndex
{
  return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setReactZIndex:(NSInteger)reactZIndex
{
  objc_setAssociatedObject(self, @selector(reactZIndex), @(reactZIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<UIView *> *)sortedReactSubviews
{
  NSArray *subviews = objc_getAssociatedObject(self, _cmd);
  if (!subviews) {
    // Check if sorting is required - in most cases it won't be
    BOOL sortingRequired = NO;
    for (UIView *subview in self.reactSubviews) {
      if (subview.reactZIndex != 0) {
        sortingRequired = YES;
        break;
      }
    }
    subviews = sortingRequired ? [self.reactSubviews sortedArrayUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
      if (a.reactZIndex > b.reactZIndex) {
        return NSOrderedDescending;
      } else {
        // ensure sorting is stable by treating equal zIndex as ascending so
        // that original order is preserved
        return NSOrderedAscending;
      }
    }] : self.reactSubviews;
    objc_setAssociatedObject(self, _cmd, subviews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return subviews;
}

// private method, used to reset sort
- (void)clearSortedSubviews
{
  objc_setAssociatedObject(self, @selector(sortedReactSubviews), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)didUpdateReactSubviews
{
  for (UIView *subview in self.sortedReactSubviews) {
    if (subview.superview != self)
    {
      [subview sendAttachedToWindowEvent];
    }
    
    [self addSubview:subview];
  }
}

- (void)reactSetFrame:(CGRect)frame
{
  // These frames are in terms of anchorPoint = topLeft, but internally the
  // views are anchorPoint = center for easier scale and rotation animations.
  // Convert the frame so it works with anchorPoint = center.
  CGPoint position = {CGRectGetMidX(frame), CGRectGetMidY(frame)};
  CGRect bounds = {CGPointZero, frame.size};

  // Avoid crashes due to nan coords
  if (isnan(position.x) || isnan(position.y) ||
      isnan(bounds.origin.x) || isnan(bounds.origin.y) ||
      isnan(bounds.size.width) || isnan(bounds.size.height)) {
    RCTLogError(@"Invalid layout for (%@)%@. position: %@. bounds: %@",
                self.reactTag, self, NSStringFromCGPoint(position), NSStringFromCGRect(bounds));
    return;
  }

//  self.center = position;
//  self.bounds = bounds;
	
	self.frame = frame;
}

- (void)didUpdateWithNode:(__unused RCTVirtualNode *)node
{
	
}

- (void)reactSetInheritedBackgroundColor:(__unused UIColor *)inheritedBackgroundColor
{
  // Does nothing by default
}

- (UIViewController *)reactViewController
{
  id responder = [self nextResponder];
  while (responder) {
    if ([responder isKindOfClass:[UIViewController class]]) {
      return responder;
    }
    responder = [responder nextResponder];
  }
  return nil;
}

- (void)reactAddControllerToClosestParent:(UIViewController *)controller
{
  if (!controller.parentViewController) {
    UIView *parentView = (UIView *)self.reactSuperview;
    while (parentView) {
      if (parentView.reactViewController) {
        [parentView.reactViewController addChildViewController:controller];
        [controller didMoveToParentViewController:parentView.reactViewController];
        break;
      }
      parentView = (UIView *)parentView.reactSuperview;
    }
    return;
  }
}

- (BOOL)interceptTouchEvent
{
    return NO;
}

/**
 * Responder overrides - to be deprecated.
 */
- (void)reactWillMakeFirstResponder {};
- (void)reactDidMakeFirstResponder {};
- (BOOL)reactRespondsToTouch:(__unused UITouch *)touch
{
  return YES;
}

@end
