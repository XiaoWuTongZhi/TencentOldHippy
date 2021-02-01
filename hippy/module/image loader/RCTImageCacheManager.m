//
//  RCTImageCacheManager.m
//  Hippy
//
//  Created by mengyanluo on 2018/11/14.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "RCTImageCacheManager.h"
#import "RCTLog.h"
#import <pthread.h>
#import <CommonCrypto/CommonDigest.h>

@interface RCTImageCacheManager() {
    NSCache *_cache;
}
@end
@implementation RCTImageCacheManager
+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    static RCTImageCacheManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}
- (instancetype) init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = 10 * 1024 * 1024;
        _cache.name = @"com.tencent.RCTImageCache";
    }
    return self;
}
- (void) setImageCacheData:(NSData *)data forURLString:(NSString *)URLString {
    if (URLString && data) {
        NSString *key = URLString;
        // 如果是base64图片的话，对key MD5压缩一下
        if ([key hasPrefix: @"data:image/"]) {
          key = [self cachedBase64ForKey: key];
        }
        [_cache setObject:data forKey:key cost:[data length]];
    }
}

- (NSData *) imageCacheDataForURLString:(NSString *)URLString {
    NSData *data = nil;
    if (URLString) {
        NSString *key = URLString;
        // 如果是base64图片的话，对key MD5压缩一下
        if ([key hasPrefix: @"data:image/"]) {
          key = [self cachedBase64ForKey: key];
        }
        data = [_cache objectForKey:key];
    }
    return data;
}

- (void) setImage:(UIImage *)image forURLString:(NSString *)URLString blurRadius:(CGFloat)radius {
    if (URLString && image) {
        NSString *key = URLString;
        // 如果是base64图片的话，对key MD5压缩一下
        if ([key hasPrefix: @"data:image/"]) {
            key = [self cachedBase64ForKey: key];
        }
        key = [key stringByAppendingFormat:@"%.1f", radius];
        CGImageRef imageRef = image.CGImage;
        NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
        [_cache setObject:image forKey:key cost:bytesPerFrame];
    }
}

- (UIImage *) imageForURLString:(NSString *)URLString blurRadius:(CGFloat)radius {
    
    UIImage *retImage = nil;
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        NSString *key = URLString;
        // 如果是base64图片的话，对key MD5压缩一下
        if ([key hasPrefix: @"data:image/"]) {
            key = [self cachedBase64ForKey: key];
        }
        key = [key stringByAppendingFormat:@"%.1f", radius];
        retImage = [_cache objectForKey:key];
    }
    return retImage;
}

- (NSString *)cachedBase64ForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                                    r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];

    return filename;
}

@end

@implementation RCTImageCacheManager (ImageLoader)

- (UIImage *)loadImageFromCacheForURLString:(NSString *)URLString radius:(CGFloat)radius isBlurredImage:(BOOL *)isBlurredImage{
    if (isBlurredImage) {
        *isBlurredImage = NO;
    }
    
    UIImage *image = [self imageForURLString:URLString blurRadius:radius];
    if (nil == image) {
        NSData *data = [self imageCacheDataForURLString:URLString];
        if (data) {
            image = [UIImage imageWithData:data];
        }
    }
    else if (radius > __FLT_EPSILON__ && isBlurredImage) {
        *isBlurredImage = YES;
    }
    return image;
}

@end
