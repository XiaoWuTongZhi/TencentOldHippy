/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTViewManager.h"

#import "RCTBridge.h"
#import "RCTBorderStyle.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTShadowView.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "UIView+React.h"
#import "RCTVirtualNode.h"
#import "RCTConvert+Transform.h"

@implementation RCTViewManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(View)

- (dispatch_queue_t)methodQueue
{
  return RCTGetUIManagerQueue();
}

- (UIView *)view
{
  return [RCTView new];
}

- (RCTShadowView *)shadowView
{
  return [RCTShadowView new];
}

- (RCTVirtualNode *)node:(NSNumber *)tag name:(NSString *)name props:(NSDictionary *)props
{
	return [RCTVirtualNode createNode: tag viewName: name props: props];
}

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(__unused RCTShadowView *)shadowView
{
  return nil;
}

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowViewRegistry:(__unused NSDictionary<NSNumber *, RCTShadowView *> *)shadowViewRegistry
{
  return nil;
}

#pragma mark - View properties

RCT_EXPORT_VIEW_PROPERTY(accessibilityLabel, NSString)
RCT_EXPORT_VIEW_PROPERTY(backgroundColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(shadowSpread, CGFloat)

RCT_REMAP_VIEW_PROPERTY(accessible, isAccessibilityElement, BOOL)
RCT_REMAP_VIEW_PROPERTY(opacity, alpha, CGFloat)

RCT_REMAP_VIEW_PROPERTY(backgroundImage, backgroundImageUrl, NSString)

RCT_REMAP_VIEW_PROPERTY(shadowOpacity, layer.shadowOpacity, float)
RCT_REMAP_VIEW_PROPERTY(shadowRadius, layer.shadowRadius, CGFloat)

RCT_EXPORT_VIEW_PROPERTY(backgroundPositionX, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(backgroundPositionY, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(onInterceptTouchEvent, BOOL)

RCT_CUSTOM_VIEW_PROPERTY(shadowColor, UIColor, RCTView) {
    if (json) {
        view.layer.shadowColor = [RCTConvert UIColor:json].CGColor;
    }
    else {
        view.layer.shadowColor = [UIColor blackColor].CGColor;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(shadowOffsetX, CGFloat, RCTView) {
    if (json) {
        CGSize shadowOffset = view.layer.shadowOffset;
        shadowOffset.width = [RCTConvert CGFloat:json];
        view.layer.shadowOffset = shadowOffset;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(shadowOffsetY, CGFloat, RCTView) {
    if (json) {
        CGSize shadowOffset = view.layer.shadowOffset;
        shadowOffset.height = [RCTConvert CGFloat:json];
        view.layer.shadowOffset = shadowOffset;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(shadowOffset, NSDictionary, RCTView) {
    if (json) {
        NSDictionary *offset = [RCTConvert NSDictionary:json];
        NSNumber *width = offset[@"width"];
        if (nil == width) {
            width = offset[@"x"];
        }
        NSNumber *height = offset[@"height"];
        if (nil == height) {
            height = offset[@"y"];
        }
        view.layer.shadowOffset = CGSizeMake([width floatValue], [height floatValue]);
    }
}

RCT_CUSTOM_VIEW_PROPERTY(overflow, OverflowType, RCTView)
{
  if (json) {
    view.clipsToBounds = [RCTConvert OverflowType:json] != OverflowVisible;
  } else {
    view.clipsToBounds = defaultView.clipsToBounds;
  }
}
RCT_CUSTOM_VIEW_PROPERTY(shouldRasterizeIOS, BOOL, RCTView)
{
  view.layer.shouldRasterize = json ? [RCTConvert BOOL:json] : defaultView.layer.shouldRasterize;
  view.layer.rasterizationScale = view.layer.shouldRasterize ? [UIScreen mainScreen].scale : defaultView.layer.rasterizationScale;
}

RCT_CUSTOM_VIEW_PROPERTY(transform, CATransform3D, RCTView)
{
  view.layer.transform = json ? [RCTConvert CATransform3D:json] : defaultView.layer.transform;
  // TODO: Improve this by enabling edge antialiasing only for transforms with rotation or skewing
  view.layer.allowsEdgeAntialiasing = !CATransform3DIsIdentity(view.layer.transform);
}
RCT_CUSTOM_VIEW_PROPERTY(pointerEvents, RCTPointerEvents, RCTView)
{
  if ([view respondsToSelector:@selector(setPointerEvents:)]) {
    view.pointerEvents = json ? [RCTConvert RCTPointerEvents:json] : defaultView.pointerEvents;
    return;
  }

  if (!json) {
    view.userInteractionEnabled = defaultView.userInteractionEnabled;
    return;
  }

  switch ([RCTConvert RCTPointerEvents:json]) {
    case RCTPointerEventsUnspecified:
      // Pointer events "unspecified" acts as if a stylesheet had not specified,
      // which is different than "auto" in CSS (which cannot and will not be
      // supported in `React`. "auto" may override a parent's "none".
      // Unspecified values do not.
      // This wouldn't override a container view's `userInteractionEnabled = NO`
      view.userInteractionEnabled = YES;
    case RCTPointerEventsNone:
      view.userInteractionEnabled = NO;
      break;
    default:
      RCTLogError(@"UIView base class does not support pointerEvent value: %@", json);
  }
}

RCT_CUSTOM_VIEW_PROPERTY(borderRadius, CGFloat, RCTView) {
  if ([view respondsToSelector:@selector(setBorderRadius:)]) {
    view.borderRadius = json ? [RCTConvert CGFloat:json] : defaultView.borderRadius;
  } else {
    view.layer.cornerRadius = json ? [RCTConvert CGFloat:json] : defaultView.layer.cornerRadius;
  }
}
RCT_CUSTOM_VIEW_PROPERTY(borderColor, CGColor, RCTView)
{
  if ([view respondsToSelector:@selector(setBorderColor:)]) {
    view.borderColor = json ? [RCTConvert CGColor:json] : defaultView.borderColor;
  } else {
    view.layer.borderColor = json ? [RCTConvert CGColor:json] : defaultView.layer.borderColor;
  }
}

RCT_CUSTOM_VIEW_PROPERTY(borderWidth, CGFloat, RCTView)
{
  if ([view respondsToSelector:@selector(setBorderWidth:)]) {
    view.borderWidth = json ? [RCTConvert CGFloat:json] : defaultView.borderWidth;
  } else {
    view.layer.borderWidth = json ? [RCTConvert CGFloat:json] : defaultView.layer.borderWidth;
  }
}
RCT_CUSTOM_VIEW_PROPERTY(borderStyle, RCTBorderStyle, RCTView)
{
  if ([view respondsToSelector:@selector(setBorderStyle:)]) {
    view.borderStyle = json ? [RCTConvert RCTBorderStyle:json] : defaultView.borderStyle;
  }
}

#define RCT_VIEW_BORDER_PROPERTY(SIDE)                                  \
RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Width, CGFloat, RCTView)         \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Width:)]) {   \
    view.border##SIDE##Width = json ? [RCTConvert CGFloat:json] : defaultView.border##SIDE##Width; \
  }                                                                     \
}                                                                       \
RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Color, UIColor, RCTView)         \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Color:)]) {   \
    view.border##SIDE##Color = json ? [RCTConvert CGColor:json] : defaultView.border##SIDE##Color; \
  }                                                                     \
}                                                                       \

