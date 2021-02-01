//
//  RCTVideoPlayerManager.m
//  Hippy
//
//  Created by 万致远 on 2019/4/29.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTVideoPlayerManager.h"
#import "RCTVideoPlayer.h"

@implementation RCTVideoPlayerManager

RCT_EXPORT_MODULE(VideoView)

- (UIView *)view
{
    return [RCTVideoPlayer new];
}

RCT_EXPORT_VIEW_PROPERTY(src, NSString)
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL)
RCT_EXPORT_VIEW_PROPERTY(loop, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        UIView *view = viewRegistry[reactTag];
        if (view == nil || ![view isKindOfClass:[RCTVideoPlayer class]]) {
            RCTLogError(@"tried to setPage: on an error viewPager %@ "
                        "with tag #%@", view, reactTag);
        }
        RCTVideoPlayer *videoPlayer = (RCTVideoPlayer *)view;
        [videoPlayer play];
    }];
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        UIView *view = viewRegistry[reactTag];
        if (view == nil || ![view isKindOfClass:[RCTVideoPlayer class]]) {
            RCTLogError(@"tried to setPage: on an error viewPager %@ "
                        "with tag #%@", view, reactTag);
        }
        RCTVideoPlayer *videoPlayer = (RCTVideoPlayer *)view;
        [videoPlayer pause];
    }];
}

RCT_EXPORT_METHOD(seek:(nonnull NSNumber *)reactTag
                  theTime:(__unused NSNumber *)theTime//毫秒单位
                  ) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        UIView *view = viewRegistry[reactTag];
        if (view == nil || ![view isKindOfClass:[RCTVideoPlayer class]]) {
            RCTLogError(@"tried to setPage: on an error viewPager %@ "
                        "with tag #%@", view, reactTag);
        }
        RCTVideoPlayer *videoPlayer = (RCTVideoPlayer *)view;
        NSInteger seceonds = theTime.integerValue / 1000.0;
        [videoPlayer seekToTime:CMTimeMakeWithSeconds(seceonds, 1)];
    }];
}
@end
