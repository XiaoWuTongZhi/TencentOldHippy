//
//  HPEventObserverModule.m
//  HippyNative
//
//  Created by pennyli on 2017/12/19.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#import "RCTEventObserverModule.h"
#import "RCTAssert.h"
#import "RCTEventDispatcher.h"

@implementation RCTEventObserverModule {
    NSMutableDictionary *_config;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(EventObserver)

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    if (self = [super init]) {
        _config = [NSMutableDictionary new];
    }
    return self;
}

RCT_EXPORT_METHOD(addListener:(NSString *)eventName)
{
    RCTAssertParam(eventName);
    NSNumber *value = _config[eventName];
    if (value == nil) {
        value = @(1);
        [self addEventObserverForName: eventName];
    } else {
        value = @(value.integerValue + 1);
    }
    _config[eventName] = value;
}

RCT_EXPORT_METHOD(removeListener:(NSString *)eventName)
{
    NSNumber *value = _config[eventName];
    if (value == nil || value.integerValue == 1) {
        [_config removeObjectForKey: eventName];
        [self removeEventObserverForName: eventName];
    } else {
        value = @(value.integerValue - 1);
        _config[eventName] = value;
    }
}

- (void)addEventObserverForName:(__unused NSString *)eventName
{
    // should override by subclass
    // do sth
}

- (void)removeEventObserverForName:(__unused NSString *)eventName
{
    // should override by subclass
    // do sth
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)sendEvent:(NSString *)eventName params:(NSDictionary *)params
{
	RCTAssertParam(eventName);
	[self.bridge.eventDispatcher dispatchEvent:@"EventDispatcher" methodName:@"receiveNativeEvent" args:@{@"eventName": eventName, @"extra": params ? : @{}}];
}
@end
