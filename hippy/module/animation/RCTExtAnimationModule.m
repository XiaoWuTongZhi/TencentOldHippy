//
//  RCTExtAnimationModule.m
//  HippyNative
//
//  Created by pennyli on 2017/12/25.
//  Copyright © 2017年 pennyli. All rights reserved.
//
//#import "HPJSBridge.h"
//#import "UIView+Hippy.h"
#import "RCTUIManager.h"
#import "RCTExtAnimation.h"
#import "RCTExtAnimationGroup.h"
#import "RCTExtAnimation+Group.h"
#import "RCTExtAnimationModule.h"
#import "RCTExtAnimationViewParams.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmacro-redefined"
#define RCTLogInfo(...) do{}while(0)
#pragma clang diagnostic pop

@implementation RCTExtAnimationIdCount {
    NSMutableDictionary *_animationIdDic;
}
- (instancetype) init {
    self = [super init];
    if (self) {
        _animationIdDic = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void) addCountForAnimationId:(NSNumber *)animationId {
    NSNumber *number = [_animationIdDic objectForKey:animationId];
    [_animationIdDic setObject:@([number unsignedIntegerValue] + 1) forKey:animationId];
}
- (BOOL) subtractionCountForAnimationId:(NSNumber *)animationId {
    NSNumber *number = [_animationIdDic objectForKey:animationId];
    if (number) {
        NSUInteger count = [number unsignedIntegerValue];
        if (count == 1) {
            [_animationIdDic removeObjectForKey:animationId];
            return YES;
        }
        else {
            [_animationIdDic setObject:@(count - 1) forKey:animationId];
            return NO;
        }
    }
    return YES;
}
- (NSUInteger) countForAnimationId:(NSNumber *)animationId {
    NSNumber *count = [_animationIdDic objectForKey:animationId];
    return [count unsignedIntegerValue];
}
@end

@interface RCTExtAnimationModule () <CAAnimationDelegate>
@end

@implementation RCTExtAnimationModule {
    NSMutableDictionary <NSNumber *, RCTExtAnimation *> *_animationById;
    NSMutableDictionary <NSNumber *, NSMutableArray <RCTExtAnimationViewParams *> *> *_paramsByAnimationId;
    NSMutableDictionary <NSNumber *, RCTExtAnimationViewParams *> *_paramsByReactTag;
    NSLock *_lock;
    //  NSMutableArray <NSNumber *> *_virtualAnimations;
    RCTExtAnimationIdCount *_virtualAnimations;
}

//@synthesize executeQueue = _executeQueue;
@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(AnimationModule)

- (dispatch_queue_t)methodQueue {
    return RCTGetUIManagerQueue();
}

- (instancetype)init
{
    if (self = [super init]) {
        _animationById = [NSMutableDictionary new];
        _paramsByReactTag = [NSMutableDictionary new];
        _paramsByAnimationId = [NSMutableDictionary new];
        _lock = [[NSLock alloc] init];
        //      _virtualAnimations = [NSMutableArray array];
        _virtualAnimations = [[RCTExtAnimationIdCount alloc] init];
    }
    return self;
}

- (void)invalidate
{
    [_lock lock];
    [_paramsByAnimationId removeAllObjects];
    [_paramsByReactTag removeAllObjects];
    [_animationById removeAllObjects];
    [_lock unlock];
}

- (BOOL)isRunInDomThread
{
    return YES;
}

//bug：create->destroy->create后，如果不重新render：这个方法无法被调用到
//- (NSDictionary *)bindAnimaiton:(NSDictionary *)params viewTag:(NSNumber *)viewTag rootTag:(NSNumber *)rootTag
RCT_EXPORT_METHOD(createAnimation:(NSNumber *__nonnull)animationId
                  mode:(NSString *)mode
                  params:(NSDictionary *)params)
{
    [_lock lock];
    RCTExtAnimation *ani = [[RCTExtAnimation alloc] initWithMode: mode animationId: animationId config: params];
    [_animationById setObject: ani forKey: animationId];
    [_lock unlock];
    RCTLogInfo(@"create animation Id:%@",animationId);
}

RCT_EXPORT_METHOD(createAnimationSet:(NSNumber *__nonnull)animationId animations:(NSDictionary *)animations)
{
    [_lock lock];
    RCTExtAnimationGroup *group = [[RCTExtAnimationGroup alloc] initWithMode: @"group" animationId: animationId config: animations];
    group.virtualAnimation = [animations[@"virtual"] boolValue];
    NSArray *children = animations[@"children"];
    NSMutableArray *anis = [NSMutableArray arrayWithCapacity: children.count];
    [children enumerateObjectsUsingBlock:^(NSDictionary * info, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
        NSNumber *subAnimationId = info[@"animationId"];
        BOOL follow = [info[@"follow"] boolValue];
        RCTExtAnimation *ani = self->_animationById[subAnimationId];
#ifdef DEBUG
        if (ani == nil) {
            RCTAssert(ani != nil, @"create group animation but use illege sub animaiton");
        }
#endif
        ani.bFollow = follow;
        [anis addObject: ani];
    }];
    group.animations = anis;
    [_animationById setObject: group forKey: animationId];
    
    [_lock unlock];
    
    RCTLogInfo(@"create group animations:%@",animationId);
}

//该方法会调用[RCTExtAnimationModule paramForAnimationId:]，
//进而调用[RCTExtAnimationModule connectAnimationToView]
//在里面执行动画
RCT_EXPORT_METHOD(startAnimation:(NSNumber *__nonnull)animationId)
{
    [_lock lock];
    RCTExtAnimation *ani = _animationById[animationId];
    if (ani.state == RCTExtAnimationStartedState) {
        [_lock unlock];
        RCTLogInfo(@"startAnimation [%@] from [%@] to [%@] not completed", animationId, @(ani.startValue), @(ani.endValue));
        return;
    }
    
    RCTLogInfo(@"startAnimation [%@] from [%@] to [%@]", animationId, @(ani.startValue), @(ani.endValue));
    
    ani.state = RCTExtAnimationReadyState;
    
    if ([ani isKindOfClass:[RCTExtAnimationGroup class]]) {
        RCTExtAnimationGroup *group = (RCTExtAnimationGroup *)ani;
        if (group.virtualAnimation) {
            for (RCTExtAnimation *animation in group.animations) {
                [_virtualAnimations addCountForAnimationId:animationId];
                animation.parentAnimationId = animationId;
                NSNumber *animationId = animation.animationId;
                animation.state = RCTExtAnimationReadyState;
                [self paramForAnimationId:animationId];
            }
        } else {
            [self paramForAnimationId:animationId];
        }
    } else {
        [self paramForAnimationId:animationId];
    }
    [_lock unlock];
}

RCT_EXPORT_METHOD(pauseAnimation:(NSNumber *__nonnull)animationId) {
    [_lock lock];
    NSArray <RCTExtAnimationViewParams *> *params = [_paramsByAnimationId[animationId] copy];
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * _Nonnull param, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
            UIView *view = [self.bridge.uiManager viewForReactTag:param.reactTag];
            CFTimeInterval pausedTime = [view.layer convertTime:CACurrentMediaTime() fromLayer:nil];
            view.layer.speed = 0.0;
            view.layer.timeOffset = pausedTime;
        }];
    }];
    [_lock unlock];
}

