/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDevMenu.h"

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTBridge+Private.h"
#import "RCTDefines.h"
#import "RCTEventDispatcher.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTRootView.h"
#import "RCTUtils.h"
#import "RCTWebSocketProxy.h"

#if RCT_DEV

static NSString *const RCTShowDevMenuNotification = @"RCTShowDevMenuNotification";
static NSString *const RCTDevMenuSettingsKey = @"RCTDevMenu";

@implementation UIWindow (RCTDevMenu)

- (void)RCT_motionEnded:(__unused UIEventSubtype)motion withEvent:(UIEvent *)event
{
  if (event.subtype == UIEventSubtypeMotionShake) {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTShowDevMenuNotification object:nil];
  }
}

@end

typedef NS_ENUM(NSInteger, RCTDevMenuType) {
  RCTDevMenuTypeButton,
  RCTDevMenuTypeToggle
};

@interface RCTDevMenuItem ()

@property (nonatomic, assign, readonly) RCTDevMenuType type;
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *selectedTitle;
@property (nonatomic, copy) id value;

@end

@implementation RCTDevMenuItem
{
  id _handler; // block
}

- (instancetype)initWithType:(RCTDevMenuType)type
                         key:(NSString *)key
                       title:(NSString *)title
               selectedTitle:(NSString *)selectedTitle
                     handler:(id /* block */)handler
{
  if ((self = [super init])) {
    _type = type;
    _key = [key copy];
    _title = [title copy];
    _selectedTitle = [selectedTitle copy];
    _handler = [handler copy];
    _value = nil;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

+ (instancetype)buttonItemWithTitle:(NSString *)title
                            handler:(void (^)(void))handler
{
  return [[self alloc] initWithType:RCTDevMenuTypeButton
                                key:nil
                              title:title
                      selectedTitle:nil
                            handler:handler];
}

+ (instancetype)toggleItemWithKey:(NSString *)key
                            title:(NSString *)title
                    selectedTitle:(NSString *)selectedTitle
                          handler:(void (^)(BOOL selected))handler
{
  return [[self alloc] initWithType:RCTDevMenuTypeToggle
                                key:key
                              title:title
                      selectedTitle:selectedTitle
                            handler:handler];
}

- (void)callHandler
{
  switch (_type) {
    case RCTDevMenuTypeButton: {
      if (_handler) {
        ((void(^)(void))_handler)();
      }
      break;
    }
    case RCTDevMenuTypeToggle: {
      if (_handler) {
        ((void(^)(BOOL selected))_handler)([_value boolValue]);
      }
      break;
    }
  }
}

@end

@interface RCTDevMenu () <RCTBridgeModule, RCTInvalidating>

@property (nonatomic, strong) Class executorClass;

@end

@implementation RCTDevMenu
{
  __weak UIAlertController *_actionSheet;
  NSUserDefaults *_defaults;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)initialize
{
  // We're swizzling here because it's poor form to override methods in a category,
  // however UIWindow doesn't actually implement motionEnded:withEvent:, so there's
  // no need to call the original implementation.
  RCTSwapInstanceMethods([UIWindow class], @selector(motionEnded:withEvent:), @selector(RCT_motionEnded:withEvent:));
}

- (instancetype)init
{
  if ((self = [super init])) {

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(showOnShake)
                               name:RCTShowDevMenuNotification
                             object:nil];

    _defaults = [NSUserDefaults standardUserDefaults];
    _shakeToShow = YES;

  }
  return self;
}

- (void)setBridge:(RCTBridge *)bridge
{
	_bridge = bridge;
	
#if TARGET_IPHONE_SIMULATOR
    if (bridge.debugMode) {
        __weak RCTDevMenu *weakSelf = self;
        
        RCTKeyCommands *commands = [RCTKeyCommands sharedInstance];
        
        // Toggle debug menu
        [commands registerKeyCommandWithInput:@"d"
                                modifierFlags:UIKeyModifierCommand
                                       action:^(__unused UIKeyCommand *command) {
                                           [weakSelf toggle];
                                       }];
        
        // Toggle debug menu
        [commands registerKeyCommandWithInput:@"e"
                                modifierFlags:UIKeyModifierCommand
                                       action:^(__unused UIKeyCommand *command) {
                                           [weakSelf toggle];
                                       }];
        
        // Toggle debug menu
        [commands registerKeyCommandWithInput:@"b"
                                modifierFlags:UIKeyModifierCommand
                                       action:^(__unused UIKeyCommand *command) {
                                           [weakSelf toggle];
                                       }];
        
        // Toggle debug menu
        [commands registerKeyCommandWithInput:@"u"
                                modifierFlags:UIKeyModifierCommand
                                       action:^(__unused UIKeyCommand *command) {
                                           [weakSelf toggle];
                                       }];
        
        // Toggle debug menu
        [commands registerKeyCommandWithInput:@"g"
                                modifierFlags:UIKeyModifierCommand
                                       action:^(__unused UIKeyCommand *command) {
                                           [weakSelf toggle];
                                       }];
    }
#endif
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{

  [_actionSheet dismissViewControllerAnimated:YES completion:^(void){}];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showOnShake
{
  if (_shakeToShow) {
    [self show];
  }
}

- (void)toggle
{
  if (!self.bridge.debugMode) return;
  if (_actionSheet) {
    [_actionSheet dismissViewControllerAnimated:YES completion:^(void){}];
    _actionSheet = nil;
  } else {
    [self show];
  }
}

- (void)addItem:(NSString *)title handler:(void(^)(void))handler
{
  [self addItem:[RCTDevMenuItem buttonItemWithTitle:title handler:handler]];
}

- (void)addItem:(__unused RCTDevMenuItem *)item {
    RCTAssert(NO, @"[RCTDevMenu addItem:]方法没有实现，怎么没问题？");
}

- (NSArray<RCTDevMenuItem *> *)menuItems
{
  NSMutableArray<RCTDevMenuItem *> *items = [NSMutableArray new];

  // Add built-in items

  __weak RCTDevMenu *weakSelf = self;

  [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Reload" handler:^{
    [weakSelf reload];
  }]];

  return items;
}

RCT_EXPORT_METHOD(reload)
{
    [_bridge requestReload];
}

RCT_EXPORT_METHOD(show)
{
  if (_actionSheet || !_bridge || RCTRunningInAppExtension()) {
    return;
  }

  NSString *title = [NSString stringWithFormat:@"Hippy: Development (%@)", [_bridge class]];
  // On larger devices we don't have an anchor point for the action sheet
  UIAlertControllerStyle style = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:title
                                                     message:@""
                                              preferredStyle:style];
    _actionSheet = actionSheet;

  NSArray<RCTDevMenuItem *> *items = [self menuItems];
  for (RCTDevMenuItem *item in items) {
    switch (item.type) {
      case RCTDevMenuTypeButton: {
        [_actionSheet addAction:[UIAlertAction actionWithTitle:item.title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(__unused UIAlertAction *action) {
                                                         // Cancel button tappped.
                                                         [item callHandler];
                                                       }]];
        break;
      }
        default:
        break;
    }
  }

  [_actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(__unused UIAlertAction *action) {
                                                 }]];

  [RCTPresentedViewController() presentViewController:_actionSheet animated:YES completion:^(void){}];
}

- (void)setExecutorClass:(Class)executorClass
{
	if (_bridge.debugMode) {
		if (_executorClass != executorClass) {
			_executorClass = executorClass;
		}

		if (_bridge.executorClass != executorClass) {

			// TODO (6929129): we can remove this special case test once we have better
			// support for custom executors in the dev menu. But right now this is
			// needed to prevent overriding a custom executor with the default if a
			// custom executor has been set directly on the bridge
			_bridge.executorClass = executorClass;
			[_bridge reload];
		}
	}
}

@end

#else // Unavailable when not in dev mode

@implementation RCTDevMenu

- (void)show {}
- (void)reload {}
- (void)addItem:(__unused NSString *)title handler:(__unused dispatch_block_t)handler {}
- (void)addItem:(__unused RCTDevMenu *)item {}

@end

#endif

@implementation  RCTBridge (RCTDevMenu)

- (RCTDevMenu *)devMenu
{
#if RCT_DEV
  return [self moduleForClass:[RCTDevMenu class]];
#else
  return nil;
#endif
}

@end
