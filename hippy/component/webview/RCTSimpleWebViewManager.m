//
//  RCTWebViewManager.m
//  Hippy
//
//  Created by 万致远 on 2019/3/30.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTSimpleWebViewManager.h"

@implementation RCTSimpleWebViewManager
RCT_EXPORT_MODULE(WebView)

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadEnd, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)

- (UIView *)view {
    return [RCTSimpleWebView new];
}

@end
