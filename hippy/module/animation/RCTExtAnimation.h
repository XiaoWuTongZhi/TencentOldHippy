//
//  RCTExtAnimation.h
//  HippyNative
//
//  Created by pennyli on 2017/12/26.
//  Copyright © 2017年 pennyli. All rights reserved.
//
//这个文件从HPAnimation改名而来
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@class RCTExtAnimation;

typedef NS_ENUM(NSInteger, RCTExtAnimationValueType) {
    RCTExtAnimationValueTypeNone,
    RCTExtAnimationValueTypeRad,
    RCTExtAnimationValueTypeDeg
};

typedef NS_ENUM(NSInteger, RCTExtAnimationDirection) {
    RCTExtAnimationDirectionCenter,
    RCTExtAnimationDirectionLeft,
    RCTExtAnimationDirectionTop,
    RCTExtAnimationDirectionBottom,
    RCTExtAnimationDirectionRight
};
typedef NS_ENUM(NSInteger, RCTExtAnimationState) {
	RCTExtAnimationInitState,
	RCTExtAnimationReadyState,
	RCTExtAnimationStartedState,
	RCTExtAnimationFinishState
};

@interface RCTExtAnimation : NSObject <CAAnimationDelegate>

@property (nonatomic, assign) double startValue;
@property (nonatomic, assign) double endValue;
@property (nonatomic, assign, readonly) NSTimeInterval delay;
@property (nonatomic, assign, readonly) float repeatCount;
@property (nonatomic, strong, readonly) NSNumber *animationId;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong, readonly) NSString *timingFunction;
@property (nonatomic, assign, readonly) RCTExtAnimationValueType valueType;
@property (nonatomic, assign, readonly) RCTExtAnimationDirection directionType;
@property (nonatomic, copy) NSNumber *parentAnimationId;
@property (nonatomic, assign) RCTExtAnimationState state;


- (void)updateAnimation:(NSDictionary *)config;

- (CAAnimation *)animationOfView:(UIView *)view forProp:(NSString *)prop;

- (instancetype)initWithMode:(NSString *)mode animationId:(NSNumber *)animationID config:(NSDictionary *)config;

@end
