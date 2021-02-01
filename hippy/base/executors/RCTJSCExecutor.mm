/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTJSCExecutor.h"

#import <cinttypes>
#import <memory>
#import <pthread.h>
#import <string>
#import <unordered_map>

#import <UIKit/UIDevice.h>

#import "RCTAssert.h"
#import "RCTBridge+Private.h"
#import "RCTDefines.h"
#import "RCTDevMenu.h"
#import "RCTJavaScriptLoader.h"
#import "RCTLog.h"
#import "RCTPerformanceLogger.h"
#import "RCTUtils.h"
#import "RCTRedBox.h"
#import "RCTJSCErrorHandling.h"
#include "js-native-api-jsc.h"
#include "javascript-task.h"
#include "js-native-api.h"
#include "scope.h"
#include "javascript-task-runner.h"
#include "engine.h"
#import "RCTJSEnginesMapper.h"

NSString *const RCTJSCThreadName = @"com.tencent.hippy.JavaScript";
NSString *const RCTJavaScriptContextCreatedNotification = @"RCTJavaScriptContextCreatedNotification";
RCT_EXTERN NSString *const RCTFBJSContextClassKey = @"_RCTFBJSContextClassKey";
RCT_EXTERN NSString *const RCTFBJSValueClassKey = @"_RCTFBJSValueClassKey";

struct __attribute__((packed)) ModuleData {
    uint32_t offset;
    uint32_t size;
};

using file_ptr = std::unique_ptr<FILE, decltype(&fclose)>;
using memory_ptr = std::unique_ptr<void, decltype(&free)>;

struct RandomAccessBundleData {
    file_ptr bundle;
    size_t baseOffset;
    size_t numTableEntries;
    std::unique_ptr<ModuleData[]> table;
    RandomAccessBundleData(): bundle(nullptr, fclose) {}
};

@implementation RCTJSCExecutor
{
    // Set at setUp time:
    RCTPerformanceLogger *_performanceLogger;
    JSContext *_JSContext;
    // Set as needed:
    RandomAccessBundleData _randomAccessBundle;
    JSValueRef _batchedBridgeRef;
}

@synthesize valid = _valid;
@synthesize executorkey = _executorkey;
@synthesize bridge = _bridge;
@synthesize pScope = _pScope;
@synthesize JSGlobalContextRef = _JSGlobalContextRef;

RCT_EXPORT_MODULE()

- (void)setBridge:(RCTBridge *)bridge
{
    if (_bridge != bridge) {
        _bridge = bridge;
        _performanceLogger = [bridge performanceLogger];
    }
}

- (instancetype)initWithExecurotKey:(NSString *)execurotkey bridge:(RCTBridge *)bridge {
    
    if (self = [super init]) {
        _valid = YES;
        //当前JSCore有个bug导致无法实现单VM对应多个context：
        //context无法被删除，一直被VM持有。除非移除VM
        self.executorkey = execurotkey;
        self.bridge = bridge;
        std::shared_ptr<Engine> engine = [[RCTJSEnginesMapper defaultInstance] createJSEngineForKey:self.executorkey];
        std::unique_ptr<Engine::RegisterMap> map = [self registerMap];
        const char *pName = [execurotkey UTF8String]?:"";
        std::shared_ptr<Scope> scope = engine->CreateScope(pName, std::move(map));
        self.pScope = scope;
    }
    
    return self;
}

