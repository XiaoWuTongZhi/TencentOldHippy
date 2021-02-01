/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTShadowView.h"
#import "RCTTextDecorationLineType.h"

typedef NS_ENUM(NSInteger, RCTSizeComparison)
{
  RCTSizeTooLarge,
  RCTSizeTooSmall,
  RCTSizeWithinRange,
};


extern NSString *const RCTIsHighlightedAttributeName;
extern NSString *const RCTReactTagAttributeName;
extern NSString *const RCTShadowViewAttributeName;

@interface RCTShadowText : RCTShadowView {
    @protected
    NSTextStorage *_cachedTextStorage;
    CGFloat _cachedTextStorageWidth;
    CGFloat _cachedTextStorageWidthMode;
    NSAttributedString *_cachedAttributedString;
    CGFloat _effectiveLetterSpacing;
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, copy) NSString *fontWeight;
@property (nonatomic, copy) NSString *fontStyle;
@property (nonatomic, copy) NSArray *fontVariant;
@property (nonatomic, assign) BOOL isHighlighted;
@property (nonatomic, assign) CGFloat letterSpacing;
@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, assign) NSUInteger numberOfLines;
@property (nonatomic, assign) NSLineBreakMode ellipsizeMode;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) NSTextAlignment textAlign;
@property (nonatomic, strong) UIColor *textDecorationColor;
@property (nonatomic, assign) NSUnderlineStyle textDecorationStyle;
@property (nonatomic, assign) RCTTextDecorationLineType textDecorationLine;
@property (nonatomic, assign) CGFloat fontSizeMultiplier;
@property (nonatomic, assign) BOOL allowFontScaling;
@property (nonatomic, assign) CGFloat opacity;
@property (nonatomic, assign) CGSize textShadowOffset;
@property (nonatomic, assign) CGFloat textShadowRadius;
@property (nonatomic, strong) UIColor *textShadowColor;
@property (nonatomic, assign) BOOL adjustsFontSizeToFit;
@property (nonatomic, assign) CGFloat minimumFontScale;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL autoLetterSpacing;

- (void)recomputeText;
- (NSAttributedString *)_attributedStringWithFontFamily:(NSString *)fontFamily
                                               fontSize:(NSNumber *)fontSize
                                             fontWeight:(NSString *)fontWeight
                                              fontStyle:(NSString *)fontStyle
                                          letterSpacing:(NSNumber *)letterSpacing
                                     useBackgroundColor:(BOOL)useBackgroundColor
                                        foregroundColor:(UIColor *)foregroundColor
                                        backgroundColor:(UIColor *)backgroundColor
                                                opacity:(CGFloat)opacity;
- (void)_addAttribute:(NSString *)attribute withValue:(id)attributeValue toAttributedString:(NSMutableAttributedString *)attributedString;
- (void)_setParagraphStyleOnAttributedString:(NSMutableAttributedString *)attributedString
                              fontLineHeight:(CGFloat)fontLineHeight
                      heightOfTallestSubview:(CGFloat)heightOfTallestSubview;
@end
