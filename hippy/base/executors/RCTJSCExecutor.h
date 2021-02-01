/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <JavaScriptCore/JavaScriptCore.h>

#import "RCTJavaScriptExecutor.h"

typedef void (^RCTJavaScriptValueCallback)(JSValue *result, NSError *error);

/**
 * Default name for the JS thread
 */
RCT_EXTERN NSString *const RCTJSCThreadName;

/**
 * This notification fires on the JS thread immediately after a `JSContext`
 * is fully initialized, but before the JS bundle has been loaded. The object
 * of this notification is the `JSContext`. Native modules should listen for
 * notification only if they need to install custom functionality into the
 * context. Note that this notification won't fire when debugging in Chrome.
 */
RCT_EXTERN NSString *const RCTJavaScriptContextCreatedNotification;

/**
 * A key to a reference to a JSContext class, held in the the current thread's
 *  dictionary. The reference would point to the JSContext class in the JS VM
 *  used in React (or ComponenetScript). It is recommended not to access it
 *  through the thread's dictionary, but rather to use the `FBJSCurrentContext()`
 *  accessor, which will return the current JSContext in the currently used VM.
 */
RCT_EXTERN NSString *const RCTFBJSContextClassKey;

/**
 * A key to a reference to a JSValue class, held in the the current thread's
 *  dictionary. The reference would point to the JSValue class in the JS VM
 *  used in React (or ComponenetScript). It is recommended not to access it
 *  through the thread's dictionary, but rather to use the `FBJSValue()` accessor.
 */
RCT_EXTERN NSString *const RCTFBJSValueClassKey;

/**
 * Uses a JavaScriptCore context as the execution engine.
 */
@interface RCTJSCExecutor : NSObject <RCTJavaScriptExecutor>

/**
 * Specify a name for the JSContext used, which will be visible in debugging tools
 * @default is "RCTJSContext"
 */
@property (nonatomic, copy) NSString *contextName;

/**
 * Invokes the given module/method directly. The completion block will be called with the
 * JSValue returned by the JS context.
 *
 * Currently this does not flush the JS-to-native message queue.
 */
- (void)callFunctionOnModule:(NSString *)module
                      method:(NSString *)method
                   arguments:(NSArray *)args
             jsValueCallback:(RCTJavaScriptValueCallback)onComplete;

@end