- (std::unique_ptr<Engine::RegisterMap>) registerMap {
    __weak RCTJSCExecutor *weakSelf = self;
    hippy::base::RegisterFunction taskEndCB = [weakSelf](void *){
        RCTJSCExecutor *strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf->_bridge handleBuffer:nil batchEnded:YES];
        }
    };
    hippy::base::RegisterFunction ctxCreateCB = [weakSelf](void* p){
        RCTJSCExecutor *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        ScopeWrapper* wrapper = reinterpret_cast<ScopeWrapper*>(p);
        std::shared_ptr<Scope> scope = wrapper->scope_.lock();
        if (scope) {
            RCTBridge *bridge = [strongSelf bridge];
            if (!bridge) {
                NSError *error = RCTErrorWithMessage(@"bridge is nil");
                RCTFatal(error);
            }
            std::shared_ptr<hippy::napi::JSCCtx> context = std::static_pointer_cast<hippy::napi::JSCCtx>(scope->GetContext());
            context->RegisterGlobalInJs();
            NSString *devInfoString = [bridge deviceInfo];
            context->SetGlobalVar("__HIPPYNATIVEGLOBAL__", [devInfoString UTF8String]);
            context->SetGlobalVar("__fbBatchedBridgeConfig", [[bridge moduleConfig] UTF8String]);
            JSContext* jsContext = [JSContext contextWithJSGlobalContextRef:context->GetCtxRef()];
            installBasicSynchronousHooksOnContext(jsContext);
            jsContext[@"reportUncaughtException"] = ^(NSString* err) {
                RCTJSCExecutor *strongSelf = weakSelf;
                if (strongSelf && err) {
                    NSError *error = RCTErrorWithMessageAndModule(err, bridge.moduleName);
                    RCTFatal(error);
                }
            };
            jsContext[@"nativeRequireModuleConfig"] = ^NSArray *(NSString *moduleName) {
                RCTJSCExecutor *strongSelf = weakSelf;
                if (!strongSelf.valid) {
                    return nil;
                }
              
                //RCT_PROFILE_BEGIN_EVENT(RCTProfileTagAlways, @"nativeRequireModuleConfig", @{ @"moduleName": moduleName });
                NSArray *result = [strongSelf->_bridge configForModuleName:moduleName];
                //RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"js_call,config");
                return RCTNullIfNil(result);
            };
          
            jsContext[@"nativeFlushQueueImmediate"] = ^(NSArray<NSArray *> *calls){
                RCTJSCExecutor *strongSelf = weakSelf;
                if (!strongSelf.valid || !calls) {
                    return;
                }
                
                //RCT_PROFILE_BEGIN_EVENT(RCTProfileTagAlways, @"nativeFlushQueueImmediate", nil);
                [strongSelf->_bridge handleBuffer:calls batchEnded:NO];
                //RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"js_call");
            };
            
            jsContext[@"nativeCallSyncHook"] = ^id(NSUInteger module, NSUInteger method, NSArray *args) {
                RCTJSCExecutor *strongSelf = weakSelf;
                if (!strongSelf.valid) {
                    return nil;
                }
              
              //RCT_PROFILE_BEGIN_EVENT(RCTProfileTagAlways, @"nativeCallSyncHook", nil);
                id result = [strongSelf->_bridge callNativeModule:module method:method params:args];
              //RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"js_call,config");
                return result;
            };
            
        #if RCT_DEV
            // Inject handler used by HMR
            jsContext[@"nativeInjectHMRUpdate"] = ^(NSString *sourceCode, NSString *sourceCodeURL) {
                RCTJSCExecutor *strongSelf = weakSelf;
                if (!strongSelf.valid) {
                    return;
                }
              
                JSStringRef execJSString = JSStringCreateWithUTF8CString(sourceCode.UTF8String);
                JSStringRef jsURL = JSStringCreateWithUTF8CString(sourceCodeURL.UTF8String);
                JSEvaluateScript([strongSelf JSGlobalContextRef], execJSString, NULL, jsURL, 0, NULL);
                JSStringRelease(jsURL);
                JSStringRelease(execJSString);
            };
        #endif
        }
    };
    hippy::base::RegisterFunction jsExceptionCB = [weakSelf](void *p) {
        RCTJSCExecutor *strongSelf = weakSelf;
        if (strongSelf && p) {
            const char *errorString = (char*)p;
            NSString *err = [NSString stringWithUTF8String:errorString];
            NSError *error = RCTErrorWithMessageAndModule(err, strongSelf.bridge.moduleName);
            RCTFatal(error);
        }
    };
    
    std::unique_ptr<hippy::base::RegisterMap> ptr = std::make_unique<hippy::base::RegisterMap>();
    ptr->insert(std::make_pair(hippy::base::kAsyncTaskEndKey, taskEndCB));
    ptr->insert(std::make_pair(hippy::base::kContextCreatedCBKey, ctxCreateCB));
    ptr->insert(std::make_pair(hippy::base::kHandleExceptionKey, jsExceptionCB));
    return ptr;
}

- (JSContext *)JSContext {
    if (nil == _JSContext) {
        _JSContext = [JSContext contextWithJSGlobalContextRef:[self JSGlobalContextRef]];
        if (_JSContext) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RCTJavaScriptContextCreatedNotification
                                                                object:_JSContext];
        }
    }
    return _JSContext;
}

