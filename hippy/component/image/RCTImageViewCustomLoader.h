//
//  RCTImageViewV2CustomLoader.h
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/21.
//  Copyright © 2018年 刘海波. All rights reserved.
//


#import "RCTBridgeModule.h"
@class RCTImageView;

@protocol RCTImageViewCustomLoader<RCTBridgeModule>

@required

- (void)imageView:(RCTImageView *)imageView
		loadAtUrl:(NSURL *)url
 placeholderImage:(UIImage *)placeholderImage
		  context:(void *)context
		 progress:(void (^)(long long, long long))progressBlock
		completed:(void (^)(NSData *, NSURL *, NSError *))completedBlock;

- (void)cancelImageDownload:(UIImageView *)imageView withUrl:(NSURL *)url;

/**
*  单纯拉取图片
*/
- (void)loadImage:(NSURL *)url completed:(void (^)(NSData *, NSURL *, NSError *, BOOL cached))completedBlock;
@end