RCT_VIEW_BORDER_PROPERTY(Top)
RCT_VIEW_BORDER_PROPERTY(Right)
RCT_VIEW_BORDER_PROPERTY(Bottom)
RCT_VIEW_BORDER_PROPERTY(Left)

#define RCT_VIEW_BORDER_RADIUS_PROPERTY(SIDE)                           \
RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Radius, CGFloat, RCTView)        \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Radius:)]) {  \
    view.border##SIDE##Radius = json ? [RCTConvert CGFloat:json] : defaultView.border##SIDE##Radius; \
  }                                                                     \
}                                                                       \

RCT_VIEW_BORDER_RADIUS_PROPERTY(TopLeft)
RCT_VIEW_BORDER_RADIUS_PROPERTY(TopRight)
RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomLeft)
RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomRight)

RCT_REMAP_VIEW_PROPERTY(zIndex, reactZIndex, NSInteger)

#pragma mark - ShadowView properties

RCT_EXPORT_SHADOW_PROPERTY(backgroundColor, UIColor)

RCT_EXPORT_SHADOW_PROPERTY(top, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(right, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(bottom, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(left, CGFloat);

RCT_EXPORT_SHADOW_PROPERTY(width, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(height, CGFloat)

RCT_EXPORT_SHADOW_PROPERTY(minWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(maxWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(minHeight, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(maxHeight, CGFloat)

RCT_EXPORT_SHADOW_PROPERTY(borderTopWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(borderRightWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(borderBottomWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(borderLeftWidth, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(borderWidth, CGFloat)

RCT_EXPORT_SHADOW_PROPERTY(marginTop, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(marginRight, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(marginBottom, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(marginLeft, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(marginVertical, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(marginHorizontal, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(margin, CGFloat)

RCT_EXPORT_SHADOW_PROPERTY(paddingTop, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(paddingRight, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(paddingBottom, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(paddingLeft, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(paddingVertical, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(paddingHorizontal, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(padding, CGFloat)

RCT_EXPORT_SHADOW_PROPERTY(flex, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(flexGrow, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(flexShrink, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(flexBasis, CGFloat)

//hplayout
RCT_EXPORT_SHADOW_PROPERTY(flexDirection, FlexDirection)
RCT_EXPORT_SHADOW_PROPERTY(flexWrap, FlexWrapMode)
RCT_EXPORT_SHADOW_PROPERTY(justifyContent, FlexAlign)
RCT_EXPORT_SHADOW_PROPERTY(alignItems, FlexAlign)
RCT_EXPORT_SHADOW_PROPERTY(alignSelf, FlexAlign)
RCT_EXPORT_SHADOW_PROPERTY(position, PositionType)

RCT_REMAP_SHADOW_PROPERTY(display, displayType, DisplayType)

RCT_EXPORT_SHADOW_PROPERTY(overflow, OverflowType)


RCT_EXPORT_SHADOW_PROPERTY(onLayout, RCTDirectEventBlock)


RCT_EXPORT_VIEW_PROPERTY(onClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLongClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPressIn, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPressOut, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTouchDown, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTouchMove, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTouchEnd, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTouchCancel, RCTDirectEventBlock)


RCT_EXPORT_SHADOW_PROPERTY(zIndex, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(onAttachedToWindow, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDetachedFromWindow, RCTDirectEventBlock)

@end

#import <objc/runtime.h>

static const char* init_props_identifier = "init_props_identifier";

@implementation RCTViewManager(InitProps)

- (NSDictionary *)props
{
  return objc_getAssociatedObject(self, init_props_identifier);
}

- (void)setProps:(NSDictionary *)props
{
  if (props == nil) {
    return;
  }
  
  objc_setAssociatedObject(self, init_props_identifier, props, OBJC_ASSOCIATION_RETAIN);
}
@end
