//
//  RCTMemoryWarning.h
//  hippy
//
//  Created by ozonelmy on 2019/11/6.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 一些涉及内存优化的接口协议
@protocol RCTMemoryOpt <NSObject>
@required

/// 当app收到内存警告时调用
- (void)didReceiveMemoryWarning;

/// 当app退入后台是调用
- (void)appDidEnterBackground;

/// 当app返回前台时调用
- (void)appWillEnterForeground;
@end

NS_ASSUME_NONNULL_END
