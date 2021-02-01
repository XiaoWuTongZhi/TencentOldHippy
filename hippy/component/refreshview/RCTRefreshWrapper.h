//
//  RCTRefreshWrapper.h
//  Hippy
//
//  Created by mengyanluo on 2018/9/19.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTInvalidating.h"
NS_ASSUME_NONNULL_BEGIN
@class RCTBridge;
@interface RCTRefreshWrapper : UIView<RCTInvalidating>
- (void) refreshCompleted;
- (void) startRefresh;
@end

NS_ASSUME_NONNULL_END
