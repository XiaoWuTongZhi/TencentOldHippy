//
//  RCTBridge+Mtt.m
//  mtt
//
//  Created by halehuang(黄灏涛) on 2017/2/16.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "RCTBridge+Mtt.h"
#import <objc/runtime.h>
#import "RCTBridge+Private.h"
#import "RCTPerformanceLogger.h"
#import "RCTBridge+LocalFileSource.h"
#import "RCTAssert.h"
NSString *const RCTSecondaryBundleDidStartLoadNotification = @"RCTSecondaryBundleDidStartLoadNotification";
NSString *const RCTSecondaryBundleDidLoadSourceCodeNotification = @"RCTSecondaryBundleDidLoadSourceCodeNotification";
NSString *const RCTSecondaryBundleDidLoadNotification = @"RCTSecondaryBundleDidLoadNotification";

@interface SecondaryBundle : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) SecondaryBundleLoadingCompletion loadBundleCompletion;
@property (nonatomic, copy) SecondaryBundleLoadingCompletion enqueueScriptCompletion;
@property (nonatomic, copy) SecondaryBundleCompletion completion;

@end

@implementation SecondaryBundle

@end

static const void *RCTBridgeIsSecondaryBundleLoadingKey = &RCTBridgeIsSecondaryBundleLoadingKey;
static const void *RCTBridgePendingLoadBundlesKey = &RCTBridgePendingLoadBundlesKey;
static const void *RCTBridgeLoadedBundlesKey = &RCTBridgeLoadedBundlesKey;

@implementation RCTBridge (Mtt)

- (NSMutableArray *)pendingLoadBundles
{
    id value = objc_getAssociatedObject(self, RCTBridgePendingLoadBundlesKey);
    return value;
}

