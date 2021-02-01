/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTRootView.h"
#import "RCTRootViewDelegate.h"
#import "RCTRootViewInternal.h"

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTEventDispatcher.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTPerformanceLogger.h"
#import "RCTTouchHandler.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "UIView+React.h"
#import "RCTBridge+Mtt.h"
#import "RCTBundleURLProvider.h"

NSString *const RCTContentDidAppearNotification = @"RCTContentDidAppearNotification";

@interface RCTUIManager (RCTRootView)

- (NSNumber *)allocateRootTag;

@end

@interface RCTRootContentView : RCTView <RCTInvalidating>

@property (nonatomic, readonly) BOOL contentHasAppeared;
@property (nonatomic, strong) RCTTouchHandler *touchHandler;
@property (nonatomic, assign) int64_t startTimpStamp;

- (instancetype)initWithFrame:(CGRect)frame
                       bridge:(RCTBridge *)bridge
                     reactTag:(NSNumber *)reactTag
               sizeFlexiblity:(RCTRootViewSizeFlexibility)sizeFlexibility NS_DESIGNATED_INITIALIZER;

@end

@interface RCTRootView ()
// MttRN: 增加一个属性用于属性传递
@property (nonatomic, strong) NSDictionary *shareOptions;

@end

@implementation RCTRootView
{
  RCTBridge *_bridge;
  NSString *_moduleName;
  RCTRootContentView *_contentView;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
                    moduleName:(NSString *)moduleName
             initialProperties:(NSDictionary *)initialProperties
                  shareOptions:(NSDictionary *)shareOptions
				      delegate:(id<RCTRootViewDelegate>)delegate
{
    RCTAssertMainQueue();
    RCTAssert(bridge, @"A bridge instance is required to create an RCTRootView");
    RCTAssert(moduleName, @"A moduleName is required to create an RCTRootView");

    if ((self = [super initWithFrame:CGRectZero])) {

        self.backgroundColor = [UIColor clearColor];

        _bridge = bridge;
        if (nil == _bridge.moduleName) {
            _bridge.moduleName = moduleName;
        }
        _moduleName = moduleName;
        _appProperties = [initialProperties copy];
        _loadingViewFadeDelay = 0.25;
        _loadingViewFadeDuration = 0.25;
        _sizeFlexibility = RCTRootViewSizeFlexibilityNone;
        _shareOptions = shareOptions;
        _delegate = delegate;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bridgeDidReload)
                                                     name:RCTJavaScriptWillStartLoadingNotification
                                                   object:_bridge];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(javaScriptDidLoad:)
                                                     name:RCTJavaScriptDidLoadNotification
                                                   object:_bridge];
	  
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(javaScriptDidFailToLoad:) name:RCTJavaScriptDidFailToLoadNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_contentDidAppear:)
                                                     name:RCTContentDidAppearNotification
                                                   object:self];
	  
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_secondaryBundleDidLoadSourceCode:)
                                                     name:RCTSecondaryBundleDidLoadSourceCodeNotification
                                                   object:nil];
	  
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_secondayBundleDidFinishLoad:)
                                                     name:RCTSecondaryBundleDidLoadNotification
                                                   object:nil];

        [self showLoadingView];
        [_bridge.performanceLogger markStartForTag:RCTPLTTI];
    }

    return self;
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
					   moduleName:(NSString *)moduleName
				initialProperties:(NSDictionary *)initialProperties
					launchOptions:(NSDictionary *)launchOptions
					 shareOptions:(NSDictionary *)shareOptions
						debugMode:(BOOL)mode
						 delegate:(id<RCTRootViewDelegate>)delegate
	
