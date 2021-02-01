//
//  RCTNavigatorHostView.h
//  Hippy
//
//  Created by mengyanluo on 2018/9/28.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTInvalidating.h"
@class RCTBridge;
NS_ASSUME_NONNULL_BEGIN
@protocol NavigatorHostViewDelegate<NSObject>
@end

@interface RCTNavigatorHostView : UIView<RCTInvalidating, UINavigationControllerDelegate>
@property (nonatomic, weak)id<NavigatorHostViewDelegate> delegate;
- (instancetype) initWithBridge:(RCTBridge *)bridge props:(NSDictionary *)props;
- (void) push:(NSDictionary *)params;
- (void) pop:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END
