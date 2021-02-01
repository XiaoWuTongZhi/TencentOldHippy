//
//  RCTRefreshWrapperItemView.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/19.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTRefreshWrapperItemView.h"
#import "UIView+React.h"
@implementation RCTRefreshWrapperItemView

- (void) setFrame:(CGRect)frame {
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        frame.origin.y = -frame.size.height;
    }
    [super setFrame:frame];
}

@end