- (JSGlobalContextRef)JSGlobalContextRef {
    if (nil == _JSGlobalContextRef) {
        std::shared_ptr<Scope> scope = self.pScope;
        if (scope) {
            std::shared_ptr<hippy::napi::Ctx> napiCtx = scope->GetContext();
            std::shared_ptr<hippy::napi::JSCCtx> jscContext = std::static_pointer_cast<hippy::napi::JSCCtx>(napiCtx);
            _JSGlobalContextRef = jscContext->GetCtxRef();
        }
    }
    return _JSGlobalContextRef;
}

- (BOOL)_synchronouslyExecuteApplicationScript:(NSData *)script
                                     sourceURL:(NSURL *)sourceURL
                                     JSContext:(JSContext *)context
                                         error:(NSError **)error
{
    BOOL isRAMBundle = NO;
    script = loadPossiblyBundledApplicationScript(script, sourceURL, _performanceLogger, isRAMBundle, _randomAccessBundle, error);
    if (!script) {
        return NO;
    }
    if (isRAMBundle) {
        registerNativeRequire(context, self);
    }
    NSError *returnedError = executeApplicationScript(script, sourceURL, _performanceLogger, [self JSGlobalContextRef]);
    if (returnedError) {
        if (error) {
            *error = returnedError;
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)setUp
{
    [self executeBlockOnJavaScriptQueue:^{
        if (!self.valid) {
            return;
        }
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        if (!threadDictionary[RCTFBJSContextClassKey] || !threadDictionary[RCTFBJSValueClassKey]) {
            threadDictionary[RCTFBJSContextClassKey] = [JSContext class];
            threadDictionary[RCTFBJSValueClassKey] = [JSValue class];
        }
    }];
}

/** Installs synchronous hooks that don't require a weak reference back to the RCTJSCExecutor. */
static void installBasicSynchronousHooksOnContext(JSContext *context)
{
    context[@"nativeLoggingHook"] = ^(NSString *message, NSNumber *logLevel) {
        RCTLogLevel level = RCTLogLevelInfo;
        if (logLevel) {
            level = MAX(level, (RCTLogLevel)logLevel.integerValue);
        }
        
        _RCTLogJavaScriptInternal(level, message);
    };
    context[@"nativePerformanceNow"] = ^{
        return @(CACurrentMediaTime() * 1000);
    };
}

- (void)invalidate
{
    if (!self.isValid) {
        return;
    }
    _valid = NO;
    self.pScope = nullptr;
    _JSContext.name = @"RCTJSContext(delete)";
    _JSContext = nil;
    _JSGlobalContextRef = NULL;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RCTJSEnginesMapper defaultInstance] removeEngineForKey:[self executorkey]];
    });
}

- (NSString *)contextName
{
    return [[self JSContext] name];
}

- (NSString *)executorkey {
    return _executorkey?:[NSString stringWithFormat:@"%p", self];
}

RCT_EXPORT_METHOD(setContextName:(nonnull NSString *)contextName)
{
    [self executeBlockOnJavaScriptQueue:^{
        [[self JSContext] setName:contextName];
    }];
}

- (void)dealloc
{
    [self invalidate];
        
    _randomAccessBundle.bundle.reset();
    _randomAccessBundle.table.reset();
}

- (void)flushedQueue:(RCTJavaScriptCallback)onComplete
{
    // TODO: Make this function handle first class instead of dynamically dispatching it. #9317773
    [self _executeJSCall:@"flushedQueue" arguments:@[] unwrapResult:YES callback:onComplete];
}

- (void)_callFunctionOnModule:(NSString *)module
                       method:(NSString *)method
                    arguments:(NSArray *)args
                  returnValue:(BOOL)returnValue
                 unwrapResult:(BOOL)unwrapResult
                     callback:(RCTJavaScriptCallback)onComplete
{
    // TODO: Make this function handle first class instead of dynamically dispatching it. #9317773
    NSString *bridgeMethod = returnValue ? @"callFunctionReturnFlushedQueue" : @"callFunctionReturnResultAndFlushedQueue";
    [self _executeJSCall:bridgeMethod arguments:@[module, method, args] unwrapResult:unwrapResult callback:onComplete];
}

- (void)callFunctionOnModule:(NSString *)module method:(NSString *)method arguments:(NSArray *)args callback:(RCTJavaScriptCallback)onComplete
{
    [self _callFunctionOnModule:module method:method arguments:args returnValue:YES unwrapResult:YES callback:onComplete];
}

