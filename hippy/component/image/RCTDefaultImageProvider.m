//
//  RCTDefaultImageProvider.m
//  hippy
//
//  Created by ozonelmy on 2020/8/4.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTDefaultImageProvider.h"
#import "NSData+Format.h"
#import "RCTBridge.h"

@interface RCTDefaultImageProvider () {
    NSData *_data;
    UIImage *_image;
    CGImageSourceRef _imageSourceRef;
}

@end

@implementation RCTDefaultImageProvider

RCT_EXPORT_MODULE(defaultImageProvider)

+ (BOOL)canHandleData:(NSData *)data {
    return YES;
}

+ (BOOL)isAnimatedImage:(NSData *)data {
    BOOL ret = [data hippy_isAnimatedImage];
    return ret;
}

+ (NSUInteger)priorityForData:(NSData *)data {
    return 0;
}

+ (instancetype)imageProviderInstanceForData:(NSData *)data {
    return [[[self class] alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        if ([[self class] isAnimatedImage:data]) {
            _imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        }
        else {
            _data = data;
        }
    }
    return self;
}

- (UIImage *)image {
    if (nil == _image) {
        if (_data) {
            CGFloat view_width = _imageViewSize.width;
            CGFloat view_height = _imageViewSize.height;
            if (_needsDownSampling && view_width > 0 && view_height > 0) {
                CGFloat scale = [UIScreen mainScreen].scale;
                NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache: @(NO)};
                CGImageSourceRef ref = CGImageSourceCreateWithData((__bridge CFDataRef)_data, (__bridge CFDictionaryRef)options);
                if (ref) {
                    NSInteger width = 0, height = 0;
                    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(ref, 0, NULL);
                    if(properties) {
                        CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                        if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                        val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                        if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                        if (width > (view_width * scale) || height > (view_height * scale)) {
                            NSInteger maxDimensionInPixels = MAX(view_width, view_height) * scale;
                            NSDictionary *downsampleOptions = @{(NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @(YES), (NSString *)kCGImageSourceShouldCacheImmediately: @(YES),
                                                         (NSString *)kCGImageSourceCreateThumbnailWithTransform: @(YES), (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxDimensionInPixels)};
                            CGImageRef downsampleImageRef = CGImageSourceCreateThumbnailAtIndex(ref, 0, (__bridge CFDictionaryRef)downsampleOptions);
                            _image = [UIImage imageWithCGImage: downsampleImageRef];
                            if (nil == _image) {
                                _image = [UIImage imageWithData:_data];
                            }
                            CGImageRelease(downsampleImageRef);
                        }
                        CFRelease(properties);
                    }
                    CFRelease(ref);
                }
            }
            else {
                _image = [UIImage imageWithData:_data];
            }
        }
        else {
            _image = [self imageAtFrame:0];
        }
    }
    return _image;
}

- (UIImage *)imageAtFrame:(NSUInteger)index {
    if (_imageSourceRef) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSourceRef, index, NULL);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return image;
    }
    else if (_data) {
        return [self image];
    }
    return nil;
}

- (NSUInteger)imageCount {
    if (_imageSourceRef) {
        size_t count = CGImageSourceGetCount(_imageSourceRef);
        return count;
    }
    return 0;

}

- (NSTimeInterval)delayTimeAtFrame:(NSUInteger)frame {
    const NSTimeInterval kDelayTimeIntervalDefault = 0.1;
    if (_imageSourceRef) {
        NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(_imageSourceRef, frame, NULL);
        NSDictionary *framePropertiesGIF = [frameProperties objectForKey:(id)kCGImagePropertyGIFDictionary];
        
        // Try to use the unclamped delay time; fall back to the normal delay time.
        NSNumber *delayTime = [framePropertiesGIF objectForKey:(id)kCGImagePropertyGIFUnclampedDelayTime];
        if (!delayTime) {
            delayTime = [framePropertiesGIF objectForKey:(id)kCGImagePropertyGIFDelayTime];
        }
        if (!delayTime) {
            delayTime = @(kDelayTimeIntervalDefault);
        }
        return [delayTime floatValue];
    }
    return kDelayTimeIntervalDefault;
}

- (void)dealloc {
    if (_imageSourceRef) {
        CFRelease(_imageSourceRef);
    }
    _data = nil;
}

@end
