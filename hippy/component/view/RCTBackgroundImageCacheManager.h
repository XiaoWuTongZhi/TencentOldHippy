//
//  RCTBackgroundImageCacheManager.h
//  QBCommonRNLib
//
//  Created by 万致远 on 2018/8/28.
//  Copyright © 2018年 刘海波. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCTBackgroundImageCacheManager : NSObject
@property(strong, nonatomic) dispatch_queue_t g_background_queue;

typedef void(^RCTBackgroundImageCompletionHandler)(UIImage* decodedImage, NSError *error);
+ (RCTBackgroundImageCacheManager *)sharedInstance;

- (void)imageWithUrl:(NSString *)url
               frame:(CGRect)frame
            reactTag:(NSNumber *)reactTag
             handler:(RCTBackgroundImageCompletionHandler)completionHandler ;
//释放
- (void)releaseBackgroundImageCacheWithUrl:(NSString *)uri
                                     frame:(CGRect)frame
                                  reactTag:(NSNumber *)reactTag;
@end