RCT_EXPORT_METHOD(resumeAnimation:(NSNumber *__nonnull)animationId) {
    [_lock lock];
    NSArray <RCTExtAnimationViewParams *> *params = [_paramsByAnimationId[animationId] copy];
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry) {
        [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * _Nonnull param, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
            UIView *view = [self.bridge.uiManager viewForReactTag:param.reactTag];
            CFTimeInterval pausedTime = [view.layer timeOffset];
            view.layer.speed = 1.0;
            view.layer.timeOffset = 0.0;
            view.layer.beginTime = 0.0;
            CFTimeInterval timeSincePause = [view.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
            view.layer.beginTime = timeSincePause;
        }];
    }];
    [_lock unlock];
}

//这个方法真是神之命名？
//这个方法里会调用[RCTExtAnimationModule connectAnimationToView]，该方法是真正执行动画的地方
- (void) paramForAnimationId:(NSNumber *)animationId {
    NSArray <RCTExtAnimationViewParams *> *params = _paramsByAnimationId[animationId];
    NSMutableArray <NSNumber *> *reactTags = [NSMutableArray new];
    [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * _Nonnull param, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
        [reactTags addObject: param.reactTag];
    }];
    
    //如果这个animationId没有绑定任何view，则不往下执行
    if (!reactTags.count) {
        return;
    }
    
    RCTLogInfo(@"animation begin:%@",animationId);
    __weak RCTExtAnimationModule *weakSelf = self;
    //动画必须在主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        [reactTags enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tag,__unused NSUInteger idx,__unused BOOL *stop) {
            UIView *view = [weakSelf.bridge.uiManager viewForReactTag:tag];
            if (!view) {
                //在这里相当于循环的continue
                return;
            }
            
            //爱拍视频业务中，点击某个视频，底部会有loading动画，动画实现方式：动画1开始->动画1结束->动画2开始->动画2结束->动画1开始->动画1结束，如此直到视频载入结束。
            //但是在动画过程中，点击返回按钮，会将当前unit从window上删除但不销毁，而导致原持续500毫秒的动画立刻结束，使动画1与2不停快速执行
            //做个判断，如果view不在window上则不进行动画操作。
            if (view.window) {
                //真正执行动画的地方
                [weakSelf connectAnimationToView: view];
                //在这里相当于循环的continue
                return;
            }
            
            //根据罗老师写的注释，以下是边缘情况
            RCTLogInfo(@"animation view is not added to window");
            [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * p,__unused NSUInteger idx, __unused BOOL *stop) {
                [p.animationIdWithPropDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSNumber * obj,__unused BOOL *stop1) {
                    RCTExtAnimation *ani = self->_animationById[obj];
                    if (![obj isEqual: animationId]) {
                        //在这里相当于循环的continue
                        return;
                    }
                    
                    [p setValue: @(ani.endValue) forProp: key];
                    ani.state = RCTExtAnimationFinishState;
                    //                  RCTLogInfo(@"animationDidStop:%@ finish:%@ prop:%@ value:%@", animationID, @(flag), key, @(ani.endValue));
                }];
            }];
            [self.bridge.uiManager executeBlockOnUIManagerQueue:^{
                [self.bridge.uiManager updateViewsFromParams:params completion:^(__unused RCTUIManager *uiManager) {
                }];
            }];
            
        }];
    });
}