{
    NSMutableDictionary *extendsLaunchOptions = [NSMutableDictionary new];
	[extendsLaunchOptions addEntriesFromDictionary: launchOptions];
	[extendsLaunchOptions setObject: @(mode) forKey:@"DebugMode"];
  	RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:bundleURL
                                            moduleProvider:nil
                                             launchOptions:extendsLaunchOptions
                                                 executorKey:nil];
	return [self initWithBridge:bridge moduleName:moduleName initialProperties:initialProperties shareOptions:shareOptions delegate: delegate];
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
				   businessURL:(NSURL *)businessURL
					moduleName:(NSString *)moduleName
			 initialProperties:(NSDictionary *)initialProperties
				 launchOptions:(NSDictionary *)launchOptions
				  shareOptions:(NSDictionary *)shareOptions
					 debugMode:(BOOL)mode
					  delegate:(id<RCTRootViewDelegate>)delegate
{
	if (mode) {
        NSString *localhost = [RCTBundleURLProvider sharedInstance].localhost ?: @"localhost:38989";
        NSString *bundleStr = [NSString stringWithFormat:@"http://%@%@",localhost,[RCTBundleURLProvider sharedInstance].debugPathUrl];
        NSURL *bundleUrl = [NSURL URLWithString:bundleStr];
        
        if (self = [self initWithBundleURL: bundleUrl moduleName: moduleName initialProperties: initialProperties launchOptions: launchOptions shareOptions: shareOptions debugMode: mode delegate: delegate]) {
        }
        return self;
	} else {
		bridge.batchedBridge.useCommonBridge = YES;
		if (self = [self initWithBridge: bridge moduleName: moduleName initialProperties: initialProperties shareOptions: shareOptions delegate: delegate]) {
			if (!bridge.isLoading && !bridge.isValid) {
				if (delegate && [delegate respondsToSelector: @selector(rootView:didLoadFinish:)]) {
					[delegate rootView: self didLoadFinish: NO];
				}
			} else {
				__weak __typeof__(self) weakSelf = self;
				[bridge loadSecondary:businessURL loadBundleCompletion: nil enqueueScriptCompletion: nil completion:^(BOOL success) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (success) {
							[weakSelf bundleFinishedLoading: bridge.batchedBridge];
						}
					});
				}];
			}
		}
		return self;
	}
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    super.backgroundColor = backgroundColor;
    _contentView.backgroundColor = backgroundColor;
}

- (UIViewController *)reactViewController
{
    return _reactViewController ?: [super reactViewController];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setLoadingView:(UIView *)loadingView
{
    _loadingView = loadingView;
    if (!_contentView.contentHasAppeared) {
        [self showLoadingView];
    }
}

- (void)showLoadingView
{
    if (_loadingView && !_contentView.contentHasAppeared) {
        _loadingView.hidden = NO;
        [self addSubview:_loadingView];
    }
}

- (void)_contentDidAppear:(NSNotification *)n
{
    if (_loadingView.superview == self && _contentView.contentHasAppeared) {
        if (_loadingViewFadeDuration > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_loadingViewFadeDelay * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                               [UIView transitionWithView:self
                                                 duration:self->_loadingViewFadeDuration
                                                  options:UIViewAnimationOptionTransitionCrossDissolve
                                               animations:^{
                                                   self->_loadingView.hidden = YES;
                                               } completion:^(__unused BOOL finished) {
                                                   [self->_loadingView removeFromSuperview];
                                               }];
                           });
        } else {
            _loadingView.hidden = YES;
            [_loadingView removeFromSuperview];
        }
    }
    [self contentDidAppear: [n.userInfo[@"cost"] longLongValue]];
}

- (NSNumber *)reactTag
{
    RCTAssertMainQueue();
    if (!super.reactTag) {
    /**
     * Every root view that is created must have a unique react tag.
     * Numbering of these tags goes from 1, 11, 21, 31, etc
     *
     * NOTE: Since the bridge persists, the RootViews might be reused, so the
     * react tag must be re-assigned every time a new UIManager is created.
     */
        self.reactTag = [_bridge.uiManager allocateRootTag];
    }
    return super.reactTag;
}

- (void)bridgeDidReload
{
    RCTAssertMainQueue();
    // Clear the reactTag so it can be re-assigned
    self.reactTag = nil;
}

