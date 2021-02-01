/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTNetInfo.h"

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

static NSString *const RCTReachabilityStateUnknown = @"UNKNOWN";
static NSString *const RCTReachabilityStateNone = @"NONE";
static NSString *const RCTReachabilityStateWifi = @"WIFI";
static NSString *const RCTReachabilityStateCell = @"CELL";

@implementation RCTNetInfo
{
  SCNetworkReachabilityRef _reachability;
  NSString *_status;
  NSString *_host;
}

RCT_EXPORT_MODULE()

static void RCTReachabilityCallback(__unused SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
  RCTNetInfo *self = (__bridge id)info;
  NSString *status = RCTReachabilityStateUnknown;
  if ((flags & kSCNetworkReachabilityFlagsReachable) == 0 ||
      (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0) {
    status = RCTReachabilityStateNone;
  }

#if TARGET_OS_IPHONE

  else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
    status = RCTReachabilityStateCell;
  }

#endif

  else {
    status = RCTReachabilityStateWifi;
  }

  if (![status isEqualToString:self->_status]) {
    self->_status = status;
    [self sendEvent:@"networkStatusDidChange" params:@{@"network_info": status}];
  }
}

#pragma mark - Lifecycle

- (instancetype)initWithHost:(NSString *)host
{
  RCTAssertParam(host);
  RCTAssert(![host hasPrefix:@"http"], @"Host value should just contain the domain, not the URL scheme.");

  if ((self = [self init])) {
    _host = [host copy];
  }
  return self;
}

- (void) addEventObserverForName:(NSString *)eventName {
  if ([eventName isEqualToString:@"networkStatusDidChange"]) {
    _status = RCTReachabilityStateUnknown;
    _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, _host.UTF8String ?: "apple.com");
    SCNetworkReachabilityContext context = { 0, ( __bridge void *)self, NULL, NULL, NULL };
    SCNetworkReachabilitySetCallback(_reachability, RCTReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  }
}

- (void) removeEventObserverForName:(NSString *)eventName {
  if ([eventName isEqualToString:@"networkStatusDidChange"]) {
		[self releaseReachability];
  }
}

- (void)invalidate
{
	[self releaseReachability];
}

- (void)releaseReachability
{
	if (_reachability) {
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
		CFRelease(_reachability);
		_reachability = NULL;
	}
}

- (void)dealloc
{
	[self releaseReachability];
}
#pragma mark - Public API

RCT_EXPORT_METHOD(getCurrentConnectivity:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  resolve(@{@"network_info": _status ?: RCTReachabilityStateUnknown});
}

@end
