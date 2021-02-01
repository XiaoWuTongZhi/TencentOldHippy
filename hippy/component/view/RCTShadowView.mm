/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTShadowView.h"

#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "UIView+React.h"
#import "UIView+Private.h"

static NSString *const RCTBackgroundColorProp = @"backgroundColor";

typedef NS_ENUM(unsigned int, meta_prop_t) {
  META_PROP_LEFT,
  META_PROP_TOP,
  META_PROP_RIGHT,
  META_PROP_BOTTOM,
  META_PROP_HORIZONTAL,
  META_PROP_VERTICAL,
  META_PROP_ALL,
  META_PROP_COUNT,
};

@implementation RCTShadowView
{
  RCTUpdateLifecycle _propagationLifecycle;
  RCTUpdateLifecycle _textLifecycle;
  NSDictionary *_lastParentProperties;
  NSMutableArray<RCTShadowView *> *_reactSubviews;
  BOOL _recomputePadding;
  BOOL _recomputeMargin;
  BOOL _recomputeBorder;
  BOOL _didUpdateSubviews;
  float _paddingMetaProps[META_PROP_COUNT];
  float _marginMetaProps[META_PROP_COUNT];
  float _borderMetaProps[META_PROP_COUNT];
}

@synthesize reactTag = _reactTag;
@synthesize props = _props;
@synthesize rootTag = _rootTag;
@synthesize parent = _parent;

//not used function
//static void RCTPrint(void *context)
//{
//  RCTShadowView *shadowView = (__bridge RCTShadowView *)context;
//  printf("%s(%zd), ", shadowView.viewName.UTF8String, shadowView.reactTag.integerValue);
//}
#define DEFINE_PROCESS_META_PROPS(type)                                                            \
static void RCTProcessMetaProps##type(const float metaProps[META_PROP_COUNT], MTTNodeRef node) {   \
  if (!isnan(metaProps[META_PROP_LEFT])) {                                           \
    MTTNodeStyleSet##type(node, CSSLeft, metaProps[META_PROP_LEFT]);                          \
  } else if (!isnan(metaProps[META_PROP_HORIZONTAL])) {                              \
    MTTNodeStyleSet##type(node, CSSLeft, metaProps[META_PROP_HORIZONTAL]);                    \
  } else if (!isnan(metaProps[META_PROP_ALL])) {                                     \
    MTTNodeStyleSet##type(node, CSSLeft, metaProps[META_PROP_ALL]);                           \
  } else {                                                                                         \
    MTTNodeStyleSet##type(node, CSSLeft, 0);                                                  \
  }                                                                                                \
  \
  if (!isnan(metaProps[META_PROP_RIGHT])) {                                          \
    MTTNodeStyleSet##type(node, CSSRight, metaProps[META_PROP_RIGHT]);                           \
  } else if (!isnan(metaProps[META_PROP_HORIZONTAL])) {                              \
    MTTNodeStyleSet##type(node, CSSRight, metaProps[META_PROP_HORIZONTAL]);                      \
  } else if (!isnan(metaProps[META_PROP_ALL])) {                                     \
    MTTNodeStyleSet##type(node, CSSRight, metaProps[META_PROP_ALL]);                             \
  } else {                                                                                         \
    MTTNodeStyleSet##type(node, CSSRight, 0);                                                    \
  }                                                                                                \
  \
  if (!isnan(metaProps[META_PROP_TOP])) {                                            \
    MTTNodeStyleSet##type(node, CSSTop, metaProps[META_PROP_TOP]);                             \
  } else if (!isnan(metaProps[META_PROP_VERTICAL])) {                                \
    MTTNodeStyleSet##type(node, CSSTop, metaProps[META_PROP_VERTICAL]);                        \
  } else if (!isnan(metaProps[META_PROP_ALL])) {                                     \
    MTTNodeStyleSet##type(node, CSSTop, metaProps[META_PROP_ALL]);                             \
  } else {                                                                                         \
    MTTNodeStyleSet##type(node, CSSTop, 0);                                                    \
  }                                                                                                \
  \
  if (!isnan(metaProps[META_PROP_BOTTOM])) {                                         \
    MTTNodeStyleSet##type(node, CSSBottom, metaProps[META_PROP_BOTTOM]);                       \
  } else if (!isnan(metaProps[META_PROP_VERTICAL])) {                                \
    MTTNodeStyleSet##type(node, CSSBottom, metaProps[META_PROP_VERTICAL]);                     \
  } else if (!isnan(metaProps[META_PROP_ALL])) {                                     \
    MTTNodeStyleSet##type(node, CSSBottom, metaProps[META_PROP_ALL]);                          \
  } else {                                                                                         \
    MTTNodeStyleSet##type(node, CSSBottom, 0);                                                 \
  }                                                                                                \
}

