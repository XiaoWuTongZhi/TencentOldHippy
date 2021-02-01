//
// Created by 万致远 on 2018/12/3.
// Copyright (c) 2018 Tencent. All rights reserved.
//

#import "RCTViewPagerItemManager.h"
#import "RCTViewPagerItem.h"

@implementation RCTViewPagerItemManager
RCT_EXPORT_MODULE(ViewPagerItem)
- (UIView *)view
{
    return [RCTViewPagerItem new];
}
@end
