//
//  RCTAdaptorRequestHandler.h
//  demo
//
//  Created by mengyanluo on 2018/7/17.RCTURLRequestHandler
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTURLRequestHandler.h"
#import "RCTInvalidating.h"
#import "RCTURLRequestDelegate.h"

/*
 * 用户自定义adaptor用于图片请求
 */
@interface RCTAdaptorRequestHandler : NSObject<RCTURLRequestHandler, RCTInvalidating, NSURLSessionDelegate> {
    NSMutableDictionary<NSNumber *, id<RCTURLRequestDelegate>> *_delegateCache;
}

@end
