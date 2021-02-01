//
//  RCTRefreshWrapperItemViewManager.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/19.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTRefreshWrapperItemViewManager.h"
#import "RCTRefreshWrapperItemView.h"
@implementation RCTRefreshWrapperItemViewManager
RCT_EXPORT_MODULE(RefreshWrapperItemView)
- (UIView *)view {
    return [RCTRefreshWrapperItemView new];
}
@end
