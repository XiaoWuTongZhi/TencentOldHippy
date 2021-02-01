//
//  HPConvert+Transform.m
//  Hippy
//
//  Created by pennyli on 2018/1/6.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import "RCTConvert+Transform.h"
#import "RCTLog.h"
#import "RCTUtils.h"

@implementation RCTConvert(Transform)

static const NSUInteger kMatrixArrayLength = 4 * 4;

+ (CGFloat)convertToRadians:(id)json
{
    if ([json isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)json;
        if ([stringValue hasSuffix:@"deg"]) {
            CGFloat degrees = [[stringValue substringToIndex:stringValue.length - 3] floatValue];
            return degrees * M_PI / 180;
        }
        if ([stringValue hasSuffix:@"rad"]) {
            return [[stringValue substringToIndex:stringValue.length - 3] floatValue];
        }
    }
    return [json floatValue];
}

+ (CATransform3D)CATransform3DFromMatrix:(id)json
{
    CATransform3D transform = CATransform3DIdentity;
    if (!json) {
        return transform;
    }
    if (![json isKindOfClass:[NSArray class]]) {
        RCTLogError(@"[%@], a CATransform3D. Expected array for transform matrix.", json);
        return transform;
    }
    if ([json count] != kMatrixArrayLength) {
        RCTLogError(@"[%@], a CATransform3D. Expected 4x4 matrix array.", json);
        return transform;
    }
    for (NSUInteger i = 0; i < kMatrixArrayLength; i++) {
        ((CGFloat *)&transform)[i] = [RCTConvert CGFloat:json[i]];
    }
    return transform;
}

+ (CATransform3D)CATransform3D:(id)json
{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = - 1.0 / 500.0;
    if (!json) {
        return transform;
    }
    if (![json isKindOfClass:[NSArray class]]) {
        RCTLogError(@"[%@],a CATransform3D. Did you pass something other than an array?", json);
        return transform;
    }
    // legacy matrix support
    if ([(NSArray *)json count] == kMatrixArrayLength && [json[0] isKindOfClass:[NSNumber class]]) {
        RCTLogWarn(@"[RCTConvert CATransform3D:] has deprecated a matrix as input. Pass an array of configs (which can contain a matrix key) instead.");
        return [self CATransform3DFromMatrix:json];
    }
    
    CGFloat zeroScaleThreshold = FLT_EPSILON;
    
    for (NSDictionary *transformConfig in (NSArray<NSDictionary *> *)json) {
        if (transformConfig.count != 1) {
            RCTLogError(@"[%@], a CATransform3D. You must specify exactly one property per transform object.", json);
            return transform;
        }
        NSString *property = transformConfig.allKeys[0];
        id value = RCTNilIfNull(transformConfig[property]);
        if ([property isEqualToString:@"matrix"]) {
            transform = [self CATransform3DFromMatrix:value];
            
        } else if ([property isEqualToString:@"perspective"]) {
            transform.m34 = -1 / [value floatValue];
            
        } else if ([property isEqualToString:@"rotateX"]) {
            CGFloat rotate = [self convertToRadians:value];
            transform = CATransform3DRotate(transform, rotate, 1, 0, 0);
            
        } else if ([property isEqualToString:@"rotateY"]) {
            CGFloat rotate = [self convertToRadians:value];
            transform = CATransform3DRotate(transform, rotate, 0, 1, 0);
            
        } else if ([property isEqualToString:@"rotate"] || [property isEqualToString:@"rotateZ"]) {
            CGFloat rotate = [self convertToRadians:value];
            transform = CATransform3DRotate(transform, rotate, 0, 0, 1);
            
        } else if ([property isEqualToString:@"scale"]) {
            CGFloat scale = [value floatValue];
            scale = ABS(scale) < zeroScaleThreshold ? zeroScaleThreshold : scale;
            transform.m34 = 0.f;
            transform = CATransform3DScale(transform, scale, scale, scale);
        } else if ([property isEqualToString:@"scaleX"]) {
            CGFloat scale = [value floatValue];
            scale = ABS(scale) < zeroScaleThreshold ? zeroScaleThreshold : scale;
            transform.m34 = 0.f;
            transform = CATransform3DScale(transform, scale, 1, 1);
            
        } else if ([property isEqualToString:@"scaleY"]) {
            CGFloat scale = [value floatValue];
            scale = ABS(scale) < zeroScaleThreshold ? zeroScaleThreshold : scale;
            transform.m34 = 0.f;
            transform = CATransform3DScale(transform, 1, scale, 1);
            
        } else if ([property isEqualToString:@"translate"]) {
            NSArray *array = (NSArray<NSNumber *> *)value;
            CGFloat translateX = [RCTNilIfNull(array[0]) floatValue];
            CGFloat translateY = [RCTNilIfNull(array[1]) floatValue];
            CGFloat translateZ = array.count > 2 ? [RCTNilIfNull(array[2]) floatValue] : 0;
            transform = CATransform3DTranslate(transform, translateX, translateY, translateZ);
            
        } else if ([property isEqualToString:@"translateX"]) {
            CGFloat translate = [value floatValue];
            transform = CATransform3DTranslate(transform, translate, 0, 0);
            
        } else if ([property isEqualToString:@"translateY"]) {
            CGFloat translate = [value floatValue];
            transform = CATransform3DTranslate(transform, 0, translate, 0);
            
        } else if ([property isEqualToString:@"skewX"]) {
            CGFloat skew = [self convertToRadians:value];
            transform.m21 = tanf(skew);
            
        } else if ([property isEqualToString:@"skewY"]) {
            CGFloat skew = [self convertToRadians:value];
            transform.m12 = tanf(skew);
            
        } else {
          RCTLogError(@"Unsupported transform type for a CATransform3D: %@.", property);
        }
    }
    return transform;
}

@end
