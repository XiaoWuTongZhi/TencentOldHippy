//
//  HPAniamtion.m
//  HippyNative
//
//  Created by pennyli on 2017/12/26.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#import "RCTExtAnimation.h"
#import "RCTExtAnimation+Group.h"
#import "RCTExtAnimation+Value.h"
#import "RCTAssert.h"
@implementation RCTExtAnimation

+ (NSDictionary *)animationKeyMap
{
	static NSDictionary *animationMap = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (animationMap == nil) {
			animationMap = @{@"position.x": @[@"left",@"right"],
							 @"position.y": @[@"top", @"bottom"],
							 @"bounds.size.width": @[@"width"],
							 @"bounds.size.height": @[@"height"],
							 @"opacity": @[@"opacity"],
							 @"transform.rotation.z": @[@"rotate", @"rotateZ"],
							 @"transform.rotation.x": @[@"rotateX"],
							 @"transform.rotation.y": @[@"rotateY"],
							 @"transform.scale": @[@"scale"],
							 @"transform.scale.x": @[@"scaleX"],
							 @"transform.scale.y": @[@"scaleY"],
							 @"transform.translation.x": @[@"translateX"],
							 @"transform.translation.y": @[@"translateY"]
							 };
		}
	});
	return animationMap;
}

+ (CGFloat)convertToRadians:(id)json
{
	if ([json isKindOfClass:[NSString class]]) {
		NSString *stringValue = (NSString *)json;
		if ([stringValue hasSuffix:@"deg"]) {
			CGFloat degrees = [[stringValue substringToIndex:stringValue.length - 3] floatValue];
			return degrees * M_PI / 180;
		}
		if ([stringValue hasSuffix:@"rad"]) {
			return [[stringValue substringToIndex:stringValue.length - 3] floatValue];
		}
	}
	return [json floatValue];
}

- (instancetype)initWithMode:(NSString *)mode animationId:(NSNumber *)animationID config:(NSDictionary *)config
{
    if (self = [super init]) {
        _state = RCTExtAnimationInitState;
		_animationId = animationID;
		_duration = [config[@"duration"] doubleValue] / 1000;
		_delay = [config[@"delay"] doubleValue] / 1000;
		_startValue = [config[@"startValue"] doubleValue];
		_endValue = [config[@"toValue"] doubleValue];
		_repeatCount = [config[@"repeatCount"] integerValue];
		_repeatCount = _repeatCount == -1 ? MAXFLOAT : MAX(1, _repeatCount);
        
		NSString *valueTypeStr = config[@"valueType"];
		// value type
		_valueType = RCTExtAnimationValueTypeNone;
		if ([valueTypeStr isEqualToString: @"deg"]) {
			_valueType = RCTExtAnimationValueTypeDeg;
		} else if ([valueTypeStr isEqualToString: @"rad"]) {
			_valueType = RCTExtAnimationValueTypeRad;
		}
        
        NSString *directionTypeStr = config[@"direction"];
        _directionType = RCTExtAnimationDirectionCenter;
        if ([directionTypeStr isEqualToString: @"left"]) {
            _directionType = RCTExtAnimationDirectionLeft;
        } else if ([directionTypeStr isEqualToString: @"right"]) {
            _directionType = RCTExtAnimationDirectionRight;
        } else if ([directionTypeStr isEqualToString: @"bottom"]) {
            _directionType = RCTExtAnimationDirectionBottom;
        } else if ([directionTypeStr isEqualToString: @"top"]) {
            _directionType = RCTExtAnimationDirectionTop;
        }
		
		// timing function
		NSString *timingFunction = config[@"timingFunction"];
		if ([timingFunction isEqualToString: @"easeIn"]) {
			_timingFunction = kCAMediaTimingFunctionEaseIn;
		} else if ([timingFunction isEqualToString: @"easeOut"]) {
			_timingFunction = kCAMediaTimingFunctionEaseOut;
		} else if ([timingFunction isEqualToString: @"easeInOut"]) {
			_timingFunction = kCAMediaTimingFunctionEaseInEaseOut;
		} else if ([timingFunction isEqualToString: @"linear"]){
			_timingFunction = kCAMediaTimingFunctionLinear;
		} else {
			_timingFunction = kCAMediaTimingFunctionEaseIn;
		}
    }
    return self;
}

