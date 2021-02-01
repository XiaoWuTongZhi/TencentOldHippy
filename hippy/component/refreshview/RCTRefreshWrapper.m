//
//  RCTRefreshWrapper.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/19.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTRefreshWrapper.h"
#import "UIView+React.h"
#import "RCTRefreshWrapperItemView.h"
#import "RCTScrollableProtocol.h"
@interface RCTRefreshWrapper()<UIScrollViewDelegate>
@property (nonatomic, weak) RCTRefreshWrapperItemView *wrapperItemView;
@property (nonatomic, weak) id<RCTScrollableProtocol> scrollableView;
@property (nonatomic, copy) RCTDirectEventBlock onRefresh;
@property (nonatomic, assign) CGFloat bounceTime;
@property (nonatomic, weak) RCTBridge *bridge;
@end
@implementation RCTRefreshWrapper
- (void) addSubview:(UIView *)view {
    if (view != _wrapperItemView) {
        [super addSubview:view];
    }
    [self refactorViews];
}

- (void) refactorViews {
    if (_wrapperItemView && _scrollableView) {
        CGSize size = _wrapperItemView.frame.size;
        _wrapperItemView.frame = CGRectMake(0, -size.height, size.width, size.height);
        [_scrollableView.realScrollView addSubview:_wrapperItemView];
    }
}

- (void) refreshCompleted {
    CGFloat duration = _bounceTime != 0 ? _bounceTime : 400;
    [UIView animateWithDuration:duration / 1000.f animations:^{
        [self->_scrollableView.realScrollView setContentInset:UIEdgeInsetsZero];
    }];
}

- (void) startRefresh {
    CGFloat wrapperItemViewHeight = _wrapperItemView.frame.size.height;
    UIEdgeInsets insets = _scrollableView.realScrollView.contentInset;
    insets.top = wrapperItemViewHeight;
    CGFloat duration = _bounceTime != 0 ? _bounceTime : 400;
    [UIView animateWithDuration:duration / 1000.f animations:^{
        [self->_scrollableView.realScrollView setContentInset:insets];
        [self->_scrollableView.realScrollView setContentOffset:CGPointMake(0, -insets.top)];
    }];
    if (_onRefresh) {
        _onRefresh(@{});
    }
}

- (void) insertReactSubview:(UIView *)view atIndex:(NSInteger)index {
    if ([view isKindOfClass:[RCTRefreshWrapperItemView class]]) {
        _wrapperItemView = (RCTRefreshWrapperItemView *)view;
    }
    else if ([view conformsToProtocol:@protocol(RCTScrollableProtocol)]) {
        _scrollableView = (id<RCTScrollableProtocol>) view;
        [_scrollableView addScrollListener:self];
    }
    [super insertReactSubview:view atIndex:index];
}

- (void) invalidate {
    [_scrollableView removeScrollListener:self];
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat wrapperItemViewHeight = _wrapperItemView.frame.size.height;
    UIEdgeInsets insets = scrollView.contentInset;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (contentOffsetY <= -wrapperItemViewHeight && insets.top != wrapperItemViewHeight) {
        insets.top = wrapperItemViewHeight;
        scrollView.contentInset = insets;
        if (_onRefresh) {
            _onRefresh(@{});
        }
    }
}

@end