- (void)javaScriptDidLoad:(NSNotification *)notification
{
    RCTAssertMainQueue();

    // Use the (batched) bridge that's sent in the notification payload, so the
    // RCTRootContentView is scoped to the right bridge
    RCTBridge *bridge = notification.userInfo[@"bridge"];
    if (!bridge.useCommonBridge && _bridge.batchedBridge == bridge)
    {
        [self bundleFinishedLoading:bridge];
    }
}


- (void)javaScriptDidFailToLoad:(NSNotification *)notification
{
	RCTBridge *bridge = notification.userInfo[@"bridge"];
	NSError *error = notification.userInfo[@"error"];
	if (bridge == self.bridge && error) {
		RCTFatal(error);
	}
}

- (void)_secondaryBundleDidLoadSourceCode:(NSNotification *)notification
{
	NSError *error = notification.userInfo[@"error"];
    if (nil == error) {
        return;
    }
	RCTBridge *notiBridge = notification.userInfo[@"bridge"];
	if (self.bridge == notiBridge) {
		[self secondaryBundleDidLoadSourceCode: error];
	}
}

- (void)_secondayBundleDidFinishLoad:(NSNotification *)notification
{
	NSError *error = notification.userInfo[@"error"];
	RCTBridge *notiBridge = notification.userInfo[@"bridge"];
	if (self.bridge == notiBridge) {
		[self secondayBundleDidFinishLoad: error];
	}
}

- (void)contentDidAppear:(__unused int64_t)cost
{
	
}

- (void)secondaryBundleDidLoadSourceCode:(NSError *)error
{
	if (error) {
		RCTFatal(error);
	}
}

- (void)secondayBundleDidFinishLoad:(NSError *)error
{
	if (error) {
		RCTFatal(error);
	}
}

- (void)bundleFinishedLoading:(RCTBridge *)bridge
{
  if (!bridge.valid) {
    return;
  }

  [_contentView removeFromSuperview];
  _contentView = [[RCTRootContentView alloc] initWithFrame:self.bounds
                                                    bridge:bridge
                                                  reactTag:self.reactTag
                                            sizeFlexiblity:_sizeFlexibility];

  if (self.shareOptions) {
		[bridge.shareOptions setObject:self.shareOptions ? : @{} forKey: self.reactTag];
  }
	
  [self runApplication:bridge];

  _contentView.backgroundColor = self.backgroundColor;
  [self insertSubview:_contentView atIndex:0];

  if (_sizeFlexibility == RCTRootViewSizeFlexibilityNone) {
    self.intrinsicSize = self.bounds.size;
  }
}


- (void)runApplication:(RCTBridge *)bridge
{
    if (_contentView == nil) {
        return;
    }
    NSString *moduleName = _moduleName ?: @"";
    NSDictionary *appParameters = @{
                                    @"rootTag": _contentView.reactTag,
                                    @"initialProps": _appProperties ?: @{},
                                    @"commonSDKVersion": _RCTSDKVersion
                                    };
    
    RCTLogInfo(@"Running application %@ (%@)", moduleName, appParameters);
    
    [bridge enqueueJSCall:@"AppRegistry"
                   method:@"runApplication"
                     args:@[moduleName, appParameters]
               completion:NULL];
}

- (void)setSizeFlexibility:(RCTRootViewSizeFlexibility)sizeFlexibility
{
  _sizeFlexibility = sizeFlexibility;
  [self setNeedsLayout];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _contentView.frame = self.bounds;
  _loadingView.center = (CGPoint){
    CGRectGetMidX(self.bounds),
    CGRectGetMidY(self.bounds)
  };
}

- (void)setAppProperties:(NSDictionary *)appProperties
{
  RCTAssertMainQueue();

  if ([_appProperties isEqualToDictionary:appProperties]) {
    return;
  }

  _appProperties = [appProperties copy];

  if (_contentView && _bridge.valid && !_bridge.loading) {
    [self runApplication:_bridge];
  }
}

