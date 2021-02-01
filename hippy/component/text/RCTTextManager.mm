/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextManager.h"

#import "RCTAssert.h"
#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTShadowText.h"
#import "RCTText.h"
#import "RCTTextView.h"
#import "UIView+React.h"
#import "RCTVirtualTextNode.h"

//遍历该shadowView（shadowText）的dirty且非shadowText的子view，将之加入到queue
//子view如果是dirty，说明其子节点可能有dirtyView
//但现在似乎不存在这种情况，view能嵌套text，text能嵌套text，但text不能嵌套view
static void collectDirtyNonTextDescendants(RCTShadowText *shadowView, NSMutableArray *nonTextDescendants) {
  for (RCTShadowView *child in shadowView.reactSubviews) {
    if ([child isKindOfClass:[RCTShadowText class]]) {
      collectDirtyNonTextDescendants((RCTShadowText *)child, nonTextDescendants);
    }else if ([child isTextDirty]) {
      [nonTextDescendants addObject:child];
    }
  }
}

@interface RCTShadowText (Private)
//hplayout
- (NSTextStorage *)buildTextStorageForWidth:(CGFloat)width widthMode:(MeasureMode)widthMode;
@end


@implementation RCTTextManager

RCT_EXPORT_MODULE(Text)

- (UIView *)view
{
  return [RCTText new];
}

- (RCTShadowView *)shadowView
{
  return [RCTShadowText new];
}

- (RCTVirtualNode *)node:(NSNumber *)tag name:(NSString *)name props:(NSDictionary *)props
{
	return [RCTVirtualTextNode createNode: tag viewName: name props: props];
}

#pragma mark - Shadow properties

RCT_EXPORT_SHADOW_PROPERTY(color, UIColor)
RCT_EXPORT_SHADOW_PROPERTY(fontFamily, NSString)
RCT_EXPORT_SHADOW_PROPERTY(fontSize, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(fontWeight, NSString)
RCT_EXPORT_SHADOW_PROPERTY(fontStyle, NSString)
RCT_EXPORT_SHADOW_PROPERTY(fontVariant, NSArray)
RCT_EXPORT_SHADOW_PROPERTY(isHighlighted, BOOL)
RCT_EXPORT_SHADOW_PROPERTY(letterSpacing, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(lineHeight, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(numberOfLines, NSUInteger)
RCT_EXPORT_SHADOW_PROPERTY(ellipsizeMode, NSLineBreakMode)
RCT_EXPORT_SHADOW_PROPERTY(textAlign, NSTextAlignment)
RCT_EXPORT_SHADOW_PROPERTY(textDecorationStyle, NSUnderlineStyle)
RCT_EXPORT_SHADOW_PROPERTY(textDecorationColor, UIColor)
RCT_EXPORT_SHADOW_PROPERTY(textDecorationLine, RCTTextDecorationLineType)
RCT_EXPORT_SHADOW_PROPERTY(allowFontScaling, BOOL)
RCT_EXPORT_SHADOW_PROPERTY(opacity, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(textShadowOffset, CGSize)
RCT_EXPORT_SHADOW_PROPERTY(textShadowRadius, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(textShadowColor, UIColor)
RCT_EXPORT_SHADOW_PROPERTY(adjustsFontSizeToFit, BOOL)
RCT_EXPORT_SHADOW_PROPERTY(minimumFontScale, CGFloat)
RCT_EXPORT_SHADOW_PROPERTY(text, NSString)
RCT_EXPORT_SHADOW_PROPERTY(autoLetterSpacing, BOOL)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowViewRegistry:(NSDictionary<NSNumber *, RCTShadowView *> *)shadowViewRegistry
{
    for (RCTShadowView *rootView in shadowViewRegistry.allValues) {
        @autoreleasepool {
            if (![rootView isReactRootView]) {
                continue;
            }
            if (![rootView isTextDirty]) {
                continue;
            }
            NSMutableArray<RCTShadowView *> *queue = [NSMutableArray arrayWithObject:rootView];
            for (NSInteger i = 0; i < queue.count; i++) {
                @autoreleasepool {
                    RCTShadowView *shadowView = queue[i];
                    if (!shadowView) {
                        RCTLogWarn(@"shadowView is nil, please remain xcode state and call rainywan");
                        continue;
                    }
                    RCTAssert([shadowView isTextDirty], @"Don't process any nodes that don't have dirty text");

                    if ([shadowView isKindOfClass:[RCTShadowText class]]) {
                        ((RCTShadowText *)shadowView).fontSizeMultiplier = 1.0;
                        [(RCTShadowText *)shadowView recomputeText];
                        collectDirtyNonTextDescendants((RCTShadowText *)shadowView, queue);
                    }
                    else {
                        for (RCTShadowView *child in [shadowView reactSubviews]) {
                            if ([child isTextDirty]) {
                                [queue addObject:child];
                            }
                        }
                    }
                    [shadowView setTextComputed];
                }
            }
        }
    }
    return nil;
}

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowText *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  UIEdgeInsets padding = shadowView.paddingAsInsets;

  return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTText *> *viewRegistry) {
    RCTText *text = viewRegistry[reactTag];
    text.contentInset = padding;
  };
}

@end
