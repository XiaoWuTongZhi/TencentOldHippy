//
//  HPAnimationGroup.h
//  HippyNative
//
//  Created by pennyli on 2017/12/26.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#import "RCTExtAnimation.h"

@interface RCTExtAnimationGroup : RCTExtAnimation

@property (nonatomic, strong) NSArray<RCTExtAnimation *> *animations;
//这个参数表明这个动画组只是为了时序管理，并不真正绑定在某个view上
@property (nonatomic, assign) BOOL virtualAnimation;
@end
