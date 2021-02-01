//
//  RCTImageLoaderModule.m
//  React
//
//  Created by mengyanluo on 2018/4/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RCTImageLoaderModule.h"
#import "RCTImageCacheManager.h"
#import <UIKit/UIKit.h>
#import "RCTBridge.h"
#import "RCTDefaultImageProvider.h"
#import "RCTImageProviderProtocol.h"

@implementation RCTImageLoaderModule

RCT_EXPORT_MODULE(ImageLoaderModule)

@synthesize bridge = _bridge;

RCT_EXPORT_METHOD(getSize:(NSString *)urlString resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    UIImage *image = [[RCTImageCacheManager sharedInstance] loadImageFromCacheForURLString:urlString radius:0 isBlurredImage:nil];
    if (image) {
        NSDictionary *dic = @{@"width": @(image.size.width), @"height": @(image.size.height)};
        resolve(dic);
        return;
    }
    NSData *uriData = [urlString dataUsingEncoding:NSUTF8StringEncoding];
    if (nil == uriData) {
        NSError *error = [NSError errorWithDomain:@"ImageLoaderModuleDomain" code:1 userInfo:@{@"reason": @"url parse error"}];
        reject(@"1", @"url parse error", error);
        return;
    }
    CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
    NSURL *source_url = CFBridgingRelease(urlRef);
    
    typedef void (^HandleCompletedBlock)(BOOL, NSData *, NSURL *, NSError *);
    HandleCompletedBlock completedBlock = ^void(BOOL cached, NSData *data, NSURL *url, NSError *error) {
        if (error) {
             NSError *error = [NSError errorWithDomain:@"ImageLoaderModuleDomain" code:1 userInfo:@{@"reason": @"url parse error"}];
             reject(@"2", @"url request error", error);
         } else {
             if (!cached) {
                 [[RCTImageCacheManager sharedInstance] setImageCacheData:data forURLString:urlString];
             }
             Class<RCTImageProviderProtocol> ipClass = imageProviderClass(data,self.bridge);
             id<RCTImageProviderProtocol> instance = [ipClass imageProviderInstanceForData:data];
             UIImage *image = [instance image];
             if (image) {
               NSDictionary *dic = @{@"width": @(image.size.width), @"height": @(image.size.height)};
               resolve(dic);
             } else {
               NSError *error = [NSError errorWithDomain:@"ImageLoaderModuleDomain" code:2 userInfo:@{@"reason": @"image parse error"}];
               reject(@"2", @"image request error", error);
             }
         }
    };
    
    if (_bridge.imageLoader && [_bridge.imageLoader respondsToSelector: @selector(loadImage:completed:)]) {
        [_bridge.imageLoader loadImage: source_url completed:^(NSData *data, NSURL *url, NSError *error, BOOL cached) {
            completedBlock(cached, data, url, error);
        }];
    } else {
        [[[NSURLSession sharedSession] dataTaskWithURL:source_url completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
            completedBlock(NO, data, source_url, error);
        }] resume];
    }
}

RCT_EXPORT_METHOD(prefetch:(NSString *)urlString) {
    //这里后续需要使用自定义缓存，目前先使用系统缓存吧
    NSData *uriData = [urlString dataUsingEncoding:NSUTF8StringEncoding];
    if (nil == uriData) {
        return;
    }
    
    // 先查一下，有的话就不拉了
    if([[RCTImageCacheManager sharedInstance] imageCacheDataForURLString: urlString]) {
        return;
    }
    
    CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
    NSURL *source_url = CFBridgingRelease(urlRef);
    
    if (source_url) {
        
        typedef void (^HandleCompletedBlock)(BOOL, NSData *);
        HandleCompletedBlock completedBlock = ^void(BOOL cached, NSData *data) {
            if (data && !cached) {
               [[RCTImageCacheManager sharedInstance] setImageCacheData:data forURLString:urlString];
            }
        };
        
        if (_bridge.imageLoader && [_bridge.imageLoader respondsToSelector: @selector(loadImage:completed:)]) {
            [_bridge.imageLoader loadImage: source_url completed:^(NSData *data, NSURL *url, NSError *error, BOOL cached) {
                completedBlock(cached, data);
            }];
        } else {
            [[[NSURLSession sharedSession] dataTaskWithURL:source_url completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
                completedBlock(NO, data);
            }] resume];
        }
        
    }
}

@end