DEFINE_PROCESS_META_PROPS(Padding);
DEFINE_PROCESS_META_PROPS(Margin);
DEFINE_PROCESS_META_PROPS(Border);

// The absolute stuff is so that we can take into account our absolute position when rounding in order to
// snap to the pixel grid. For example, say you have the following structure:
//
// +--------+---------+--------+
// |        |+-------+|        |
// |        ||       ||        |
// |        |+-------+|        |
// +--------+---------+--------+
//
// Say the screen width is 320 pts so the three big views will get the following x bounds from our layout system:
// {0, 106.667}, {106.667, 213.333}, {213.333, 320}
//
// Assuming screen scale is 2, these numbers must be rounded to the nearest 0.5 to fit the pixel grid:
// {0, 106.5}, {106.5, 213.5}, {213.5, 320}
// You'll notice that the three widths are 106.5, 107, 106.5.
//
// This is great for the parent views but it gets trickier when we consider rounding for the subview.
//
// When we go to round the bounds for the subview in the middle, it's relative bounds are {0, 106.667}
// which gets rounded to {0, 106.5}. This will cause the subview to be one pixel smaller than it should be.
// this is why we need to pass in the absolute position in order to do the rounding relative to the screen's
// grid rather than the view's grid.
//
// After passing in the absolutePosition of {106.667, y}, we do the following calculations:
// absoluteLeft = round(absolutePosition.x + viewPosition.left) = round(106.667 + 0) = 106.5
// absoluteRight = round(absolutePosition.x + viewPosition.left + viewSize.left) + round(106.667 + 0 + 106.667) = 213.5
// width = 213.5 - 106.5 = 107
// You'll notice that this is the same width we calculated for the parent view because we've taken its position into account.

- (void)applyLayoutNode:(MTTNodeRef)node
      viewsWithNewFrame:(NSMutableSet<RCTShadowView *> *)viewsWithNewFrame
       absolutePosition:(CGPoint)absolutePosition
{
  if (!MTTNodeHasNewLayout(node)) {
    return;
  }
  MTTNodesetHasNewLayout(node, false);
  CGPoint absoluteTopLeft = {
    absolutePosition.x + MTTNodeLayoutGetLeft(node),
    absolutePosition.y + MTTNodeLayoutGetTop(node)
  };
  
  CGPoint absoluteBottomRight = {
    absolutePosition.x + MTTNodeLayoutGetLeft(node) + MTTNodeLayoutGetWidth(node),
    absolutePosition.y + MTTNodeLayoutGetTop(node) + MTTNodeLayoutGetHeight(node)
  };
  
  CGRect frame = {{
    ceil(RCTRoundPixelValue(MTTNodeLayoutGetLeft(node))),
    ceil(RCTRoundPixelValue(MTTNodeLayoutGetTop(node))),
  }, {
    ceil(RCTRoundPixelValue(absoluteBottomRight.x - absoluteTopLeft.x)),
    ceil(RCTRoundPixelValue(absoluteBottomRight.y - absoluteTopLeft.y))
  }};
  
  if (!CGRectEqualToRect(frame, _frame)) {
    _frame = frame;
    [viewsWithNewFrame addObject:self];
  }
  
  absolutePosition.x += MTTNodeLayoutGetLeft(node);
  absolutePosition.y += MTTNodeLayoutGetTop(node);
  
  [self applyLayoutToChildren:node viewsWithNewFrame:viewsWithNewFrame absolutePosition:absolutePosition];
}

