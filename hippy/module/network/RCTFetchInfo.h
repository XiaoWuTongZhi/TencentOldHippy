//
//  RCTFetchInfo.h
//  Hippy
//
//  Created by mengyanluo on 2019/5/22.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTBridgeModule.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCTFetchInfo : NSObject
//YES表示如果遇到302跳转则停止跳转，将302结果上报。否则自动跳转不上报302状态
@property (nonatomic, readonly, assign) BOOL report302Status;
@property (nonatomic, readonly, strong) RCTPromiseResolveBlock resolveBlock;
@property (nonatomic, readonly, strong) RCTPromiseRejectBlock rejectBlock;
@property (nonatomic, readonly, strong) NSMutableData *fetchData;

- (instancetype) initWithResolveBlock:(RCTPromiseResolveBlock)resolveBlock rejectBlock:(RCTPromiseRejectBlock)rejectBlock report302Status:(BOOL)report302Status;

@end

NS_ASSUME_NONNULL_END
