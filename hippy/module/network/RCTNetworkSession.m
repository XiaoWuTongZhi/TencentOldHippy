//
//  RCTNetworkSession.m
//  hippy
//
//  Created by allensun on 2020/4/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "RCTNetworkSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCTNetworkSession () <NSURLSessionDataDelegate>

@property (nullable, nonatomic, strong, readwrite) NSURLSession *session;

@end

NS_ASSUME_NONNULL_END

@implementation RCTNetworkSession

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)clearSession {
    [self.session finishTasksAndInvalidate];
    self.session = nil;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if ([self.delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [self.delegate URLSession:session
                             task:task
       willPerformHTTPRedirection:response
                       newRequest:request
                completionHandler:completionHandler];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [self.delegate URLSession:session task:task didCompleteWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if ([self.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [self.delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

@end
