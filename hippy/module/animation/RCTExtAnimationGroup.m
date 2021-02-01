//
//  HPAnimationGroup.m
//  HippyNative
//
//  Created by pennyli on 2017/12/26.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#import "RCTExtAnimationGroup.h"
#import "RCTLog.h"
#import <objc/runtime.h>
#import "RCTExtAnimation+Group.h"
#import "RCTExtAnimation+Value.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmacro-redefined"
#define RCTLogInfo(...) do{}while(0)
#pragma clang diagnostic pop

@implementation RCTExtAnimationGroup

- (void)setAnimations:(NSArray<RCTExtAnimation *> *)animations
{
    _animations = animations;
    [self setupAnimation: animations];
}

- (double)startValue
{
	RCTExtAnimation *fist = [_animations firstObject];
	return fist.startValue;
}

- (double)endValue
{
    RCTExtAnimation *last = [_animations lastObject];
    return last.endValue;
}

- (void)setupAnimation:(NSArray<RCTExtAnimation *> *)animations
{
    __block RCTExtAnimation *lastAnimation = nil;
    __block NSTimeInterval duration = 0;

    [animations enumerateObjectsUsingBlock:^(RCTExtAnimation * ani, __unused NSUInteger idx, __unused BOOL *stop) {
        if (lastAnimation) {
            if (ani.bFollow) {
                duration += ani.duration + ani.delay;
                ani.beginTime = lastAnimation.beginTime + lastAnimation.duration + ani.delay;
            } else {
                if ((lastAnimation.duration + lastAnimation.delay) < (ani.duration + lastAnimation.delay)) {
                    duration -= (lastAnimation.duration + lastAnimation.delay);
                    duration += (ani.duration + ani.delay);
                }
                ani.beginTime = lastAnimation.beginTime + ani.delay;
            }
        } else {
            duration += ani.duration + ani.delay;
            ani.beginTime = ani.delay;
        }
        lastAnimation = ani;
    }];

    self.duration = duration;
    RCTLogInfo(@"animationGroup:%@ duration:%@",self.animationId, @(duration));
    _animations = animations;
}

- (CAAnimation *)animationOfView:(UIView *)view forProp:(NSString *)prop
{
    NSMutableArray *ca_animations = [NSMutableArray arrayWithCapacity: _animations.count];
    __block RCTExtAnimation *firstAnimaiton = nil;
    RCTLogInfo(@"--------animaiton start [%@]--------", prop);
    [_animations enumerateObjectsUsingBlock:^(RCTExtAnimation * ani, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        CABasicAnimation *ca_ani = (CABasicAnimation *)[ani animationOfView: view forProp: prop];
        if (ca_ani) {
            [ca_ani setValue: ani.animationId forKey: @"animationID"];
            ca_ani.beginTime = ani.beginTime;
            if (firstAnimaiton) {
                if ([prop isEqualToString: @"top"]) {
                    CGPoint center = view.center;
                    self.fromValue = @(center.y);
                    self.toValue = @(center.y - (self.startValue - self.endValue));
                } else if ([prop isEqualToString: @"bottom"]) {
                    CGPoint center = view.center;
                    self.fromValue = @(center.y);
                    self.toValue = @(center.y + (self.startValue - self.endValue));
                } else if ([prop isEqualToString: @"left"]) {
                    CGPoint center = view.center;
                    self.fromValue = @(center.x);
                    self.toValue = @(center.x - (self.startValue - self.endValue));
                } else if ([prop isEqualToString: @"right"]) {
                    CGPoint center = view.center;
                    self.fromValue = @(center.x);
                    self.toValue = @(center.x + (self.startValue - self.endValue));
                }
            }
            [ca_animations addObject: ca_ani];
            if (firstAnimaiton == nil) {
                firstAnimaiton = ani;
            }
            RCTLogInfo(@"--------startValue:%@ tovalue:%@ beginTime:%@ duration:%@", ca_ani.fromValue, ca_ani.toValue, @(ca_ani.beginTime), @(ca_ani.duration));
        }
    }];
    RCTLogInfo(@"--------animation duration:%@", @(self.duration));
    RCTLogInfo(@"--------animaiton end [%@]--------", prop);
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = ca_animations;
    group.repeatCount = self.repeatCount;
    group.duration = self.duration;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    
    return group;
}

@end

@implementation RCTExtAnimation(Group)

- (void)setBeginTime:(NSTimeInterval)beginTime
{
	objc_setAssociatedObject(self, @selector(beginTime), @(beginTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CFTimeInterval)beginTime
{
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setBFollow:(BOOL)bFollow
{
	objc_setAssociatedObject(self, @selector(bFollow), @(bFollow), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bFollow
{
	return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

