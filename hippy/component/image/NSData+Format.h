//
//  NSData+Format.h
//  hippy
//
//  Created by pennyli on 8/9/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData(Format)

- (BOOL)hippy_isGif;
- (BOOL)hippy_isAPNG;

- (BOOL)hippy_isAnimatedImage;

@end

NS_ASSUME_NONNULL_END
