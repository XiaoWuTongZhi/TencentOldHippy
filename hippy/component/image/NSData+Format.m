//
//  NSData+Format.m
//  hippy
//
//  Created by pennyli on 8/9/19.
//

#import "NSData+Format.h"

static bool memcontains(const void *s, const void *t, size_t sl, size_t tl) {
    for (size_t i = 0; i < sl - tl; i++) {
        if (0 == memcmp(s + i, t, tl)) {
            return true;
        }
    }
    return false;
}

@implementation NSData(Format)

- (BOOL)hippy_isGif
{
    if (self.length < 12) {
        return NO;
    }
    char bytes[12] = {0};
    
    [self getBytes:&bytes length:12];
    
    const char gif[3] = {'G', 'I', 'F'};
    if (!memcmp(bytes, gif, 3)) {
        return YES;
    }
    return NO;
}

- (BOOL)hippy_isAPNG {
    if ([self length] < 0x50) {
        return NO;
    }
    const void *bytes = [self bytes];
    const char pngSig[8] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
    const char pngacTL[4] = {'a', 'c', 'T', 'L'};
    if (memcmp(bytes, pngSig, 8) &&
        memcontains(bytes, pngacTL, 0x50, 4)) {
        return YES;
    }
    return NO;
}

- (BOOL)hippy_isAnimatedImage {
    do {
        if ([self hippy_isGif]) {
            return YES;
        }
        if ([self hippy_isAPNG]) {
            return YES;
        }
    } while (0);
    return NO;
}

@end
