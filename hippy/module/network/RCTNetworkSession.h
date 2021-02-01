//
//  RCTNetworkSession.h
//  hippy
//
//  Created by allensun on 2020/4/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTNetworkSession : NSObject

@property (nullable, nonatomic, weak) id<NSURLSessionDataDelegate> delegate;

@property (nullable, nonatomic, strong, readonly) NSURLSession *session;

- (void)clearSession;

@end

NS_ASSUME_NONNULL_END
