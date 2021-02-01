/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "RCTBridgeModule.h"
#import "RCTConvert.h"
#import "RCTDefines.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "UIView+React.h"
#import "RCTBundleURLProvider.h"

@class RCTBridge;
@class RCTShadowView;
@class RCTUIManager;

typedef void (^RCTViewManagerUIBlock)(RCTUIManager *uiManager, NSDictionary<NSNumber *,__kindof UIView *> *viewRegistry);

typedef UIView* (^CreateRCTViewWithPropsBlock)(RCTBridge *bridge, NSString *classname, NSDictionary *props);


@interface RCTViewManager : NSObject <RCTBridgeModule>

/**
 * The bridge can be used to access both the RCTUIIManager and the RCTEventDispatcher,
 * allowing the manager (or the views that it manages) to manipulate the view
 * hierarchy and send events back to the JS context.
 */
@property (nonatomic, weak) RCTBridge *bridge;

/**
 * This method instantiates a native view to be managed by the module. Override
 * this to return a custom view instance, which may be preconfigured with default
 * properties, subviews, etc. This method will be called many times, and should
 * return a fresh instance each time. The view module MUST NOT cache the returned
 * view and return the same instance for subsequent calls.
 */
- (UIView *)view;

/**
 * This method instantiates a shadow view to be managed by the module. If omitted,
 * an ordinary RCTShadowView instance will be created, which is typically fine for
 * most view types. As with the -view method, the -shadowView method should return
 * a fresh instance each time it is called.
 */
- (RCTShadowView *)shadowView;


- (RCTVirtualNode *)node:(NSNumber *)tag name:(NSString *)name props:(NSDictionary *)props;


/**
 * Called to notify manager that layout has finished, in case any calculated
 * properties need to be copied over from shadow view to view.
 */
- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView;

/**
 * Called after view hierarchy manipulation has finished, and all shadow props
 * have been set, but before layout has been performed. Useful for performing
 * custom layout logic or tasks that involve walking the view hierarchy.
 * To be deprecated, hopefully.
 */
- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowViewRegistry:(NSDictionary<NSNumber *, RCTShadowView *> *)shadowViewRegistry;

/**
 * This handles the simple case, where JS and native property names match.
 */
#define RCT_EXPORT_VIEW_PROPERTY(name, type) \
+ (NSArray<NSString *> *)propConfig_##name { return @[@#type]; }

/**
 * This macro maps a named property to an arbitrary key path in the view.
 */
#define RCT_REMAP_VIEW_PROPERTY(name, keyPath, type) \
+ (NSArray<NSString *> *)propConfig_##name { return @[@#type, @#keyPath]; }

/**
 * This macro can be used when you need to provide custom logic for setting
 * view properties. The macro should be followed by a method body, which can
 * refer to "json", "view" and "defaultView" to implement the required logic.
 */
#define RCT_CUSTOM_VIEW_PROPERTY(name, type, viewClass) \
RCT_REMAP_VIEW_PROPERTY(name, __custom__, type)         \
- (void)set_##name:(id)json forView:(viewClass *)view withDefaultView:(viewClass *)defaultView

/**
 * This macro is used to map properties to the shadow view, instead of the view.
 */
#define RCT_EXPORT_SHADOW_PROPERTY(name, type) \
+ (NSArray<NSString *> *)propConfigShadow_##name { return @[@#type]; }

/**
 * This macro maps a named property to an arbitrary key path in the shadow view.
 */
#define RCT_REMAP_SHADOW_PROPERTY(name, keyPath, type) \
+ (NSArray<NSString *> *)propConfigShadow_##name { return @[@#type, @#keyPath]; }

/**
 * This macro can be used when you need to provide custom logic for setting
 * shadow view properties. The macro should be followed by a method body, which can
 * refer to "json" and "view".
 */
#define RCT_CUSTOM_SHADOW_PROPERTY(name, type, viewClass) \
RCT_REMAP_SHADOW_PROPERTY(name, __custom__, type)         \
- (void)set_##name:(id)json forShadowView:(viewClass *)view

@end

@interface RCTViewManager(Props)
@property (nonatomic, strong) NSDictionary *props;
@end