- (void)callFunctionOnModule:(NSString *)module method:(NSString *)method arguments:(NSArray *)args jsValueCallback:(RCTJavaScriptValueCallback)onComplete
{
    [self _callFunctionOnModule:module method:method arguments:args returnValue:NO unwrapResult:NO callback:onComplete];
}

- (void)invokeCallbackID:(NSNumber *)cbID
               arguments:(NSArray *)args
                callback:(RCTJavaScriptCallback)onComplete
{
    // TODO: Make this function handle first class instead of dynamically dispatching it. #9317773
    [self _executeJSCall:@"invokeCallbackAndReturnFlushedQueue" arguments:@[cbID, args] unwrapResult:YES callback:onComplete];
}

- (void)_executeJSCall:(NSString *)method
             arguments:(NSArray *)arguments
          unwrapResult:(BOOL)unwrapResult
              callback:(RCTJavaScriptCallback)onComplete
{
    RCTAssert(onComplete != nil, @"onComplete block should not be nil");
    __weak RCTJSCExecutor *weakSelf = self;
    [self executeBlockOnJavaScriptQueue:^{
        @autoreleasepool {
            RCTJSCExecutor *strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.isValid || nullptr == strongSelf.pScope) {
                return;
            }
            
#ifndef RCT_DEBUG
            @try {
#endif
                RCTBridge *bridge = [strongSelf bridge];
                NSString *moduleName = [bridge moduleName];
                NSError *executeError = nil;
                id objcValue = nil;
                std::shared_ptr<hippy::napi::Ctx> jsccontext = self.pScope->GetContext();
                std::shared_ptr<hippy::napi::CtxValue> batchedbridge_value = jsccontext->GetGlobalVar("__fbBatchedBridge");
                std::shared_ptr<hippy::napi::JSCCtxValue> jsc_resultValue = nullptr;
                std::shared_ptr<std::string> exception = nullptr;
                if (batchedbridge_value) {
                    std::shared_ptr<hippy::napi::CtxValue> method_value = jsccontext->GetProperty(batchedbridge_value, [method UTF8String]);
                    if (method_value) {
                        if (jsccontext->IsFunction(method_value)) {
                            std::shared_ptr<hippy::napi::CtxValue> function_params[arguments.count];
                            for (NSUInteger i = 0; i < arguments.count; i++) {
                                JSValueRef value = [JSValue valueWithObject:arguments[i] inContext:[strongSelf JSContext]].JSValueRef;
                                function_params[i] = std::make_shared<hippy::napi::JSCCtxValue>([strongSelf JSGlobalContextRef], value);
                            }
                            std::shared_ptr<hippy::napi::CtxValue> resultValue = jsccontext->CallFunction(method_value, arguments.count, function_params, &exception);
                            jsc_resultValue = std::static_pointer_cast<hippy::napi::JSCCtxValue>(resultValue);
                        }
                        else {
                            executeError = RCTErrorWithMessageAndModule([NSString stringWithFormat:@"%@ is not a function", method], moduleName);
                        }
                    }
                    else {
                        executeError = RCTErrorWithMessageAndModule([NSString stringWithFormat:@"property/function %@ not found in __fbBatchedBridge", method], moduleName);
                    }
                }
                else {
                    executeError = RCTErrorWithMessageAndModule(@"__fbBatchedBridge not found", moduleName);
                }
                if (exception || executeError) {
                    if (exception) {
                        NSString *string = [NSString stringWithUTF8String:exception->c_str()];
                        executeError = RCTErrorWithMessageAndModule(string, moduleName);
                    }
                }
                else if (jsc_resultValue) {
                    JSValueRef resutlRef = jsc_resultValue->value_;
                    JSValue *objc_value = [JSValue valueWithJSValueRef:resutlRef inContext:[strongSelf JSContext]];
                    objcValue = unwrapResult ? [objc_value toObject] : objc_value;
                }
                onComplete(objcValue, executeError);
#ifndef RCT_DEBUG
            } @catch (NSException *exception) {
                MttHippyException(exception);
            }
#endif
        }
    }];
}