- (void)applyLayoutToChildren:(MTTNodeRef)node
            viewsWithNewFrame:(NSMutableSet<RCTShadowView *> *)viewsWithNewFrame
             absolutePosition:(CGPoint)absolutePosition
{
  for (unsigned int i = 0; i < MTTNodeChildCount(node); ++i) {
    RCTShadowView *child = (RCTShadowView *)_reactSubviews[i];
    [child applyLayoutNode:MTTNodeGetChild(node, i)
         viewsWithNewFrame:viewsWithNewFrame
          absolutePosition:absolutePosition];
  }
}

- (NSDictionary<NSString *, id> *)processUpdatedProperties:(NSMutableSet<RCTApplierBlock> *)applierBlocks
                                          parentProperties:(NSDictionary<NSString *, id> *)parentProperties
{
  // TODO: we always refresh all propagated properties when propagation is
  // dirtied, but really we should track which properties have changed and
  // only update those.

  if (_didUpdateSubviews) {
    _didUpdateSubviews = NO;
    [self didUpdateReactSubviews];
    [applierBlocks addObject:^(NSDictionary<NSNumber *, UIView *> *viewRegistry) {
      UIView *view = viewRegistry[self->_reactTag];
      [view clearSortedSubviews];
      [view didUpdateReactSubviews];
    }];
  }

  if (!_backgroundColor) {
    UIColor *parentBackgroundColor = parentProperties[RCTBackgroundColorProp];
    if (parentBackgroundColor) {
      [applierBlocks addObject:^(NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[self->_reactTag];
        [view reactSetInheritedBackgroundColor:parentBackgroundColor];
      }];
    }
  } else {
    // Update parent properties for children
    NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionaryWithDictionary:parentProperties];
    CGFloat alpha = CGColorGetAlpha(_backgroundColor.CGColor);
    if (alpha < 1.0) {
      // If bg is non-opaque, don't propagate further
      properties[RCTBackgroundColorProp] = [UIColor clearColor];
    } else {
      properties[RCTBackgroundColorProp] = _backgroundColor;
    }
    return properties;
  }
  return parentProperties;
}

- (void)collectUpdatedProperties:(NSMutableSet<RCTApplierBlock> *)applierBlocks
                parentProperties:(NSDictionary<NSString *, id> *)parentProperties
{
  if (_propagationLifecycle == RCTUpdateLifecycleComputed && [parentProperties isEqualToDictionary:_lastParentProperties]) {
    return;
  }
  _propagationLifecycle = RCTUpdateLifecycleComputed;
  _lastParentProperties = parentProperties;
  NSDictionary<NSString *, id> *nextProps = [self processUpdatedProperties:applierBlocks parentProperties:parentProperties];
  for (RCTShadowView *child in _reactSubviews) {
    [child collectUpdatedProperties:applierBlocks parentProperties:nextProps];
  }
}

- (NSDictionary<NSString *, id> *)processUpdatedProperties:(NSMutableSet<RCTApplierBlock> *)applierBlocks
																			virtualApplierBlocks:(__unused NSMutableSet<RCTApplierVirtualBlock> *)virtualApplierBlocks
																					parentProperties:(NSDictionary<NSString *, id> *)parentProperties
{
	// TODO: we always refresh all propagated properties when propagation is
	// dirtied, but really we should track which properties have changed and
	// only update those.
	
	if (_didUpdateSubviews) {
		_didUpdateSubviews = NO;
		[self didUpdateReactSubviews];
		[applierBlocks addObject:^(NSDictionary<NSNumber *, UIView *> *viewRegistry) {
			UIView *view = viewRegistry[self->_reactTag];
			[view clearSortedSubviews];
			[view didUpdateReactSubviews];
		}];
	}
	
	if (!_backgroundColor) {
		UIColor *parentBackgroundColor = parentProperties[RCTBackgroundColorProp];
		if (parentBackgroundColor) {
			[applierBlocks addObject:^(NSDictionary<NSNumber *, UIView *> *viewRegistry) {
				UIView *view = viewRegistry[self->_reactTag];
				[view reactSetInheritedBackgroundColor:parentBackgroundColor];
			}];
		}
	} else {
		// Update parent properties for children
		NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionaryWithDictionary:parentProperties];
		CGFloat alpha = CGColorGetAlpha(_backgroundColor.CGColor);
		if (alpha < 1.0) {
			// If bg is non-opaque, don't propagate further
			properties[RCTBackgroundColorProp] = [UIColor clearColor];
		} else {
			properties[RCTBackgroundColorProp] = _backgroundColor;
		}
		return properties;
	}
	return parentProperties;
}

