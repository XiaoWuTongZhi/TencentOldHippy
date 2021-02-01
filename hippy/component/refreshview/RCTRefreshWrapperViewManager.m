//
//  RCTRefreshWrapperViewManager.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/19.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTRefreshWrapperViewManager.h"
#import "RCTRefreshWrapper.h"
#import "RCTUIManager.h"
@implementation RCTRefreshWrapperViewManager

RCT_EXPORT_MODULE(RefreshWrapper)

RCT_EXPORT_VIEW_PROPERTY(onRefresh, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(bounceTime, CGFloat)
- (UIView *)view {
    return [RCTRefreshWrapper new];
}

RCT_EXPORT_METHOD(refreshComplected:(NSNumber *__nonnull)reactTag args:(id)arg) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        RCTRefreshWrapper *wrapperView = viewRegistry[reactTag];
        [wrapperView refreshCompleted];
    }];
}

RCT_EXPORT_METHOD(startRefresh:(NSNumber *__nonnull)reactTag args:(id)arg) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        RCTRefreshWrapper *wrapperView = viewRegistry[reactTag];
        [wrapperView startRefresh];
    }];
}

@end
