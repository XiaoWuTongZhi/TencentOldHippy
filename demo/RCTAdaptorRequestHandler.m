//
//  RCTAdaptorRequestHandler.m
//  demo
//
//  Created by mengyanluo on 2018/7/17.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTAdaptorRequestHandler.h"

@implementation RCTAdaptorRequestHandler
//RCT_EXPORT_MODULE()

- (instancetype) init {
    self = [super init];
    if (self) {
        _delegateCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL) canHandleRequest:(NSURLRequest *)request {
    NSString *scheme = request.URL.scheme;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        return YES;
    }
    return NO;
}

- (id) sendRequest:(NSURLRequest *)request withDelegate:(id<RCTURLRequestDelegate>)delegate {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
    [_delegateCache setObject:delegate forKey:@([dataTask hash])];
    return dataTask;
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    id<RCTURLRequestDelegate> delegate = [_delegateCache objectForKey:@([task hash])];
    [delegate URLRequest:task didSendDataWithProgress:totalBytesSent];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)task
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    id<RCTURLRequestDelegate> delegate = [_delegateCache objectForKey:@([task hash])];
    [delegate URLRequest:task didReceiveResponse:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)task
    didReceiveData:(NSData *)data
{
    id<RCTURLRequestDelegate> delegate = [_delegateCache objectForKey:@([task hash])];
    [delegate URLRequest:task didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    id<RCTURLRequestDelegate> delegate = [_delegateCache objectForKey:@([task hash])];
    [delegate URLRequest:task didCompleteWithError:error];
    [_delegateCache removeObjectForKey:@([task hash])];
}

@end
