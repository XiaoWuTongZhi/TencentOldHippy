//
//  RCTNavigatorViewManager.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/28.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "RCTNavigatorViewManager.h"
#import "RCTNavigatorHostView.h"
#import "RCTUIManager.h"
@interface RCTNavigatorViewManager()

@end

@implementation RCTNavigatorViewManager
RCT_EXPORT_MODULE(Navigator)
- (UIView *)view {
    RCTNavigatorHostView *hostView = [[RCTNavigatorHostView alloc] initWithBridge:self.bridge props:self.props];
    hostView.delegate = self;
    return hostView;
}

RCT_EXPORT_METHOD(push:(NSNumber *__nonnull)reactTag parms:(NSDictionary *__nonnull)params) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        RCTNavigatorHostView *navigatorHostView = viewRegistry[reactTag];
        [navigatorHostView push:params];
    }];
}

RCT_EXPORT_METHOD(pop:(NSNumber *__nonnull)reactTag parms:(NSDictionary *__nonnull)params) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        RCTNavigatorHostView *navigatorHostView = viewRegistry[reactTag];
        [navigatorHostView pop:params];
    }];
}
@end