- (void)collectUpdatedProperties:(NSMutableSet<RCTApplierBlock> *)applierBlocks
						virtualApplierBlocks:(NSMutableSet<RCTApplierVirtualBlock> *)virtualApplierBlocks
								parentProperties:(NSDictionary<NSString *, id> *)parentProperties
{
	if (_propagationLifecycle == RCTUpdateLifecycleComputed && [parentProperties isEqualToDictionary:_lastParentProperties]) {
		return;
	}
	_propagationLifecycle = RCTUpdateLifecycleComputed;
	_lastParentProperties = parentProperties;
	NSDictionary<NSString *, id> *nextProps = [self processUpdatedProperties:applierBlocks
																											virtualApplierBlocks: virtualApplierBlocks parentProperties:parentProperties];
	for (RCTShadowView *child in _reactSubviews) {
		[child collectUpdatedProperties:applierBlocks virtualApplierBlocks:virtualApplierBlocks parentProperties:nextProps];
	}
}

- (void)collectUpdatedFrames:(NSMutableSet<RCTShadowView *> *)viewsWithNewFrame
                   withFrame:(CGRect)frame
                      hidden:(BOOL)hidden
            absolutePosition:(CGPoint)absolutePosition
{
  if (_hidden != hidden) {
    // The hidden state has changed. Even if the frame hasn't changed, add
    // this ShadowView to viewsWithNewFrame so the UIManager will process
    // this ShadowView's UIView and update its hidden state.
    _hidden = hidden;
    [viewsWithNewFrame addObject:self];
  }

  if (!CGRectEqualToRect(frame, _frame)) {
    MTTNodeStyleSetPositionType(_nodeRef, PositionTypeAbsolute);
    MTTNodeStyleSetWidth(_nodeRef, CGRectGetWidth(frame));
    MTTNodeStyleSetHeight(_nodeRef, CGRectGetHeight(frame));
    MTTNodeStyleSetPosition(_nodeRef, CSSLeft, frame.origin.x);
    MTTNodeStyleSetPosition(_nodeRef, CSSTop, frame.origin.y);
  }

//  CSSNodeCalculateLayout(_cssNode, frame.size.width, frame.size.height, CSSDirectionInherit);
  MTTNodeDoLayout(_nodeRef, frame.size.width, frame.size.height);
//  [self applyLayoutNode:_cssNode viewsWithNewFrame:viewsWithNewFrame absolutePosition:absolutePosition];
  [self applyLayoutNode:_nodeRef viewsWithNewFrame:viewsWithNewFrame absolutePosition:absolutePosition];
}

- (CGRect)measureLayoutRelativeToAncestor:(RCTShadowView *)ancestor
{
  CGPoint offset = CGPointZero;
  NSInteger depth = 30; // max depth to search
  RCTShadowView *shadowView = self;
  while (depth && shadowView && shadowView != ancestor) {
    offset.x += shadowView.frame.origin.x;
    offset.y += shadowView.frame.origin.y;
    shadowView = shadowView->_superview;
    depth--;
  }
  if (ancestor != shadowView) {
    return CGRectNull;
  }
  return (CGRect){offset, self.frame.size};
}

- (BOOL)viewIsDescendantOf:(RCTShadowView *)ancestor
{
  NSInteger depth = 30; // max depth to search
  RCTShadowView *shadowView = self;
  while (depth && shadowView && shadowView != ancestor) {
    shadowView = shadowView->_superview;
    depth--;
  }
  return ancestor == shadowView;
}