RCT_EXPORT_METHOD(updateAnimation:(NSNumber *__nonnull)animationId params:(NSDictionary *)params)
{
    if (params == nil) {
        return;
    }
    [_lock lock];
    RCTExtAnimation *ani = _animationById[animationId];
//    if (ani.state == RCTExtAnimationStartedState) {
//        RCTLogInfo(@"updateAnimation [%@] from [%@] to [%@] animation is not completed", animationId, @(ani.startValue), @(ani.endValue));
//        [_lock unlock];
//        return;
//    }
    
    ani.state = RCTExtAnimationInitState;
    
    [ani updateAnimation: params];
    
    // 更新
    NSMutableArray <RCTExtAnimationViewParams *> *viewParams = _paramsByAnimationId[animationId];
    NSMutableArray *updateParams = [NSMutableArray new];
    [viewParams enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * _Nonnull p,__unused NSUInteger idx,__unused BOOL * stop) {
        [p.animationIdWithPropDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSNumber * obj,__unused BOOL * istop) {
            RCTExtAnimation *rcani = self->_animationById[obj];
            if ([obj isEqual: animationId]) {
                [p setValue: @(rcani.startValue) forProp: key];
                [updateParams addObject: p.updateParams];
                RCTLogInfo(@"updateAnimation:[%@] key:[%@] value:[%@]", animationId, key, params[@"startValue"]);
            }
        }];
    }];
    
    //    [self.bridge executeBlockOnComponentThread:^{
    //      [self.bridge.uiManager updateNode: nil params: updateParams callBack: nil];
    //    }];
    
    //调用updateView，更新动画属性
    //最后收集各个view对应的rootTag，给rootView调用layoutAndMount
    [self.bridge.uiManager executeBlockOnUIManagerQueue:^{
        [self.bridge.uiManager updateViewsFromParams:viewParams completion:NULL];
    }];
    [_lock unlock];
}

