//
//  HPNetWork.m
//  Hippy
//
//  Created by pennyli on 2018/1/9.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import "RCTNetWork.h"
#import "RCTAssert.h"
#import "RCTLog.h"
#import <WebKit/WKHTTPCookieStore.h>
#import <WebKit/WKWebsiteDataStore.h>
#import "RCTUtils.h"
#import "RCTFetchInfo.h"
#import "objc/runtime.h"

static char fetchInfoKey;

static void setFetchInfoForSessionTask(NSURLSessionTask *task, RCTFetchInfo *fetchInfo) {
    objc_setAssociatedObject(task, &fetchInfoKey, fetchInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

RCTFetchInfo *fetchInfoForSessionTask(NSURLSessionTask *task) {
    RCTFetchInfo *info = objc_getAssociatedObject(task, &fetchInfoKey);
    return info;
}

@implementation RCTNetWork

RCT_EXPORT_MODULE(network)

RCT_EXPORT_METHOD(fetch:(NSDictionary *)params resolver:(__unused RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject)
{
    NSString *method = params[@"method"];
    NSString *url = params[@"url"];
    NSDictionary *header = params[@"headers"];
    NSString *body = params[@"body"];
  
    RCTAssertParam(url);
    RCTAssertParam(method);
	
	if (![header isKindOfClass: [NSDictionary class]]) {
		header = @{};
	}
	
    NSURL *requestURL = RCTURLWithString(url, NULL);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod: method];
	
	NSMutableDictionary *httpHeader = [NSMutableDictionary new];
	[header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, __unused BOOL *stop) {
		NSString *value = nil;
		if ([obj isKindOfClass: [NSArray class]]) {
			value = [[(NSArray *)obj valueForKey:@"description"] componentsJoinedByString:@","];
		} else if ([obj isKindOfClass: [NSString class]]) {
			value = obj;
		}
		
		[httpHeader setValue: value forKey: key];
	}];
    if (httpHeader.count) {
		[request setAllHTTPHeaderFields: httpHeader];
	}
    NSDictionary<NSString *, NSString *> *extraHeaders = [self extraHeaders];
    [extraHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [request addValue:obj forHTTPHeaderField:key];
    }];
    
    if (body.length) {
        NSData *postData = [body dataUsingEncoding: NSUTF8StringEncoding];
        if (postData) {
            [request setHTTPBody: postData];
        }
    }
    NSString *redirect = params[@"redirect"];
    BOOL report302Status = (nil == redirect || [redirect isEqualToString:@"manual"]);
    RCTFetchInfo *fetchInfo = [[RCTFetchInfo alloc] initWithResolveBlock:resolve rejectBlock:reject report302Status:report302Status];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = [self protocolClasses];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request];
    setFetchInfoForSessionTask(task, fetchInfo);
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    RCTFetchInfo *fetchInfo = fetchInfoForSessionTask(task);
    if (fetchInfo.report302Status) {
        RCTPromiseResolveBlock resolver = fetchInfo.resolveBlock;
        if (resolver) {
            NSDictionary *result = @{
                                     @"statusCode": @(response.statusCode),
                                     @"statusLine": @"",
                                     @"respHeaders": response.allHeaderFields ? : @{},
                                     @"respBody": @""
                                     };
            
            resolver(result);
        }
        completionHandler(nil);
    }
    else {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    BOOL is302Response = ([task.response isKindOfClass:[NSHTTPURLResponse class]] && 302 == [(NSHTTPURLResponse *)task.response statusCode]);
    RCTFetchInfo *fetchInfo = fetchInfoForSessionTask(task);
    //如果是302并且禁止自动跳转，那说明已经将302结果发送给服务器，不需要再次发送
    if (is302Response && fetchInfo.report302Status) {
        return;
    }
    if (error) {
        RCTPromiseRejectBlock rejector = fetchInfo.rejectBlock;
        NSString *code = [NSString stringWithFormat:@"%ld", (long)error.code];
        rejector(code,error.description, error);
    }
    else {
        RCTPromiseResolveBlock resolver = fetchInfo.resolveBlock;
        NSData *data = fetchInfo.fetchData;
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *) task.response;
        NSDictionary *result = @{
                                 @"statusCode": @(resp.statusCode),
                                 @"statusLine": @"",
                                 @"respHeaders": resp.allHeaderFields ? : @{},
                                 @"respBody": dataStr ? : @""
                                 };
        
        resolver(result);
    }
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSMutableData *fetchData = fetchInfoForSessionTask(dataTask).fetchData;
    [fetchData appendData:data];
}

- (NSArray<Class> *) protocolClasses {
    return [NSArray array];
}

- (NSDictionary<NSString *, NSString *> *)extraHeaders {
    return nil;
}

RCT_EXPORT_METHOD(getCookie:(NSString *)urlString resolver:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    NSData *uriData = [urlString dataUsingEncoding:NSUTF8StringEncoding];
    if (nil == uriData) {
        resolve(@"");
        return;
    }
    CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
    NSURL *source_url = CFBridgingRelease(urlRef);
    NSArray<NSHTTPCookie *>* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:source_url];
    NSMutableString *string = [NSMutableString stringWithCapacity:256];
    for (NSHTTPCookie *cookie in cookies) {
        [string appendFormat:@";%@=%@", cookie.name, cookie.value];
    }
    if ([string length] > 0) {
        [string deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    resolve(string);
}

RCT_EXPORT_METHOD(setCookie:(NSString *)urlString keyValue:(NSString *)keyValue expireString:(NSString *)expireString) {
    NSData *uriData = [urlString dataUsingEncoding:NSUTF8StringEncoding];
    if (nil == uriData) {
        return;
    }
    CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
    if (NULL == urlRef) {
        return;
    }
    NSURL *source_url = CFBridgingRelease(urlRef);
    NSArray<NSString *> *keysvalues = [keyValue componentsSeparatedByString:@";"];
    NSMutableArray<NSHTTPCookie *>* cookies = [NSMutableArray arrayWithCapacity:[keysvalues count]];
    NSString *path = [source_url path];
    NSString *domain = [source_url host];
    if (nil == path || nil == domain) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *allValues in keysvalues) {
            @autoreleasepool {
                NSArray<NSString *> *value = [allValues componentsSeparatedByString:@"="];
                NSDictionary *dictionary = @{NSHTTPCookieName: value[0], NSHTTPCookieValue: value[1], NSHTTPCookieExpires: expireString, NSHTTPCookiePath: path, NSHTTPCookieDomain: domain};
                NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:dictionary];
                if (cookie) {
                    [cookies addObject:cookie];
                    //给ios11以上的系统设置WKCookie
                    if (@available(iOS 11.0, *)) {
                        WKWebsiteDataStore *ds = [WKWebsiteDataStore defaultDataStore];
                        [ds.httpCookieStore setCookie:cookie completionHandler:NULL];
                    }
                }
            }
        }
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:source_url mainDocumentURL:nil];
    });
}

@end