- (instancetype)init
{
  if ((self = [super init])) {

    _frame = CGRectMake(0, 0, NAN, NAN);

    for (unsigned int ii = 0; ii < META_PROP_COUNT; ii++) {
      _paddingMetaProps[ii] = NAN;
      _marginMetaProps[ii] = NAN;
      _borderMetaProps[ii] = NAN;
    }

    _newView = YES;
    _propagationLifecycle = RCTUpdateLifecycleUninitialized;
    _textLifecycle = RCTUpdateLifecycleUninitialized;

    _reactSubviews = [NSMutableArray array];

    _nodeRef = MTTNodeNew();
    MTTNodeSetContext(_nodeRef, (__bridge void *)self);
  }
  return self;
}

- (BOOL)isReactRootView
{
  return RCTIsReactRootView(self.reactTag);
}

- (void)dealloc
{
  MTTNodeFree(_nodeRef);
}

- (BOOL)isCSSLeafNode
{
  return NO;
}

- (void)dirtyPropagation
{
  if (_propagationLifecycle != RCTUpdateLifecycleDirtied) {
    _propagationLifecycle = RCTUpdateLifecycleDirtied;
    [_superview dirtyPropagation];
  }
}

- (BOOL)isPropagationDirty
{
  return _propagationLifecycle != RCTUpdateLifecycleComputed;
}

- (void)dirtyText
{
  if (_textLifecycle != RCTUpdateLifecycleDirtied) {
    _textLifecycle = RCTUpdateLifecycleDirtied;
    [_superview dirtyText];
  }
}

- (BOOL)isTextDirty
{
  return _textLifecycle != RCTUpdateLifecycleComputed;
}

- (void)setTextComputed
{
  _textLifecycle = RCTUpdateLifecycleComputed;
}

- (void)insertReactSubview:(RCTShadowView *)subview atIndex:(NSInteger)atIndex
{
  [_reactSubviews insertObject:subview atIndex:atIndex];
  if (![self isCSSLeafNode]) {
    MTTNodeInsertChild(_nodeRef, subview.nodeRef, (uint32_t)atIndex);
  }
  subview->_superview = self;
  _didUpdateSubviews = YES;
  [self dirtyText];
  [self dirtyPropagation];
}

- (void)removeReactSubview:(RCTShadowView *)subview
{
  [subview dirtyText];
  [subview dirtyPropagation];
  _didUpdateSubviews = YES;
  subview->_superview = nil;
  [_reactSubviews removeObject:subview];
  if (![self isCSSLeafNode]) {
    MTTNodeRemoveChild(_nodeRef, subview.nodeRef);
  }
}

- (NSArray<RCTShadowView *> *)reactSubviews
{
  return _reactSubviews;
}

- (RCTShadowView *)reactSuperview
{
  return _superview;
}

- (NSNumber *)reactTagAtPoint:(CGPoint)point
{
  for (RCTShadowView *shadowView in _reactSubviews) {
    if (CGRectContainsPoint(shadowView.frame, point)) {
      CGPoint relativePoint = point;
      CGPoint origin = shadowView.frame.origin;
      relativePoint.x -= origin.x;
      relativePoint.y -= origin.y;
      return [shadowView reactTagAtPoint:relativePoint];
    }
  }
  return self.reactTag;
}

- (NSString *)description
{
  NSString *description = super.description;
  description = [[description substringToIndex:description.length - 1] stringByAppendingFormat:@"; viewName: %@; reactTag: %@; frame: %@>", self.viewName, self.reactTag, NSStringFromCGRect(self.frame)];
  return description;
}

- (void)addRecursiveDescriptionToString:(NSMutableString *)string atLevel:(NSUInteger)level
{
  for (NSUInteger i = 0; i < level; i++) {
    [string appendString:@"  | "];
  }

  [string appendString:self.description];
  [string appendString:@"\n"];

  for (RCTShadowView *subview in _reactSubviews) {
    [subview addRecursiveDescriptionToString:string atLevel:level + 1];
  }
}