- (void)setPendingLoadBundles:(NSMutableArray *)pendingLoadBundles
{
    objc_setAssociatedObject(self, RCTBridgePendingLoadBundlesKey, pendingLoadBundles, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary *)loadedBundleURLs
{
    id value = objc_getAssociatedObject(self, RCTBridgeLoadedBundlesKey);
    return value;
}

- (void)setLoadedBundleURLs:(NSMutableDictionary *)loadedBundleURLs
{
    objc_setAssociatedObject(self, RCTBridgeLoadedBundlesKey, loadedBundleURLs, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isSecondaryBundleLoading
{
    return [(NSNumber *)objc_getAssociatedObject(self, &RCTBridgeIsSecondaryBundleLoadingKey) boolValue];
}

- (void)setIsSecondaryBundleLoading:(BOOL)isSecondaryBundleLoading
{
    objc_setAssociatedObject(self, &RCTBridgeIsSecondaryBundleLoadingKey, @(isSecondaryBundleLoading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)loadSecondary:(NSURL *)secondaryBundleURL loadBundleCompletion:(SecondaryBundleLoadingCompletion)loadBundleCompletion enqueueScriptCompletion:(SecondaryBundleLoadingCompletion)enqueueScriptCompletion completion:(SecondaryBundleCompletion)completion
{
    if (secondaryBundleURL.absoluteString.length == 0)
    {
        return;
    }
    __weak RCTBatchedBridge *batchedBridge = (RCTBatchedBridge *)[self batchedBridge];
    NSString *key = secondaryBundleURL.absoluteString;
    batchedBridge.workFolder = key;
    BOOL loaded;
    @synchronized(self) {
        loaded = [self.loadedBundleURLs objectForKey:key] != nil;
    }
    // 已经加载，直接返回
    if (loaded)
    {
        if (completion)
        {
            completion(YES);
        }
        
        [self loadNextBundle];
        
        return;
    }
    
    // 正在加载中，丢进队列
    if (batchedBridge.isSecondaryBundleLoading)
    {
        SecondaryBundle *bundle = [[SecondaryBundle alloc] init];
        bundle.url = secondaryBundleURL;
        bundle.loadBundleCompletion = loadBundleCompletion;
        bundle.enqueueScriptCompletion = enqueueScriptCompletion;
        bundle.completion = completion;
        
        if (!self.pendingLoadBundles)
        {
            self.pendingLoadBundles = [[NSMutableArray alloc] init];
        }
        
        @synchronized(self) {
            [self.pendingLoadBundles addObject:bundle];
        }
    }
    else
    {
        [self.performanceLogger markStartForTag: RCTSecondaryStartup];
        
        batchedBridge.isSecondaryBundleLoading = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RCTSecondaryBundleDidStartLoadNotification object:self userInfo:@{@"url": key}];
        
        dispatch_queue_t bridgeQueue = dispatch_queue_create("mtt.bussiness.RCTBridgeQueue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_group_t initModulesAndLoadSource = dispatch_group_create();
        dispatch_group_enter(initModulesAndLoadSource);
        __block NSData* sourceCode = nil;
        [RCTJavaScriptLoader loadBundleAtURL:secondaryBundleURL onProgress:nil onComplete:^(NSError *error, NSData *source, __unused int64_t sourceLength) {
            
            if (!error)
            {
                sourceCode = source;
            }
            else
            {
                batchedBridge.isSecondaryBundleLoading = NO;
            }
            
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{@"url": key, @"bridge": self}];
            if (error)
            {
                [userInfo setObject:error forKey:@"error"];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RCTSecondaryBundleDidLoadSourceCodeNotification object:self userInfo:userInfo];
            
            if (loadBundleCompletion)
            {
                loadBundleCompletion(error);
            }
            
            dispatch_group_leave(initModulesAndLoadSource);
        }];
        
        dispatch_group_notify(initModulesAndLoadSource, bridgeQueue, ^{
            RCTBatchedBridge *strongBridge = batchedBridge;
            if (sourceCode)
            {
                // 公共包正在加载，等待
                dispatch_semaphore_wait(strongBridge.semaphore, DISPATCH_TIME_FOREVER);
                
                dispatch_semaphore_signal(strongBridge.semaphore);
                
                RCTAssert(!strongBridge.isLoading, @"异常了common包没有加载好");
                
                [strongBridge enqueueApplicationScript:sourceCode url:secondaryBundleURL onComplete:^(NSError *error) {
                    
                    if (enqueueScriptCompletion)
                    {
                        enqueueScriptCompletion(error);
                    }
                    
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{@"url": key, @"bridge": self}];
                    if (error)
                    {
                        [userInfo setObject:error forKey:@"error"];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:RCTSecondaryBundleDidLoadNotification object:self userInfo:userInfo];
                    
                    if (!error)
                    {
                        if (!self.loadedBundleURLs)
                        {
                            self.loadedBundleURLs = [[NSMutableDictionary alloc] init];
                        }
                        
                        // 加载成功，保存Url，下次无需加载
                        @synchronized(self) {
                            [self.loadedBundleURLs setObject:@(YES) forKey:key];
                        }
                    }
                    
                    batchedBridge.isSecondaryBundleLoading = NO;
                    
                    [self.performanceLogger markStopForTag: RCTSecondaryStartup];
                    
                    if (completion)
                    {
                        completion(!error);
                    }
                    
                    [self loadNextBundle];
                }];
            }
            else
            {
                if (completion)
                {
                    completion(NO);
                }
                
                [self loadNextBundle];
            }
        });
    }
}

- (void)loadNextBundle
{
    @synchronized(self) {
        if (self.pendingLoadBundles.count != 0)
        {
            SecondaryBundle *bundle = self.pendingLoadBundles[0];
            [self.pendingLoadBundles removeObject:bundle];
            [self loadSecondary:bundle.url loadBundleCompletion:bundle.loadBundleCompletion enqueueScriptCompletion:bundle.enqueueScriptCompletion completion:bundle.completion];
        }
    }
}

- (BOOL)isSecondaryBundleURLLoaded:(NSURL *)secondaryBundleURL
{
    @synchronized(self) {
        return [self.loadedBundleURLs objectForKey:secondaryBundleURL.absoluteString] != nil;
    }
}

@end
