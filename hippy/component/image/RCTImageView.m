//
//  RCTImageViewV2.m
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/21.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTImageView.h"
#import <objc/runtime.h>
#import "RCTUtils.h"
#import "UIView+React.h"
#import "RCTImageViewCustomLoader.h"
#import "RCTBridge+LocalFileSource.h"
#import "RCTImageCacheManager.h"
#import "RCTAnimatedImage.h"
#import <Accelerate/Accelerate.h>
#import "RCTDefaultImageProvider.h"
#import "NSData+Format.h"

static NSOperationQueue *rct_image_queue() {
    static dispatch_once_t onceToken;
    static NSOperationQueue *_rct_image_queue = nil;
    dispatch_once(&onceToken, ^{
        _rct_image_queue = [[NSOperationQueue alloc] init];
        _rct_image_queue.maxConcurrentOperationCount = 1;
    });
    return _rct_image_queue;
}

static NSOperationQueue *animated_image_queue() {
    static dispatch_once_t onceToken;
    static NSOperationQueue *_animatedImageOQ = nil;
    dispatch_once(&onceToken, ^{
        _animatedImageOQ = [[NSOperationQueue alloc] init];
        _animatedImageOQ.maxConcurrentOperationCount = 1;
    });
    return _animatedImageOQ;
}

UIImage *RCTBlurredImageWithRadiusv(UIImage *inputImage, CGFloat radius)
{
	CGImageRef imageRef = inputImage.CGImage;
	CGFloat imageScale = inputImage.scale;
	UIImageOrientation imageOrientation = inputImage.imageOrientation;
	
	// Image must be nonzero size
	if (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) == 0) {
		return inputImage;
	}
	
	//convert to ARGB if it isn't
	if (CGImageGetBitsPerPixel(imageRef) != 32 ||
		CGImageGetBitsPerComponent(imageRef) != 8 ||
		!((CGImageGetBitmapInfo(imageRef) & kCGBitmapAlphaInfoMask))) {
		UIGraphicsBeginImageContextWithOptions(inputImage.size, NO, inputImage.scale);
		[inputImage drawAtPoint:CGPointZero];
		imageRef = UIGraphicsGetImageFromCurrentImageContext().CGImage;
		UIGraphicsEndImageContext();
	}
	
	vImage_Buffer buffer1, buffer2;
	buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
	buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
	buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
	size_t bytes = buffer1.rowBytes * buffer1.height;
	buffer1.data = malloc(bytes);
	buffer2.data = malloc(bytes);
	
	// A description of how to compute the box kernel width from the Gaussian
	// radius (aka standard deviation) appears in the SVG spec:
	// http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
	uint32_t boxSize = floor((radius * imageScale * 3 * sqrt(2 * M_PI) / 4 + 0.5) / 2);
	boxSize |= 1; // Ensure boxSize is odd
	
	//create temp buffer
	void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
																 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
	
	//copy image data
	CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
	memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
	CFRelease(dataSource);
	
	//perform blur
	vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
	vImageBoxConvolve_ARGB8888(&buffer2, &buffer1, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
	vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
	
	//free buffers
	free(buffer2.data);
	free(tempBuffer);
	
	//create image context from buffer
	CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
											 8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
											 CGImageGetBitmapInfo(imageRef));
	
	//create image from context
	imageRef = CGBitmapContextCreateImage(ctx);
	UIImage *outputImage = [UIImage imageWithCGImage:imageRef scale:imageScale orientation:imageOrientation];
	CGImageRelease(imageRef);
	CGContextRelease(ctx);
	free(buffer1.data);
	return outputImage;
}

@interface UIImage (React)
@property (nonatomic, copy) CAKeyframeAnimation *reactKeyframeAnimation;
@end

@interface RCTImageView () {
    NSURLSessionDataTask *_task;
    NSURL *_imageLoadURL;
    long long _totalLength;
    NSMutableData *_data;
    __weak CALayer *_borderWidthLayer;
    id<RCTImageProviderProtocol> _imageProvider;
    CGSize _size;
}

@property (nonatomic) RCTAnimatedImageOperation *animatedImageOperation;
@property (atomic, strong) NSString *pendingImageSourceUri;// The image source that's being loaded from the network
@property (atomic, strong) NSString *imageSourceUri;// The image source that's currently displayed
@end

