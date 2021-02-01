//
// Created by 万致远 on 2018/11/21.
// Copyright (c) 2018 Tencent. All rights reserved.
//

#import "RCTViewPagerManager.h"
#import "RCTViewPager.h"

@implementation RCTViewPagerManager

RCT_EXPORT_MODULE(ViewPager)

- (UIView *)view
{
    return [RCTViewPager new];
}

RCT_EXPORT_VIEW_PROPERTY(initialPage, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(scrollEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(loop, BOOL)

RCT_EXPORT_VIEW_PROPERTY(onPageSelected, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPageScroll, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPageScrollStateChanged, RCTDirectEventBlock)


RCT_EXPORT_METHOD(setPage:(nonnull NSNumber *)reactTag
        pageNumber:(__unused NSNumber *)pageNumber
        )
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        UIView *view = viewRegistry[reactTag];

        if (view == nil || ![view isKindOfClass:[RCTViewPager class]]) {
            RCTLogError(@"tried to setPage: on an error viewPager %@ "
                        "with tag #%@", view, reactTag);
        }
        NSInteger pageNumberInteger = pageNumber.integerValue;
        [(RCTViewPager *)view setPage:pageNumberInteger animated:YES];
    }];

}

RCT_EXPORT_METHOD(setPageWithoutAnimation:(nonnull NSNumber *)reactTag
        pageNumber:(__unused NSNumber *)pageNumber
)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        UIView *view = viewRegistry[reactTag];
        if (view == nil || ![view isKindOfClass:[RCTViewPager class]]) {
            RCTLogError(@"tried to setPage: on an error viewPager %@ "
                        "with tag #%@", view, reactTag);
        }
        NSInteger pageNumberInteger = pageNumber.integerValue;
        [(RCTViewPager *)view setPage:pageNumberInteger animated:NO];
    }];
}


@end
