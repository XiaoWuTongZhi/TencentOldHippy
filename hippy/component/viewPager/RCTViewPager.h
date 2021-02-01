//
// Created by 万致远 on 2018/11/21.
// Copyright (c) 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTScrollView.h"
#import "RCTInvalidating.h"


/**
 ViewPagerItem数量发生变化的回调Block

 @param count 新的ViewPagerItem数量
 */
typedef void(^ViewPagerItemsCountChanged)(NSUInteger count);

@interface RCTViewPager : UIScrollView<UIScrollViewDelegate, RCTInvalidating>
@property (nonatomic, strong) RCTDirectEventBlock onPageSelected;
@property (nonatomic, strong) RCTDirectEventBlock onPageScroll;
@property (nonatomic, strong) RCTDirectEventBlock onPageScrollStateChanged;

@property (nonatomic, assign) NSInteger initialPage;
@property (nonatomic, assign) CGPoint targetOffset;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign, readonly) NSUInteger pageCount;
@property (nonatomic, copy) ViewPagerItemsCountChanged itemsChangedBlock;

- (void)setPage:(NSInteger)pageNumber animated:(BOOL)animated;
- (void)addScrollListener:(id<UIScrollViewDelegate>)scrollListener;
- (void)removeScrollListener:(id<UIScrollViewDelegate>)scrollListener;
@end