@implementation RCTImageView

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
	if (self = [super init]) {
		_bridge = bridge;
		self.clipsToBounds = YES;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didMoveToWindow
{
	[super didMoveToWindow];
	if (!self.window) {
		[self cancelImageLoad];
	} else if ([self shouldChangeImageSource]) {
      [self reloadImage];
    }
}

- (void)didReceiveMemoryWarning {
    [self clearImageIfDetached];
}

- (void)appDidEnterBackground {
    [self clearImageIfDetached];
}

- (void)appWillEnterForeground {
    
}

- (void)clearImageIfDetached
{
	if (!self.window) {
		[self clearImage];
	}
}

- (void)setSource:(NSArray *)source
{
	if (![_source isEqualToArray: source]) {
		_source = [source copy];
        self.animatedImage = nil;
		[self updateImage: nil];
		[self reloadImage];
	}
}

- (void)setDefaultImage:(UIImage *)defaultImage
{
	if (_defaultImage != defaultImage) {
		_defaultImage = defaultImage;
        [self updateImage:_defaultImage];
	}
}

- (void)setCapInsets:(UIEdgeInsets)capInsets
{
	if (!UIEdgeInsetsEqualToEdgeInsets(_capInsets, capInsets)) {
		if (UIEdgeInsetsEqualToEdgeInsets(_capInsets, UIEdgeInsetsZero) ||
			UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
			_capInsets = capInsets;
			[self reloadImage];
		} else {
			_capInsets = capInsets;
			[self updateImage: self.image];
		}
	}
}

- (void)setBlurRadius:(CGFloat)blurRadius
{
	if (blurRadius != _blurRadius) {
		_blurRadius = blurRadius;
		[self reloadImage];
	}
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    _size = frame.size;
    //display:none属性下，frame会置为0，导致ImageView不会加载图片
    //已经有同source的image正在load的情况下不reload
    if (nil == self.image && [self shouldChangeImageSource]) {
        [self reloadImage];
    }
}

- (void)setResizeMode:(RCTResizeMode)resizeMode
{
	if (_resizeMode != resizeMode) {
		_resizeMode = resizeMode;
		
		if (_resizeMode == RCTResizeModeRepeat) {
			self.contentMode = UIViewContentModeScaleToFill;
		} else {
			self.contentMode = (UIViewContentMode)resizeMode;
		}
	}
}

- (void)setRenderingMode:(UIImageRenderingMode)renderingMode
{
	if (_renderingMode != renderingMode) {
		_renderingMode = renderingMode;
		[self updateImage: self.image];
	}
}

- (BOOL)shouldChangeImageSource
{
// We need to reload if the desired image source is different from the current image
// source AND the image load that's pending
    NSDictionary *source = [self.source firstObject];
    if (source) {
        NSString *desiredImageSource = source[@"uri"];
  
        return ![desiredImageSource isEqual:self.imageSourceUri] &&
        ![desiredImageSource isEqual:self.pendingImageSourceUri];
    }
    return NO;
}

- (void)reloadImage
{
    NSDictionary *source = [self.source firstObject];
	if (source && CGRectGetWidth(self.frame) > 0 && CGRectGetHeight(self.frame) > 0) {
		if (_onLoadStart) {
			_onLoadStart(@{});
		}
        NSString *uri = source[@"uri"];
        self.pendingImageSourceUri = uri;
        BOOL isBlurredImage = NO;
        UIImage *image = [[RCTImageCacheManager sharedInstance] loadImageFromCacheForURLString:uri radius:_blurRadius isBlurredImage:&isBlurredImage];
        if (image) {
            [self loadImage:image url:uri error:nil needBlur:!isBlurredImage needCache:NO];
            return;
        }
        //直接使用[NSURL URLWithString:]无法将带有特殊符号的字符串转化为URL
        NSData *uriData = [uri dataUsingEncoding:NSUTF8StringEncoding];
        if (nil == uriData) {
            return;
        }
        CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
        NSURL *source_url = CFBridgingRelease(urlRef);
        if ([RCTBridge isRCTLocalFileURLString:uri]) {
            NSString *localPath = [_bridge absoluteStringFromRCTLocalFileURLString:uri];
            BOOL isDirectory = NO;
            BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDirectory];
            if (fileExist && !isDirectory) {
                NSData *imageData = [NSData dataWithContentsOfFile:localPath];
                Class<RCTImageProviderProtocol> ipClass = imageProviderClass(imageData, self.bridge);
                id<RCTImageProviderProtocol> instance = [self instanceImageProviderFromClass:ipClass imageData:imageData];
                BOOL isAnimatedImage = [ipClass isAnimatedImage:imageData];
                if (isAnimatedImage) {
                    if (_animatedImageOperation) {
                        [_animatedImageOperation cancel];
                    }
                    _animatedImageOperation = [[RCTAnimatedImageOperation alloc] initWithAnimatedImageProvider:instance imageView:self imageURL:source[@"uri"]];
                    [animated_image_queue() addOperation:_animatedImageOperation];
                }
                else {
                    UIImage *image = [instance image];
                    [self loadImage:image url:source_url.absoluteString error:nil needBlur:YES needCache:YES];
                }
            }
            else {
                NSError *error = [NSError errorWithDomain:RCTLocalFileReadErrorDomain code:RCTLocalFileNOFilExist userInfo:@{@"fileExist": @(fileExist), @"isDirectory": @(isDirectory), @"uri": uri}];
                [self loadImage:nil url:source_url.absoluteString error:error needBlur:YES needCache:NO];
            }
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        
        // 处理base64图片
        typedef void (^HandleBase64CompletedBlock)(NSString *);
        HandleBase64CompletedBlock handleBase64CompletedBlock = ^void(NSString *base64Data) {
            NSRange range = [base64Data rangeOfString:@";base64,"];
            if (NSNotFound != range.location) {
                base64Data = [base64Data substringFromIndex:range.location + range.length];
                NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Data
                                                                        options: NSDataBase64DecodingIgnoreUnknownCharacters];
                Class<RCTImageProviderProtocol> ipClass = imageProviderClass(imageData, self.bridge);
                id<RCTImageProviderProtocol> instance = [self instanceImageProviderFromClass:ipClass imageData:imageData];
                BOOL isAnimatedImage = [ipClass isAnimatedImage:imageData];
                if (isAnimatedImage) {
                    if (weakSelf.animatedImageOperation) {
                        [weakSelf.animatedImageOperation cancel];
                    }
                    weakSelf.animatedImageOperation = [[RCTAnimatedImageOperation alloc] initWithAnimatedImageProvider:instance imageView:self imageURL:source[@"uri"]];
                    [animated_image_queue() addOperation:weakSelf.animatedImageOperation];
                }
                else {
                    UIImage *image = [instance image];
                    NSError *error = nil;
                    if (!image) {
                        error = [NSError errorWithDomain: NSURLErrorDomain code: -1 userInfo: @{NSLocalizedDescriptionKey: @"base64 url is invalidated"}];
                    }
                    [weakSelf loadImage: image url: source[@"uri"] error: error needBlur:YES needCache:YES];
                }
            }
        };
        
        // 处理普通图片
        typedef void(^HandleImageCompletedBlock)(NSURL *);
        HandleImageCompletedBlock handleImageCompletedBlock = ^void(NSURL *source_url) {
            [weakSelf.bridge.imageLoader imageView:weakSelf loadAtUrl:source_url placeholderImage:weakSelf.defaultImage context: NULL progress:^(long long currentLength, long long totalLength) {
                if (weakSelf.onProgress) {
                    weakSelf.onProgress(@{@"loaded": @((double)currentLength), @"total": @((double)totalLength)});
                }
            } completed:^(NSData *data, NSURL *url, NSError *error) {
                Class<RCTImageProviderProtocol> ipClass = imageProviderClass(data, self.bridge);
                id<RCTImageProviderProtocol> instance = [self instanceImageProviderFromClass:ipClass imageData:data];
                BOOL isAnimatedImage = [ipClass isAnimatedImage:data];
                if (isAnimatedImage) {
                    if (weakSelf.animatedImageOperation) {
                        [weakSelf.animatedImageOperation cancel];
                    }
                    weakSelf.animatedImageOperation = [[RCTAnimatedImageOperation alloc] initWithAnimatedImageProvider:instance imageView:self imageURL:source[@"uri"]];
                    [animated_image_queue() addOperation:weakSelf.animatedImageOperation];
                }
                else {
                    UIImage *image = [instance image];
                    NSError *error = nil;
                    if (!image) {
                        error = [NSError errorWithDomain: NSURLErrorDomain code: -1 userInfo: @{NSLocalizedDescriptionKey: @"base64 url is invalidated"}];
                    }
                    [weakSelf loadImage: image url: source[@"uri"] error: error needBlur:YES needCache:YES];
                }
            }];
        };
        
        
        // base64图片也会走此逻辑
		if(_bridge.imageLoader && source_url) {
            if (_defaultImage) {
                weakSelf.image = _defaultImage;
            }
            
            if ([[source_url absoluteString] hasPrefix: @"data:image/"]) {
                handleBase64CompletedBlock([source_url absoluteString]);
            } else {
                if (_imageLoadURL) {
                    [_bridge.imageLoader cancelImageDownload:self withUrl:_imageLoadURL];
                }
                _imageLoadURL = source_url;
                handleImageCompletedBlock(source_url);
            }
            
		} else {
			if ([uri hasPrefix: @"data:image/"]) {
                handleBase64CompletedBlock(uri);
			}
            else {
                if (_task) {
                    [self cancelImageLoad];
                }
                //这里使用defaultSessionConfiguration会导致crash
                //初步判断是系统URLResponse中的某个CFString over-release导致。
                //为了避免崩溃使用ephemeralSessionConfiguration，代价是无法使用cache
                NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
                NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate: self delegateQueue:rct_image_queue()];
                _task = [session dataTaskWithURL:source_url];
                [_task resume];
            }
		}
	}
}