RCT_EXPORT_METHOD(destroyAnimation:(NSNumber * __nonnull)animationId)
{
    [_lock lock];
    [_animationById removeObjectForKey: animationId];
    NSMutableArray <RCTExtAnimationViewParams *> *params = _paramsByAnimationId[animationId];
    if (params.count) {
        NSMutableArray *reactTags = [[NSMutableArray alloc] initWithCapacity: params.count];
        [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * _Nonnull obj,__unused NSUInteger idx,__unused BOOL * stop) {
            [reactTags addObject: obj.reactTag];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSNumber *reactTag in reactTags) {
                //        UIView *view = [self.bridge viewForTag: viewID];
                UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
                [view.layer removeAnimationForKey: [NSString stringWithFormat: @"%@", animationId]];
            }
        });
    }
    [_paramsByAnimationId removeObjectForKey: animationId];
    [_lock unlock];
    RCTLogInfo(@"animaiton destory:%@",animationId);
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStart:(CAAnimation *)anim
{
    NSNumber *animationId = [anim valueForKey: @"animationID"];
    [self.bridge.eventDispatcher dispatchEvent:@"EventDispatcher" methodName:@"receiveNativeEvent" args:@{@"eventName": @"onAnimationStart", @"extra": animationId}];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [_lock lock];
    NSNumber *animationId = [anim valueForKey: @"animationID"];
    NSNumber *viewId = [anim valueForKey: @"viewID"];
    
    NSMutableArray <RCTExtAnimationViewParams *> *params = [_paramsByAnimationId[animationId] copy];
    [self.bridge.uiManager executeBlockOnUIManagerQueue:^{
        //这段代码放在UIManagerQueue中执行原因在于：
        //这段代码和375行代码都会对RCTExtAnimationViewParams中的_style进行修改，导致错误crash'dictionary was mutabled when enum'
        [params enumerateObjectsUsingBlock:^(RCTExtAnimationViewParams * p,__unused NSUInteger idx, __unused BOOL * stop) {
            [p.animationIdWithPropDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSNumber * obj,__unused BOOL * stop1) {
                RCTExtAnimation *ani = self->_animationById[obj];
                if (![obj isEqual: animationId]) {
                    return;
                }
                [p setValue: @(ani.endValue) forProp: key];
                ani.state = RCTExtAnimationFinishState;
                RCTLogInfo(@"animationDidStop:%@ finish:%@ prop:%@ value:%@", animationId, @(flag), key, @(ani.endValue));
            }];
        }];
    }];
    [_lock unlock];
    
    [self.bridge.uiManager executeBlockOnUIManagerQueue:^{
        //如果hippy示例销毁早于动画的结束，那么
        //这里的调用可能uiManager为nil，不过看起来没啥问题，先观察一下
        [self.bridge.uiManager updateViewsFromParams:params completion:^(RCTUIManager *uiManager) {
            UIView *view = [uiManager viewForReactTag:viewId];
            if (flag) {
                [view.layer removeAnimationForKey: [NSString stringWithFormat: @"%@", animationId]];
            }
            if (!CGPointEqualToPoint(view.layer.anchorPoint, CGPointMake(.5f, .5f))) {
                CALayer *viewLayer = view.layer;
                CGPoint cener = CGPointMake(CGRectGetWidth(viewLayer.bounds) / 2, CGRectGetHeight(viewLayer.bounds) / 2);
                CGPoint expectedPosition = [viewLayer convertPoint:cener toLayer:viewLayer.superlayer];
                viewLayer.anchorPoint = CGPointMake(.5f, .5f);
                viewLayer.position = expectedPosition;
            }
        }];
    }];
    NSNumber *animationSetId = [anim valueForKey:@"animationParentID"];
    if (animationSetId) {
        //    [_virtualAnimations removeObject:animationSetID];
        if ([_virtualAnimations subtractionCountForAnimationId:animationSetId]) {
            [self.bridge.eventDispatcher dispatchEvent:@"EventDispatcher" methodName:@"receiveNativeEvent" args:@{@"eventName": @"onAnimationEnd", @"extra": animationSetId}];
        }
    }
    else {
        [self.bridge.eventDispatcher dispatchEvent:@"EventDispatcher" methodName:@"receiveNativeEvent" args:@{@"eventName": @"onAnimationEnd", @"extra": animationId}];
    }
}
#pragma mark -

