//
//  RCTFetchInfo.m
//  Hippy
//
//  Created by mengyanluo on 2019/5/22.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTFetchInfo.h"

@implementation RCTFetchInfo

- (instancetype) initWithResolveBlock:(RCTPromiseResolveBlock)resolveBlock rejectBlock:(RCTPromiseRejectBlock)rejectBlock report302Status:(BOOL)report302Status {
    self = [super init];
    if (self) {
        _resolveBlock = resolveBlock;
        _rejectBlock = rejectBlock;
        _report302Status = report302Status;
        _fetchData = [NSMutableData data];
    }
    return self;
}

@end