- (void)executeApplicationScript:(NSData *)script
                       sourceURL:(NSURL *)sourceURL
                      onComplete:(RCTJavaScriptCompleteBlock)onComplete
{
    RCTAssertParam(script);
    RCTAssertParam(sourceURL);
    
    BOOL isRAMBundle = NO;
    {
        NSError *error;
        script = loadPossiblyBundledApplicationScript(script, sourceURL, _performanceLogger, isRAMBundle, _randomAccessBundle, &error);
        if (script == nil) {
            if (onComplete) {
                onComplete(error);
            }
            return;
        }
    }
    
    //RCTProfileBeginFlowEvent();
    [self executeBlockOnJavaScriptQueue:^{
        //RCTProfileEndFlowEvent();
        if (!self.isValid) {
            return;
        }
        
        if (isRAMBundle) {
            registerNativeRequire([self JSContext], self);
        }
        
        NSError *error = executeApplicationScript(script, sourceURL, self->_performanceLogger,
                                                  [self JSGlobalContextRef]);
        if (onComplete) {
            onComplete(error);
        }
    }];
}

static NSData *loadPossiblyBundledApplicationScript(NSData *script, __unused NSURL *sourceURL,
                                                    __unused RCTPerformanceLogger *performanceLogger,
                                                    __unused BOOL &isRAMBundle, __unused RandomAccessBundleData &randomAccessBundle,
                                                    __unused NSError **error)
{
    // JSStringCreateWithUTF8CString expects a null terminated C string.
    // RAM Bundling already provides a null terminated one.
    NSMutableData *nullTerminatedScript = [NSMutableData dataWithCapacity:script.length + 1];
    [nullTerminatedScript appendData:script];
    [nullTerminatedScript appendBytes:"" length:1];
    script = nullTerminatedScript;
    return script;
}

static void registerNativeRequire(JSContext *context, RCTJSCExecutor *executor)
{
    __weak RCTJSCExecutor *weakExecutor = executor;
    context[@"nativeRequire"] = ^(NSNumber *moduleID) { [weakExecutor _nativeRequire:moduleID]; };
}

static NSLock *jslock() {
    static dispatch_once_t onceToken;
    static NSLock *lock = nil;
    dispatch_once(&onceToken, ^{
        lock = [[NSLock alloc] init];
    });
    return lock;
}

static NSError *executeApplicationScript(NSData *script, NSURL *sourceURL, RCTPerformanceLogger *performanceLogger, JSGlobalContextRef ctx)
{
    [performanceLogger markStartForTag:RCTPLScriptExecution];
    JSValueRef jsError = NULL;
    JSStringRef execJSString = JSStringCreateWithUTF8CString((const char *)script.bytes);
    JSStringRef bundleURL = JSStringCreateWithUTF8CString(sourceURL.absoluteString.UTF8String);

    NSLock *lock = jslock();
    BOOL lockSuccess = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    JSEvaluateScript(ctx, execJSString, NULL, bundleURL, 0, &jsError);
    JSStringRelease(bundleURL);
    JSStringRelease(execJSString);
    if (lockSuccess) {
        [lock unlock];
    }
    
    [performanceLogger markStopForTag:RCTPLScriptExecution];
    
    NSError *error = jsError ? RCTNSErrorFromJSErrorRef(jsError, ctx) : nil;
    //RCT_PROFILE_END_EVENT(0, @"js_call");
    return error;
}

- (void)executeBlockOnJavaScriptQueue:(dispatch_block_t)block
{
    Engine* engine = [[RCTJSEnginesMapper defaultInstance] JSEngineForKey:self.executorkey].get();
    if (engine) {
        if (engine->GetJSRunner()->IsJsThread() == false) {
            std::shared_ptr<JavaScriptTask> task = std::make_shared<JavaScriptTask>();
            task->callback = block;
            engine->GetJSRunner()->PostTask(task);
        } else {
            block();
        }
    }
}

- (void)executeAsyncBlockOnJavaScriptQueue:(dispatch_block_t)block
{
    Engine* engine = [[RCTJSEnginesMapper defaultInstance] JSEngineForKey:self.executorkey].get();
    if (engine) {
        std::shared_ptr<JavaScriptTask> task = std::make_shared<JavaScriptTask>();
        task->callback = block;
        engine->GetJSRunner()->PostTask(task);
    }
}

