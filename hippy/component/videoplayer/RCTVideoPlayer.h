//
//  RCTVideoPlayer.h
//  Hippy
//
//  Created by 万致远 on 2019/4/29.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTView.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTVideoPlayer : RCTView
- (void)play;
- (void)pause;
- (void)seekToTime:(CMTime)time;
@property (nonatomic, strong) NSString *src;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, strong) RCTDirectEventBlock onLoad;
@end

NS_ASSUME_NONNULL_END