- (NSString *)recursiveDescription
{
  NSMutableString *description = [NSMutableString string];
  [self addRecursiveDescriptionToString:description atLevel:0];
  return description;
}

// Margin

#define RCT_MARGIN_PROPERTY(prop, metaProp)       \
- (void)setMargin##prop:(CGFloat)value            \
{                                                 \
  _marginMetaProps[META_PROP_##metaProp] = value; \
  _recomputeMargin = YES;                         \
}                                                 \
- (CGFloat)margin##prop                           \
{                                                 \
  return _marginMetaProps[META_PROP_##metaProp];  \
}

RCT_MARGIN_PROPERTY(, ALL)
RCT_MARGIN_PROPERTY(Vertical, VERTICAL)
RCT_MARGIN_PROPERTY(Horizontal, HORIZONTAL)
RCT_MARGIN_PROPERTY(Top, TOP)
RCT_MARGIN_PROPERTY(Left, LEFT)
RCT_MARGIN_PROPERTY(Bottom, BOTTOM)
RCT_MARGIN_PROPERTY(Right, RIGHT)

// Padding

#define RCT_PADDING_PROPERTY(prop, metaProp)       \
- (void)setPadding##prop:(CGFloat)value            \
{                                                  \
  _paddingMetaProps[META_PROP_##metaProp] = value; \
  _recomputePadding = YES;                         \
}                                                  \
- (CGFloat)padding##prop                           \
{                                                  \
  return _paddingMetaProps[META_PROP_##metaProp];  \
}

RCT_PADDING_PROPERTY(, ALL)
RCT_PADDING_PROPERTY(Vertical, VERTICAL)
RCT_PADDING_PROPERTY(Horizontal, HORIZONTAL)
RCT_PADDING_PROPERTY(Top, TOP)
RCT_PADDING_PROPERTY(Left, LEFT)
RCT_PADDING_PROPERTY(Bottom, BOTTOM)
RCT_PADDING_PROPERTY(Right, RIGHT)

- (UIEdgeInsets)paddingAsInsets
{
    CGFloat top = MTTNodeLayoutGetPadding(_nodeRef, CSSTop);
    if (isnan(top)) {
        top = 0;
    }
    CGFloat left = MTTNodeLayoutGetPadding(_nodeRef, CSSLeft);
    if (isnan(left)) {
        left = 0;
    }
    CGFloat bottom = MTTNodeLayoutGetPadding(_nodeRef, CSSBottom);
    if (isnan(bottom)) {
        bottom = 0;
    }
    CGFloat right = MTTNodeLayoutGetPadding(_nodeRef, CSSRight);
    if (isnan(right)) {
        right = 0;
    }
    return UIEdgeInsetsMake(top, left, bottom, right);
}

// Border
#define RCT_BORDER_PROPERTY(prop, metaProp)            \
- (void)setBorder##prop##Width:(CGFloat)value          \
{                                                      \
  _borderMetaProps[META_PROP_##metaProp] = value;      \
  _recomputeBorder = YES;                              \
}                                                      \
- (CGFloat)border##prop##Width                         \
{                                                      \
  return _borderMetaProps[META_PROP_##metaProp];       \
}

RCT_BORDER_PROPERTY(, ALL)
RCT_BORDER_PROPERTY(Top, TOP)
RCT_BORDER_PROPERTY(Left, LEFT)
RCT_BORDER_PROPERTY(Bottom, BOTTOM)
RCT_BORDER_PROPERTY(Right, RIGHT)

// Dimensions
#define X5_DIMENSION_PROPERTY(setProp, getProp, cssProp)           \
- (void)set##setProp:(CGFloat)value                                 \
{                                                                   \
  MTTNodeStyleSet##cssProp(_nodeRef, value);                        \
  [self dirtyText];                                                 \
}                                                                   \
- (CGFloat)getProp                                                  \
{                                                                   \
  return MTTNodeLayoutGet##cssProp(_nodeRef);                        \
}
X5_DIMENSION_PROPERTY(Width, width, Width)
X5_DIMENSION_PROPERTY(Height, height, Height)
X5_DIMENSION_PROPERTY(MinWidth, minWidth, MinWidth)
X5_DIMENSION_PROPERTY(MinHeight, minHeight, MinHeight)
X5_DIMENSION_PROPERTY(MaxWidth, maxWidth, MaxWidth)
X5_DIMENSION_PROPERTY(MaxHeight, maxHeight, MaxHeight)

// Position
#define X5_POSITION_PROPERTY(setProp, getProp, edge)               \
- (void)set##setProp:(CGFloat)value                                 \
{                                                                   \
  MTTNodeStyleSetPosition(_nodeRef, edge, value);                   \
  [self dirtyText];                                                 \
}                                                                   \
- (CGFloat)getProp                                                  \
{                                                                   \
  return MTTNodeLayoutGetPosition(_nodeRef, edge);                   \
}
X5_POSITION_PROPERTY(Top, top, CSSTop)
X5_POSITION_PROPERTY(Right, right, CSSRight)
X5_POSITION_PROPERTY(Bottom, bottom, CSSBottom)
X5_POSITION_PROPERTY(Left, left, CSSLeft)

- (void)setFrame:(CGRect)frame
{
  if (!CGRectEqualToRect(frame, _frame)) {
    _frame = frame;
    MTTNodeStyleSetPosition(_nodeRef, CSSLeft, CGRectGetMinX(frame));
    MTTNodeStyleSetPosition(_nodeRef, CSSTop, CGRectGetMinY(frame));
    MTTNodeStyleSetWidth(_nodeRef, CGRectGetWidth(frame));
    MTTNodeStyleSetHeight(_nodeRef, CGRectGetHeight(frame));
  }
}

static inline void x5AssignSuggestedDimension(MTTNodeRef cssNode, Dimension dimension, CGFloat amount)
{
  if (amount != UIViewNoIntrinsicMetric) {
    switch (dimension) {
      case DimWidth:
        if (isnan(MTTNodeLayoutGetWidth(cssNode))) {
          MTTNodeStyleSetWidth(cssNode, amount);
        }
        break;
      case DimHeight:
        if (isnan(MTTNodeLayoutGetHeight(cssNode))) {
          MTTNodeStyleSetHeight(cssNode, amount);
        }
        break;
    }
  }
}

- (void)setIntrinsicContentSize:(CGSize)size
{
  if (MTTNodeLayoutGetFlexGrow(_nodeRef) == 0.f && MTTNodeLayoutGetFlexShrink(_nodeRef) == 0.f) {
    x5AssignSuggestedDimension(_nodeRef, DimHeight, size.height);
    x5AssignSuggestedDimension(_nodeRef, DimWidth, size.width);
  }
}

- (void)setTopLeft:(CGPoint)topLeft
{
  MTTNodeStyleSetPosition(_nodeRef, CSSLeft, topLeft.x);
  MTTNodeStyleSetPosition(_nodeRef, CSSLeft, topLeft.y);
}

- (void)setSize:(CGSize)size
{
  MTTNodeStyleSetWidth(_nodeRef, size.width);
  MTTNodeStyleSetHeight(_nodeRef, size.height);
}

// Flex

- (void)setFlex:(CGFloat)value
{
  MTTNodeStyleSetFlex(_nodeRef, value);
}

#define X5_STYLE_PROPERTY(setProp, getProp, cssProp, type) \
- (void)set##setProp:(type)value                            \
{                                                           \
  MTTNodeStyleSet##cssProp(_nodeRef, value);                \
}                                                           \
- (type)getProp                                             \
{                                                           \
  return MTTNodeLayoutGet##cssProp(_nodeRef);                \
}

X5_STYLE_PROPERTY(FlexGrow, flexGrow, FlexGrow, CGFloat)
X5_STYLE_PROPERTY(FlexShrink, flexShrink, FlexShrink, CGFloat)
X5_STYLE_PROPERTY(FlexBasis, flexBasis, FlexBasis, CGFloat)
X5_STYLE_PROPERTY(FlexDirection, flexDirection, FlexDirection, FlexDirection)
X5_STYLE_PROPERTY(JustifyContent, justifyContent, JustifyContent, FlexAlign)
X5_STYLE_PROPERTY(AlignSelf, alignSelf, AlignSelf, FlexAlign)
X5_STYLE_PROPERTY(AlignItems, alignItems, AlignItems, FlexAlign)
X5_STYLE_PROPERTY(Position, position, PositionType, PositionType)
X5_STYLE_PROPERTY(FlexWrap, flexWrap, FlexWrap, FlexWrapMode)
X5_STYLE_PROPERTY(Overflow, overflow, Overflow, OverflowType)
X5_STYLE_PROPERTY(DisplayType, displayType, Display, DisplayType)

- (void)setBackgroundColor:(UIColor *)color
{
  _backgroundColor = color;
  [self dirtyPropagation];
}

- (void)setZIndex:(NSInteger)zIndex
{
  _zIndex = zIndex;
  if (_superview) {
    // Changing zIndex means the subview order of the parent needs updating
    _superview->_didUpdateSubviews = YES;
    [_superview dirtyPropagation];
  }
}

- (void)didUpdateReactSubviews
{
  // Does nothing by default
}

- (void)didSetProps:(__unused NSArray<NSString *> *)changedProps
{
  if (_recomputePadding) {
    RCTProcessMetaPropsPadding(_paddingMetaProps, _nodeRef);
  }
  if (_recomputeMargin) {
    RCTProcessMetaPropsMargin(_marginMetaProps, _nodeRef);
  }
  if (_recomputeBorder) {
    RCTProcessMetaPropsBorder(_borderMetaProps, _nodeRef);
  }
  _recomputeMargin = NO;
  _recomputePadding = NO;
  _recomputeBorder = NO;
}

- (void)reactSetFrame:(__unused CGRect)frame {
    
}


- (NSDictionary *)mergeProps:(NSDictionary *)props
{
  if (self.props == nil) {
    self.props = props;
    return self.props;
  }
  
  if ([_props isEqualToDictionary: props]) {
    return @{};
  }
  
  NSMutableDictionary *needUpdatedProps = [[NSMutableDictionary alloc] initWithDictionary: props];
  NSMutableArray <NSString *> *sameKeys = [NSMutableArray new];
  [self.props enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * stop) {
    if (needUpdatedProps[key] == nil) {
      //RCTNilIfNull方法会将NULL转化为nil,对于数字类型属性则为0，导致实际上为kCFNull的属性，最终会转化为0
      //比如view长宽属性，前端并没有设置其具体数值，而使用css需要终端计算大小，但由于上述机制，导致MTT排版引擎将其宽高设置为0，0，引发bug
      //因此这里做个判断，遇到mergeprops时，如果需要删除的属性是布局相关类型，那一律将新值设置为默认值
        needUpdatedProps[key] = [self defaultValueForKey:key];
    } else {
      if ([needUpdatedProps[key] isEqual: obj]) {
        [sameKeys addObject: key];
      }
    }
  }];
  self.props = needUpdatedProps;
  [needUpdatedProps removeObjectsForKeys: sameKeys];
  return needUpdatedProps;
}

- (id) defaultValueForKey:(NSString *)key {
    static dispatch_once_t onceToken;
    static NSArray *layoutKeys = nil;
    id ret = nil;
    dispatch_once(&onceToken, ^{
        layoutKeys = @[@"top", @"left", @"bottom", @"right", @"width", @"height", @"minWidth", @"maxWidth", @"minHeight", @"maxHeight", @"borderTopWidth", @"borderRightWidth", @"borderBottomWidth", @"borderLeftWidth", @"borderWidth", @"marginTop", @"marginLeft", @"marginBottom", @"marginRight", @"marginVertical", @"marginHorizontal", @"paddingTpp", @"paddingRight", @"paddingBottom", @"paddingLeft", @"paddingVertical", @"paddingHorizontal"];
    });
    if ([layoutKeys containsObject:key]) {
        ret = @(NAN);
    }
    else if ([key isEqualToString:@"display"]){
        ret = @"block";
    }
    else {
        ret = (id)kCFNull;
    }
    return ret;
}
@end
