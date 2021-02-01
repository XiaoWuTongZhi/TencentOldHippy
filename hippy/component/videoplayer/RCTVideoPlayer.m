
//
//  RCTVideoPlayer.m
//  Hippy
//
//  Created by 万致远 on 2019/4/29.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTVideoPlayer.h"

#import "UIView+React.h"

@interface RCTVideoPlayer ()
//视频播放器
@property (nonatomic,strong) AVPlayer *avplayer;
@property (nonatomic,strong) AVPlayerLayer *avplayerLayer;
@property (nonatomic,strong) AVPlayerItem *playerItem;

@end

#define KScreemWidth  [UIScreen mainScreen].bounds.size.width
#define KScreemHeight  [UIScreen mainScreen].bounds.size.height


@implementation RCTVideoPlayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)reactSetFrame:(CGRect)frame {
    [super reactSetFrame:frame];
    self.avplayerLayer.frame = self.bounds;
}

- (AVPlayerLayer *)avplayerLayer {
    if (_avplayer) {
        //显示画面
        _avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avplayer];
        //视频填充模式
        _avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        //设置画布frame
        _avplayerLayer.frame = self.bounds;
        //添加到当前视图
        [self.layer addSublayer:_avplayerLayer];
    }
    return _avplayerLayer;
}

//监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            if (self.onLoad) {
                self.onLoad(@{});
            }
            if (self.autoPlay) {
                [self.avplayer play];
            }
            
        } else{
        }
    }
}

- (void)setSrc:(NSString *)src {
//    @"https://test-1252808551.cos.ap-chengdu.myqcloud.com/2.mp4"
    NSData *uriData = [src dataUsingEncoding:NSUTF8StringEncoding];
    CFURLRef urlRef = CFURLCreateWithBytes(NULL, [uriData bytes], [uriData length], kCFStringEncodingUTF8, NULL);
    NSURL *mediaUrl = CFBridgingRelease(urlRef);
    
    
    // 初始化播放单元
    self.playerItem = [AVPlayerItem playerItemWithURL:mediaUrl];
    
    //初始化播放器对象
    self.avplayer = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    
    //添加监听
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // 添加视频播放结束通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

//播放结束的回调
- (void)moviePlayDidEnd:(NSNotification *)notification {
//    __weak typeof(self) weakSelf = self;
    [self.avplayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if (self.loop) {
            [self.avplayer play];
        }
//        [weakSelf.videoSlider setValue:0.0 animated:YES];
//        [weakSelf.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }];
}

#pragma mark - Action Methods
// 播放
- (void)play {
    [self.avplayer play];
}

- (void)pause {
    [self.avplayer pause];
    
}

- (void)seekToTime:(CMTime)time {
    [self.avplayer seekToTime:time];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}
    

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
