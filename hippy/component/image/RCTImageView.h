//
//  RCTImageViewV2.h
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/21.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTComponent.h"
#import "RCTConvert.h"
#import "RCTAnimatedImageView.h"
#import "RCTMemoryOpt.h"
#import "RCTImageProviderProtocol.h"

@class RCTBridge;
@class RCTImageView;
@interface RCTAnimatedImageOperation : NSOperation {
    NSData *_animatedImageData;
    NSString *_url;
    __weak RCTImageView *_imageView;
    BOOL _isSharpP;
    id<RCTImageProviderProtocol> _imageProvider;
}

- (id) initWithAnimatedImageData:(NSData *)data imageView:(RCTImageView *)imageView imageURL:(NSString *)url isSharpP:(BOOL)isSharpP;
- (id) initWithAnimatedImageProvider:(id<RCTImageProviderProtocol>)imageProvider imageView:(RCTImageView *)imageView imageURL:(NSString *)url;

@end

typedef NS_ENUM(NSInteger, RCTResizeMode) {
	RCTResizeModeCover = UIViewContentModeScaleAspectFill,
	RCTResizeModeContain = UIViewContentModeScaleAspectFit,
	RCTResizeModeStretch = UIViewContentModeScaleToFill,
	RCTResizeModeCenter = UIViewContentModeCenter,
	RCTResizeModeRepeat = -1, // Use negative values to avoid conflicts with iOS enum values.
};

@interface RCTImageView : RCTAnimatedImageView <NSURLSessionDelegate, RCTMemoryOpt>

@property (nonatomic, assign) CGFloat blurRadius;
@property (nonatomic, assign) UIEdgeInsets capInsets;
@property (nonatomic, assign) RCTResizeMode resizeMode;
@property (nonatomic, copy) NSArray *source;
@property (nonatomic, strong) UIImage *defaultImage;
@property (nonatomic, assign) UIImageRenderingMode renderingMode;
@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, assign) BOOL isGray;
@property (nonatomic, assign) BOOL needDownsampleing;
@property (nonatomic, assign) CGFloat borderTopLeftRadius;
@property (nonatomic, assign) CGFloat borderTopRightRadius;
@property (nonatomic, assign) CGFloat borderBottomLeftRadius;
@property (nonatomic, assign) CGFloat borderBottomRightRadius;

@property (nonatomic, copy) RCTDirectEventBlock onLoadStart;
@property (nonatomic, copy) RCTDirectEventBlock onProgress;
@property (nonatomic, copy) RCTDirectEventBlock onError;
@property (nonatomic, copy) RCTDirectEventBlock onLoad;
@property (nonatomic, copy) RCTDirectEventBlock onLoadEnd;

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

- (void)reloadImage;

- (void)updateImage:(UIImage *)image;

- (UIImage *) imageFromData:(NSData *)data;

- (void)clearImageIfDetached;

- (id<RCTImageProviderProtocol>) instanceImageProviderFromClass:(Class<RCTImageProviderProtocol>)cls imageData:(NSData *)data;

@end

@interface RCTConvert(RCTResizeMode)
+ (RCTResizeMode)RCTResizeMode:(id)json;
@end