- (void)cancelImageLoad
{
    self.pendingImageSourceUri = nil;
	NSDictionary *source = [self.source firstObject];
	if (_bridge.imageLoader) {
        [_animatedImageOperation cancel];
        _animatedImageOperation = nil;
		[_bridge.imageLoader cancelImageDownload: self withUrl: source[@"uri"]];
	} else {
		[_task cancel];
		_task = nil;
        //_data进行多线程操作导致不安全，需要将_data的操作放在同一个串行队列中
        [rct_image_queue() addOperationWithBlock:^{
            self->_data = nil;
            self->_totalLength = 0;
        }];
	}
}

- (void)clearImage
{
	[self cancelImageLoad];
	[self.layer removeAnimationForKey:@"contents"];
	self.image = nil;
    self.imageSourceUri = nil;
}

- (UIImage *) imageFromData:(NSData *)data {
    if (nil == data) {
        return nil;
    }
    Class<RCTImageProviderProtocol> ipClass = imageProviderClass(data, self.bridge);
    id<RCTImageProviderProtocol> instance = [self instanceImageProviderFromClass:ipClass imageData:data];
    return [instance image];
}

#pragma mark  -
- (void)URLSession:(__unused NSURLSession *)session dataTask:(__unused NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if (_task == dataTask) {
        _totalLength = response.expectedContentLength;
        completionHandler(NSURLSessionResponseAllow);
        NSUInteger capacity = NSURLResponseUnknownLength != _totalLength ? (NSUInteger)_totalLength : 256;
        _data = [[NSMutableData alloc] initWithCapacity:capacity];
    }
}