//如果props[@"useAnimation"]为true，那么
//在[RCTUIManager createView:]和[RCTUIManager updateView:]中就会调用这个方法

//一顿操作猛如虎，其实就是：
//在_paramsByAnimationID根据animationId做了一份索引
//在_paramsByReactTag根据reactTag做了一份索引
//然后复制了一份最初的props回去
- (NSDictionary *)bindAnimaiton:(NSDictionary *)params viewTag:(NSNumber *)viewTag rootTag:(NSNumber *)rootTag
{
    [_lock lock];
    
    //p是对这个params的封装
    RCTExtAnimationViewParams *p = [[RCTExtAnimationViewParams alloc] initWithParams: params viewTag:viewTag rootTag: rootTag];
    [p parse];
    
    BOOL contain = [self alreadyConnectAnimation: p];
    [p.animationIdWithPropDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSNumber * animationId,__unused BOOL * stop) {
        RCTExtAnimation *ani = self->_animationById[animationId];
        
        //这个if看不懂。。
        if (ani.state == RCTExtAnimationFinishState) {
            [p setValue: @(ani.endValue) forProp: key];
        } else {
            [p setValue: @(ani.startValue) forProp: key];
        }
        
        //viewParams是
        NSMutableArray *viewParams = self->_paramsByAnimationId[animationId];
        if (viewParams == nil) {
            viewParams = [NSMutableArray new];
            [self->_paramsByAnimationId setObject: viewParams forKey: animationId];
        }
        
        if (!contain) {
            //如果不包含，就添加
            [viewParams addObject: p];
            RCTLogInfo(@"bind aniamtion [%@] to view [%@] prop [%@]",animationId, viewTag, key);
        } else {
            //如果包含，就替换
            NSInteger index = [viewParams indexOfObject: p];
            if (index != NSNotFound) {
                [viewParams removeObjectAtIndex: index];
            }
            [viewParams addObject: p];
        }
    }];
    
    //根据RreactTag做了一份索引
    [_paramsByReactTag setObject: p forKey: viewTag];
    [_lock unlock];
    
    return p.updateParams;
}

//真正执行动画的地方，createAnimation和startAnimation都会调用这个地方
- (void)connectAnimationToView:(UIView *)view
{
    [_lock lock];
    NSNumber *reactTag = view.reactTag;
    RCTExtAnimationViewParams *p = _paramsByReactTag[reactTag];
    
    NSMutableArray <CAAnimation *> *animations = [NSMutableArray new];
    [p.animationIdWithPropDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *prop, NSNumber * animationId,__unused BOOL * stop) {
        RCTExtAnimation *animation = self->_animationById[animationId];
        //createAnimation的时候也会进这个地方，由于RCTExtAnimationState为InitState，故不调用
        if (animation.state != RCTExtAnimationReadyState) {
            return;
        }
        //取出关键的动画
        CAAnimation *ani = [animation animationOfView: view forProp: prop];
        animation.state = RCTExtAnimationStartedState;
        [ani setValue: animationId forKey: @"animationID"];
        if (animation.parentAnimationId) {
            [ani setValue:animation.parentAnimationId forKey:@"animationParentID"];
        }
        [ani setValue: view.reactTag forKey: @"viewID"];
        ani.delegate = self;
        [animations addObject: ani];
        RCTLogInfo(@"connect aniamtion[%@] to view [%@] prop [%@] from [%@] to [%@]",animationId, view.reactTag, prop, @(animation.startValue), @(animation.endValue));
    }];
    
    //遍历动画  一一执行
    [animations enumerateObjectsUsingBlock:^(CAAnimation * _Nonnull ani, __unused NSUInteger idx, __unused BOOL *stop) {
        NSNumber *animationId = [ani valueForKey: @"animationID"];
        //真正执行动画的地方
        [view.layer addAnimation: ani forKey: [NSString stringWithFormat: @"%@", animationId]];
    }];
    
    [_lock unlock];
}

- (BOOL)alreadyConnectAnimation:(RCTExtAnimationViewParams *)p
{
    return [[_paramsByReactTag allValues] containsObject: p];
}

@end
