//
//  RCTImageProviderProtocol.h
//  hippy
//
//  Created by ozonelmy on 2020/8/4.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"

@class UIImage;
@class RCTBridge;

@protocol RCTImageProviderProtocol <NSObject, RCTBridgeModule>

@required
/** 询问类能否处理当前图像数据
 */
+ (BOOL)canHandleData:(NSData *)data;
/** 询问类当前图像数据是否是动图(GIF,APNG,etc)
 */
+ (BOOL)isAnimatedImage:(NSData *)data;
/** 获取针前图像数据，使用当前类处理的优先级
 *  优先级高的类将优先处理当前数据
 *  比如某个data，cls1与cls2的 `canHandleData`方法都返回YES，
 *  但是priorityForData方法分别返回1与2
 *  则系统会使用cls2进行数据处理
 */
+ (NSUInteger)priorityForData:(NSData *)data;

/** 根据数据创建图像处理类实例
 */
+ (instancetype)imageProviderInstanceForData:(NSData *)data;

/** 返回图像。如果是动图，建议返回第一帧。
 */
- (UIImage *)image;

//Animated Image
@optional
/** 若是动图，则返回动图帧数。
 *  若是动图，此方法必须实现。
 */
- (NSUInteger)imageCount;
/** 返回第frame帧图片
 *  若是动图，此方法必须实现。
 */
- (UIImage *)imageAtFrame:(NSUInteger)frame;
/**动图循环次数，0表示一直循环播放。
*  若是动图，此方法必须实现。
*/
- (NSUInteger)loopCount;
/** 特定帧的延迟播放时间
 */
- (NSTimeInterval)delayTimeAtFrame:(NSUInteger)frame;

@end

#ifdef __cplusplus
extern "C" {
#endif

Class<RCTImageProviderProtocol> imageProviderClass(NSData *data, RCTBridge *bridge);

#ifdef __cplusplus
}
#endif
