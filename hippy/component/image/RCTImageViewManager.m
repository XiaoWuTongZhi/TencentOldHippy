//
//  RCTImageViewV2Manager.m
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/21.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTImageViewManager.h"
#import "RCTImageView.h"
#import "RCTConvert.h"
#import <UIKit/UIKit.h>

@implementation RCTImageViewManager

RCT_EXPORT_MODULE(Image)

RCT_EXPORT_VIEW_PROPERTY(blurRadius, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(capInsets, UIEdgeInsets)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, RCTResizeMode)
RCT_EXPORT_VIEW_PROPERTY(source, NSArray)
RCT_EXPORT_VIEW_PROPERTY(onLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPartialLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadEnd, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(isGray, BOOL)
RCT_EXPORT_VIEW_PROPERTY(needDownsampleing, BOOL)


RCT_CUSTOM_VIEW_PROPERTY(tintColor, UIColor, RCTImageView)
{
	view.tintColor = [RCTConvert UIColor:json] ?: defaultView.tintColor;
	view.renderingMode = json ? UIImageRenderingModeAlwaysTemplate : defaultView.renderingMode;
}

RCT_CUSTOM_VIEW_PROPERTY(defaultSource, NSString, RCTImageView) {
    NSString *source = [RCTConvert NSString:json];
    if ([source hasPrefix: @"data:image/"]) {
        NSRange range = [source rangeOfString:@";base64,"];
        if (NSNotFound != range.location) {
            source = [source substringFromIndex:range.location + range.length];
        }
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:source options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [view imageFromData:imageData];
        view.defaultImage = image;
    }
}

#define RCT_VIEW_BORDER_RADIUS_PROPERTY(SIDE)                           \
RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Radius, CGFloat, RCTImageView)        \
{                                                                       \
    if ([view respondsToSelector:@selector(setBorder##SIDE##Radius:)]) {  \
        view.border##SIDE##Radius = json ? [RCTConvert CGFloat:json] : defaultView.border##SIDE##Radius; \
    }                                                                     \
}                                                                       \

RCT_VIEW_BORDER_RADIUS_PROPERTY(TopLeft)
RCT_VIEW_BORDER_RADIUS_PROPERTY(TopRight)
RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomLeft)
RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomRight)

- (UIView *)view
{
	return [[RCTImageView alloc] initWithBridge: self.bridge];
}

@end