- (void)setIntrinsicSize:(CGSize)intrinsicSize
{
    BOOL oldSizeHasAZeroDimension = _intrinsicSize.height == 0 || _intrinsicSize.width == 0;
    BOOL newSizeHasAZeroDimension = intrinsicSize.height == 0 || intrinsicSize.width == 0;
    BOOL bothSizesHaveAZeroDimension = oldSizeHasAZeroDimension && newSizeHasAZeroDimension;

    BOOL sizesAreEqual = CGSizeEqualToSize(_intrinsicSize, intrinsicSize);

    _intrinsicSize = intrinsicSize;

    // Don't notify the delegate if the content remains invisible or its size has not changed
    if (bothSizesHaveAZeroDimension || sizesAreEqual) {
    return;
    }
    if ([_delegate respondsToSelector:@selector(rootViewDidChangeIntrinsicSize:)]) {
        [_delegate rootViewDidChangeIntrinsicSize:self];
    }
}

- (void)contentViewInvalidated
{
  [_contentView removeFromSuperview];
  _contentView = nil;
  [self showLoadingView];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_contentView invalidate];
}

- (void)cancelTouches
{
  [[_contentView touchHandler] cancelTouch];
}

@end

@implementation RCTUIManager (RCTRootView)

- (NSNumber *)allocateRootTag
{
  NSNumber *rootTag = objc_getAssociatedObject(self, _cmd) ?: @10;
  objc_setAssociatedObject(self, _cmd, @(rootTag.integerValue + 10), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return rootTag;
}

@end

@implementation RCTRootContentView
{
  __weak RCTBridge *_bridge;
  UIColor *_backgroundColor;
}

- (instancetype)initWithFrame:(CGRect)frame
                       bridge:(RCTBridge *)bridge
                     reactTag:(NSNumber *)reactTag
               sizeFlexiblity:(RCTRootViewSizeFlexibility)sizeFlexibility
{
  if ((self = [super initWithFrame:frame])) {
    _bridge = bridge;
    self.reactTag = reactTag;
      
          _touchHandler = [[RCTTouchHandler alloc] initWithRootView: self bridge:bridge];
    [self addGestureRecognizer:_touchHandler];
    [_bridge.uiManager registerRootView:self withSizeFlexibility:sizeFlexibility];
    self.layer.backgroundColor = NULL;
    _startTimpStamp = CACurrentMediaTime() * 1000;
  }
  return self;
}



RCT_NOT_IMPLEMENTED(-(instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(-(instancetype)initWithCoder:(nonnull NSCoder *)aDecoder)

- (void)insertReactSubview:(UIView *)subview atIndex:(NSInteger)atIndex
{
  [super insertReactSubview:subview atIndex:atIndex];
  [_bridge.performanceLogger markStopForTag:RCTPLTTI];
	[_bridge.performanceLogger markStopForTag:RCTFeedsTimeCost];
	
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self->_contentHasAppeared) {
      self->_contentHasAppeared = YES;
	  int64_t cost = [self->_bridge.performanceLogger durationForTag: RCTPLTTI];
      [[NSNotificationCenter defaultCenter] postNotificationName:RCTContentDidAppearNotification
                                                          object:self.superview
														userInfo:@{@"cost" : @(cost)}];
			
    }
  });
}

- (void)setFrame:(CGRect)frame
{
  super.frame = frame;
  if (self.reactTag && _bridge.isValid) {
    [_bridge.uiManager setFrame:frame forView:self];
  }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  _backgroundColor = backgroundColor;
  if (self.reactTag && _bridge.isValid) {
    [_bridge.uiManager setBackgroundColor:backgroundColor forView:self];
  }
}

- (UIColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)invalidate
{
  if (self.userInteractionEnabled) {
    self.userInteractionEnabled = NO;
    [(RCTRootView *)self.superview contentViewInvalidated];
    [_bridge enqueueJSCall:@"AppRegistry"
                    method:@"unmountApplicationComponentAtRootTag"
                      args:@[self.reactTag]
                completion:NULL];
  }
}

@end