- (void)URLSession:(__unused NSURLSession *)session dataTask:(__unused NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (_task == dataTask) {
        if (_onProgress && NSURLResponseUnknownLength != _totalLength) {
            _onProgress(@{@"loaded": @((double)data.length), @"total": @((double)_totalLength)});
        }
        [_data appendData: data];
    }
}

- (void)URLSession:(__unused NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if (_task == task) {
        NSString *urlString = [[[task originalRequest] URL] absoluteString];
        if (!error) {
            if ([_data length] > 0) {
                Class<RCTImageProviderProtocol> ipClass = imageProviderClass(_data, self.bridge);
                id<RCTImageProviderProtocol> instance = [self instanceImageProviderFromClass:ipClass imageData:_data];
                BOOL isAnimatedImage = [ipClass isAnimatedImage:_data];
                if (isAnimatedImage) {
                    if (_animatedImageOperation) {
                        [_animatedImageOperation cancel];
                    }
                    _animatedImageOperation = [[RCTAnimatedImageOperation alloc] initWithAnimatedImageProvider:instance imageView:self imageURL:urlString];
                    [animated_image_queue() addOperation:_animatedImageOperation];
                }
                else {
                    [[RCTImageCacheManager sharedInstance] setImageCacheData:_data forURLString:urlString];
                    UIImage *image = [instance image];
                    //这里可能会转换失败，要抛出错误
                    if (image) {
                        [self loadImage: image url:urlString error:nil needBlur:YES needCache:YES];
                    } else {
                        NSError *theError = [NSError errorWithDomain:@"imageFromDataErrorDomain" code:1 userInfo:@{@"reason": @"Error in imageFromData"}];
                        [self loadImage: nil url:urlString error:theError needBlur:YES needCache:YES];
                    }
                }
            }
            else {
                NSURLResponse *response = [task response];
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSUInteger statusCode = [httpResponse statusCode];
                    NSString *errorMessage = [NSString stringWithFormat:@"no data received, HTTPStatusCode is %zd", statusCode];
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorMessage};
                    NSError *error = [NSError errorWithDomain:@"ImageLoadDomain" code:1 userInfo:userInfo];
                    [self loadImage:nil url:urlString error:error needBlur:NO needCache:NO];
                }
            }
        } else {
            [self loadImage:nil url:urlString error:error needBlur:YES needCache:YES];
        }
    }
    [session finishTasksAndInvalidate];
}