- (void)injectJSONText:(NSString *)script
   asGlobalObjectNamed:(NSString *)objectName
              callback:(RCTJavaScriptCompleteBlock)onComplete
{
    NSAssert(nil != script, @"param 'script' can't be nil");
    if (nil == script) {
        if (onComplete) {
            NSString *errorMessage = [NSString stringWithFormat:@"param 'script' is nil"];
            NSError *error = [NSError errorWithDomain:RCTErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            onComplete(error);
        }
        return;
    }
    if (RCT_DEBUG) {
        RCTAssert(RCTJSONParse(script, NULL) != nil, @"%@ wasn't valid JSON!", script);
    }
    
    __weak RCTJSCExecutor *weakSelf = self;
    //RCTProfileBeginFlowEvent();
    [self executeBlockOnJavaScriptQueue:^{
        //RCTProfileEndFlowEvent();
        
        RCTJSCExecutor *strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.isValid) {
            return;
        }
        
        //RCT_PROFILE_BEGIN_EVENT(0, @"injectJSONText", @{@"objectName": objectName});
        JSStringRef execJSString = JSStringCreateWithCFString((__bridge CFStringRef)script);
        JSGlobalContextRef ctx = [strongSelf JSGlobalContextRef];
        JSValueRef valueToInject = JSValueMakeFromJSONString(ctx, execJSString);
        JSStringRelease(execJSString);
        
        NSError *error;
        if (!valueToInject) {
            NSString *errorMessage = [NSString stringWithFormat:@"Can't make JSON value from script '%@'", script];
            error = [NSError errorWithDomain:RCTErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            RCTLogError(@"%@", errorMessage);
        } else {
            JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
            JSStringRef JSName = JSStringCreateWithCFString((__bridge CFStringRef)objectName);
            JSValueRef jsError = NULL;
            JSObjectSetProperty(ctx, globalObject, JSName, valueToInject, kJSPropertyAttributeNone, &jsError);
            JSStringRelease(JSName);
            
            if (jsError) {
                error = RCTNSErrorFromJSErrorRef(jsError, ctx);
            }
        }
        //RCT_PROFILE_END_EVENT(0, @"js_call,json_call");
        
        if (onComplete) {
            onComplete(error);
        }
    }];
}

static bool readRandomAccessModule(const RandomAccessBundleData &bundleData, size_t offset, size_t size, char *data)
{
    return fseek(bundleData.bundle.get(), offset + bundleData.baseOffset, SEEK_SET) == 0 &&
    fread(data, 1, size, bundleData.bundle.get()) == size;
}

static void executeRandomAccessModule(RCTJSCExecutor *executor, uint32_t moduleID, size_t offset, size_t size)
{
    auto data = std::make_unique<char[]>(size);
    if (!readRandomAccessModule(executor->_randomAccessBundle, offset, size, data.get())) {
        RCTFatal(RCTErrorWithMessage(@"Error loading RAM module"));
        return;
    }
    
    char url[14]; // 10 = maximum decimal digits in a 32bit unsigned int + ".js" + null byte
    sprintf(url, "%" PRIu32 ".js", moduleID);
    
    JSStringRef code = JSStringCreateWithUTF8CString(data.get());
    JSValueRef jsError = NULL;
    JSStringRef sourceURL = JSStringCreateWithUTF8CString(url);
    JSGlobalContextRef ctx = [executor JSGlobalContextRef];
    JSValueRef result = JSEvaluateScript(ctx, code, NULL, sourceURL, 0, &jsError);
    
    JSStringRelease(code);
    JSStringRelease(sourceURL);
    
    if (!result) {
        NSError *error = RCTNSErrorFromJSErrorRef(jsError, ctx);
        dispatch_async(dispatch_get_main_queue(), ^{
            RCTFatal(error);
            [executor invalidate];
        });
    }
}

- (void)_nativeRequire:(NSNumber *)moduleID
{
    if (!moduleID) {
        return;
    }
    
    [_performanceLogger addValue:1 forTag:RCTPLRAMNativeRequiresCount];
    [_performanceLogger appendStartForTag:RCTPLRAMNativeRequires];
    //RCT_PROFILE_BEGIN_EVENT(RCTProfileTagAlways, ([@"nativeRequire_" stringByAppendingFormat:@"%@", moduleID]), nil);
    
    const uint32_t ID = [moduleID unsignedIntValue];
    
    if (ID < _randomAccessBundle.numTableEntries) {
        ModuleData *moduleData = &_randomAccessBundle.table[ID];
        const uint32_t size = NSSwapLittleIntToHost(moduleData->size);
        
        // sparse entry in the table -- module does not exist or is contained in the startup section
        if (size == 0) {
            return;
        }
        
        executeRandomAccessModule(self, ID, NSSwapLittleIntToHost(moduleData->offset), size);
    }
    
    //RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"js_call");
    [_performanceLogger appendStopForTag:RCTPLRAMNativeRequires];
}

@end