- (void)updateAnimation:(NSDictionary *)config
{
	_duration = config[@"duration"] ? [config[@"duration"] doubleValue] / 1000 : _duration;
	_delay = config[@"delay"] ? [config[@"delay"] doubleValue] / 1000 : _delay;
	_startValue = config[@"startValue"] ? [config[@"startValue"] doubleValue] : _startValue;
	_endValue = config[@"toValue"] ? [config[@"toValue"] doubleValue] : _endValue;
	_repeatCount = config[@"repeatCount"] ? [config[@"repeatCount"] integerValue] : _repeatCount;
	_repeatCount = _repeatCount == -1 ? MAXFLOAT : MAX(1, _repeatCount);
	 
	NSString *valueTypeStr = config[@"valueType"];
	// value type
	if (valueTypeStr) {
		_valueType = RCTExtAnimationValueTypeNone;
		if ([valueTypeStr isEqualToString: @"deg"]) {
			_valueType = RCTExtAnimationValueTypeDeg;
		} else if ([valueTypeStr isEqualToString: @"rad"]) {
			_valueType = RCTExtAnimationValueTypeRad;
		}
	}

	if (config[@"direction"]) {
		NSString *directionTypeStr = config[@"direction"];
		_directionType = RCTExtAnimationDirectionCenter;
		if ([directionTypeStr isEqualToString: @"left"]) {
			_directionType = RCTExtAnimationDirectionLeft;
		} else if ([directionTypeStr isEqualToString: @"right"]) {
			_directionType = RCTExtAnimationDirectionRight;
		} else if ([directionTypeStr isEqualToString: @"bottom"]) {
			_directionType = RCTExtAnimationDirectionBottom;
		} else if ([directionTypeStr isEqualToString: @"top"]) {
			_directionType = RCTExtAnimationDirectionTop;
		}
	}
	
	// timing function
	if (config[@"timingFunction"]) {
		NSString *timingFunction = config[@"timingFunction"];
		if ([timingFunction isEqualToString: @"easeIn"]) {
			_timingFunction = kCAMediaTimingFunctionEaseIn;
		} else if ([timingFunction isEqualToString: @"easeOut"]) {
			_timingFunction = kCAMediaTimingFunctionEaseOut;
		} else if ([timingFunction isEqualToString: @"easeInOut"]) {
			_timingFunction = kCAMediaTimingFunctionEaseInEaseOut;
		} else if ([timingFunction isEqualToString: @"linear"]){
			_timingFunction = kCAMediaTimingFunctionLinear;
		} else {
			_timingFunction = kCAMediaTimingFunctionDefault;
		}
	}
}


- (CAAnimation *)animationOfView:(UIView *)view forProp:(NSString *)prop
{
	NSString *animationKey = nil;
	NSDictionary *animationKeyMap = [[self class] animationKeyMap];
	for (NSString *key in animationKeyMap) {
		NSArray *maps = animationKeyMap[key];
		if ([maps containsObject: prop]) {
			animationKey = key;
			break;
		}
	}
	
	if (animationKey == nil) {
		RCTAssert(animationKey != nil, @"[%@] illge animaton prop", prop);
		return nil;
	}
	
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: animationKey];
	
	if ([animationKey hasPrefix: @"transform"]){
		if (_valueType == RCTExtAnimationValueTypeDeg) {
			self.fromValue = @(_startValue * M_PI / 180);
			self.toValue = @(_endValue * M_PI / 180);
		} else {
			self.fromValue = @(_startValue);
			self.toValue = @(_endValue);
		}
	} else if ([animationKey isEqualToString: @"position.x"] || [animationKey isEqualToString: @"position.y"]) {
		[self calcValueWithCenter: view.center forProp: prop];
    } else if ([animationKey isEqualToString: @"bounds.size.width"]) {
      CGPoint position = view.layer.position;
        if (_directionType == RCTExtAnimationDirectionLeft) {
            view.layer.anchorPoint = CGPointMake(0, .5);
          view.layer.position = CGPointMake(position.x - CGRectGetWidth(view.frame) / 2, position.y);
        } else if (_directionType == RCTExtAnimationDirectionRight){
            view.layer.anchorPoint = CGPointMake(1, .5);
          view.layer.position = CGPointMake(position.x + CGRectGetWidth(view.frame) / 2, position.y);
        } else {
            view.layer.anchorPoint = CGPointMake(.5, .5);
        }
        self.fromValue = @(_startValue);
        self.toValue = @(_endValue);
    } else if ([animationKey isEqualToString: @"bounds.size.height"]) {
      CGPoint position = view.layer.position;
        if (_directionType == RCTExtAnimationDirectionTop){
          view.layer.position = CGPointMake(position.x, position.y - CGRectGetHeight(view.frame) / 2);
            view.layer.anchorPoint = CGPointMake(0.5, 0);
        }  else if (_directionType == RCTExtAnimationDirectionBottom){
          view.layer.position = CGPointMake(position.x, position.y + CGRectGetHeight(view.frame) / 2);
            view.layer.anchorPoint = CGPointMake(.5, 1);
        } else
            view.layer.anchorPoint = CGPointMake(0.5, 0.5);
        
        self.fromValue = @(_startValue);
        self.toValue = @(_endValue);
    }
    else {
		self.fromValue = @(_startValue);
		self.toValue = @(_endValue);
	}
	
    if (self.fromValue && self.toValue) {
        animation.fromValue = self.fromValue;
        animation.toValue = self.toValue;
    }
    else if (self.byValue){
        animation.byValue = self.byValue;
    }
	animation.duration = _duration;
	animation.beginTime = CACurrentMediaTime() + _delay;
	animation.timingFunction = [CAMediaTimingFunction functionWithName: _timingFunction];
	animation.repeatCount = _repeatCount;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
	
	return animation;
}

@end