#pragma mark -


- (void)loadImage:(UIImage *)image url:(NSString *)url error:(NSError *)error needBlur:(BOOL)needBlur needCache:(BOOL)needCache
{
	if (error) {
		if (_onError && error.code != NSURLErrorCancelled) {
			_onError(@{@"error": error.localizedDescription});
		}
		if (_onLoadEnd) {
			_onLoadEnd(nil);
		}
		return;
	}
	
	__weak typeof(self) weakSelf = self;
	void (^setImageBlock)(UIImage *) = ^(UIImage *image) {
        weakSelf.pendingImageSourceUri = nil;
        weakSelf.imageSourceUri = url;
		if (image.reactKeyframeAnimation) {
			[weakSelf.layer addAnimation:image.reactKeyframeAnimation forKey:@"contents"];
		} else {
			[weakSelf.layer removeAnimationForKey:@"contents"];
			[weakSelf updateImage: image];
		}
		
		if (weakSelf.onLoad)
			weakSelf.onLoad(@{@"width": @(image.size.width),@"height": @(image.size.height), @"url":url ? :@""});
		if (weakSelf.onLoadEnd)
			weakSelf.onLoadEnd(nil);
	};
    
    //1GB内存手机 限制模糊半径，粗略规避下内存问题
    if (_blurRadius > 100 && [NSProcessInfo processInfo].physicalMemory <= 1024 * 1024 * 1000) {
        _blurRadius = 100;
    }
    
    CGFloat br = _blurRadius;
	if (_blurRadius > __FLT_EPSILON__ && needBlur) {
		// Blur on a background thread to avoid blocking interaction
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			UIImage *blurredImage = RCTBlurredImageWithRadiusv(image, br);
            if (needCache) {
                [[RCTImageCacheManager sharedInstance] setImage:blurredImage forURLString:url blurRadius:br];
            }
			RCTExecuteOnMainQueue(^{
				setImageBlock(blurredImage);
			});
		});
	} else {
		RCTExecuteOnMainQueue(^{
            if (needCache) {
                [[RCTImageCacheManager sharedInstance] setImage:image forURLString:url blurRadius:br];
            }
			setImageBlock(image);
		});
	}
}

- (void)updateImage:(UIImage *)image
{
	image = image ? : _defaultImage;
	if (!image) {
		self.image = nil;
		return;
	}
	
	if (_renderingMode != image.renderingMode) {
		image = [image imageWithRenderingMode:_renderingMode];
	}
	
	if (_resizeMode == RCTResizeModeRepeat) {
		image = [image resizableImageWithCapInsets: _capInsets resizingMode: UIImageResizingModeTile];
	} else if (!UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _capInsets)) {
		// Applying capInsets of 0 will switch the "resizingMode" of the image to "tile" which is undesired
		image = [image resizableImageWithCapInsets:_capInsets resizingMode:UIImageResizingModeStretch];
    } else if (_isGray) {
        image = [self grayImage:image];
    }
	
	// Apply trilinear filtering to smooth out mis-sized images
//    self.layer.minificationFilter = kCAFilterTrilinear;
//    self.layer.magnificationFilter = kCAFilterTrilinear;

    if (image.images) {
        RCTAssert(NO, @"GIF图片不应该进入这个逻辑");
	}
	else {
		self.image = image;
        [self updateCornerRadius];
	}
}

- (UIImage *)grayImage:(UIImage *)image {
    const int RED = 1 ;
    const int GREEN = 2 ;
    const int BLUE = 3 ;
    CGFloat scale = image.scale;

    int width = image.size.width * scale;
    int height = image.size.height * scale;

    uint32_t *pixels = (uint32_t *)malloc(width * height * sizeof(uint32_t));
    memset(pixels, 0, width * height * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 8,
                                                 width * sizeof ( uint32_t ),
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast );

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);

    for (int y = 0 ; y < height; y++) {
        for (int x = 0 ; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
           
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }

    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    CGContextRelease (context);
    CGColorSpaceRelease (colorSpace);
    free (pixels);

    UIImage *resultUIImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease (imageRef);

    return resultUIImage;
}

- (void) updateCornerRadius {
    if (_borderWidthLayer) {
        [_borderWidthLayer removeFromSuperlayer];
    }
    if ([self needsUpdateCornerRadius]) {
        CGRect contentRect = UIEdgeInsetsInsetRect(self.bounds, _capInsets);
        
#ifdef RCTLog
        CGFloat width = CGRectGetWidth(contentRect);
        CGFloat height = CGRectGetHeight(contentRect);
        BOOL flag1 = _borderTopLeftRadius <= MIN(width, height) / 2;
        if (!flag1) {
            RCTLog(@"[warning] _borderTopLeftRadius must be shorter than width / 2");
        }
        BOOL flag2 = _borderTopRightRadius <= MIN(width, height) / 2;
        if (!flag2) {
            RCTLog(@"[warning] _borderTopRightRadius must be shorter than width / 2");
        }
        BOOL flag3 = _borderBottomLeftRadius <= MIN(width, height) / 2;
        if (!flag3) {
            RCTLog(@"[warning] _borderBottomLeftRadius must be shorter than width / 2");
        }
        BOOL flag4 = _borderBottomRightRadius <= MIN(width, height) / 2;
        if (!flag4) {
            RCTLog(@"[warning] _borderBottomRightRadius must be shorter than width / 2");
        }
#endif
        
        CGFloat minX = CGRectGetMinX(contentRect);
        CGFloat minY = CGRectGetMinY(contentRect);
        CGFloat maxX = CGRectGetMaxX(contentRect);
        CGFloat maxY = CGRectGetMaxY(contentRect);
        
        UIBezierPath *bezierPath = [UIBezierPath bezierPath];
        CGPoint p1 = CGPointMake(minX + _borderTopLeftRadius, minY);
        [bezierPath moveToPoint:p1];
        CGPoint p2 = CGPointMake(maxX - _borderTopRightRadius, minY);
        [bezierPath addLineToPoint:p2];
        CGPoint p3 = CGPointMake(maxX - _borderTopRightRadius, minY + _borderTopRightRadius);
        [bezierPath addArcWithCenter:p3 radius:_borderTopRightRadius startAngle:M_PI_2 + M_PI endAngle:0 clockwise:YES];
        
        CGPoint p4 = CGPointMake(maxX, maxY - _borderBottomRightRadius);
        [bezierPath addLineToPoint:p4];
        CGPoint p5 = CGPointMake(maxX - _borderBottomRightRadius, maxY - _borderBottomRightRadius);
        [bezierPath addArcWithCenter:p5 radius:_borderBottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
        CGPoint p6 = CGPointMake(minX + _borderBottomLeftRadius, maxY);
        [bezierPath addLineToPoint:p6];
        CGPoint p7 = CGPointMake(minX + _borderBottomLeftRadius, maxY - _borderBottomLeftRadius);
        [bezierPath addArcWithCenter:p7 radius:_borderBottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
        CGPoint p8 = CGPointMake(minX, minY + _borderTopLeftRadius);
        [bezierPath addLineToPoint:p8];
        CGPoint p9 = CGPointMake(minX + _borderTopLeftRadius, minY + _borderTopLeftRadius);
        [bezierPath addArcWithCenter:p9 radius:_borderTopLeftRadius startAngle:M_PI endAngle:M_PI + M_PI_2 clockwise:YES];
        [bezierPath closePath];
        
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = bezierPath.CGPath;
        self.layer.mask = mask;
        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.path = bezierPath.CGPath;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        borderLayer.strokeColor = self.layer.borderColor;
        borderLayer.lineWidth = self.layer.borderWidth * 2;
        borderLayer.frame = contentRect;
        _borderWidthLayer = borderLayer;
        [self.layer addSublayer:borderLayer];
    }
    else {
        self.layer.mask = nil;
    }
}

- (BOOL) needsUpdateCornerRadius {
    if (_borderTopLeftRadius > CGFLOAT_MIN ||
        _borderTopRightRadius > CGFLOAT_MIN ||
        _borderBottomLeftRadius > CGFLOAT_MIN ||
        _borderBottomRightRadius > CGFLOAT_MIN) {
        return YES;
    }
    return NO;
}

- (id<RCTImageProviderProtocol>) instanceImageProviderFromClass:(Class<RCTImageProviderProtocol>)cls imageData:(NSData *)data {
    id<RCTImageProviderProtocol> instance = [cls imageProviderInstanceForData:data];
    if ([instance isKindOfClass:[RCTDefaultImageProvider class]]) {
        RCTDefaultImageProvider *provider = (RCTDefaultImageProvider *)instance;
        provider.imageViewSize = _size;
        provider.needsDownSampling = _needDownsampleing;
    }
    return instance;
}

@end

@implementation UIImage (React)

- (CAKeyframeAnimation *)reactKeyframeAnimation
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactKeyframeAnimation:(CAKeyframeAnimation *)reactKeyframeAnimation
{
	objc_setAssociatedObject(self, @selector(reactKeyframeAnimation), reactKeyframeAnimation, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation RCTConvert(RCTResizeMode)

RCT_ENUM_CONVERTER(RCTResizeMode, (@{
									 @"cover": @(RCTResizeModeCover),
									 @"contain": @(RCTResizeModeContain),
									 @"stretch": @(RCTResizeModeStretch),
									 @"center": @(RCTResizeModeCenter),
									 @"repeat": @(RCTResizeModeRepeat),
									 }), RCTResizeModeStretch, integerValue)

@end



@implementation RCTAnimatedImageOperation

- (id) initWithAnimatedImageData:(NSData *)data imageView:(RCTImageView *)imageView imageURL:(NSString *)url isSharpP:(BOOL)isSharpP {
    self = [super init];
    if (self) {
        _animatedImageData = data;
        _url = url;
        _imageView = imageView;
        _isSharpP = isSharpP;
    }
    return self;
}

- (id) initWithAnimatedImageProvider:(id<RCTImageProviderProtocol>)imageProvider imageView:(RCTImageView *)imageView imageURL:(NSString *)url {
    self = [super init];
    if (self) {
        _imageProvider = imageProvider;
        _url = url;
        _imageView = imageView;
    }
    return self;
}

- (void) main {
    if (![self isCancelled] && (_animatedImageData || _imageProvider) &&_imageView) {
        RCTAnimatedImage *animatedImage  = nil;
        if (_imageProvider) {
            animatedImage = [RCTAnimatedImage animatedImageWithAnimatedImageProvider:_imageProvider];
        }
        else if (_animatedImageData) {
            animatedImage = [RCTAnimatedImage animatedImageWithGIFData:_animatedImageData];
        }
        if (![self isCancelled] && _imageView) {
            __weak RCTImageView *wIV = _imageView;
            __weak NSString *wURL = _url;
            dispatch_async(dispatch_get_main_queue(), ^{
                RCTImageView *sIV = wIV;
                NSString *sURL = wURL;
                [sIV loadImage:animatedImage.posterImage url:sURL error:nil needBlur:NO needCache:NO];
                sIV.animatedImage = animatedImage;
            });
        }
    }
}

@end
