/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTAssert.h"
#import "RCTLog.h"
#import "RCTJSStackFrame.h"
NSString *const RCTErrorDomain = @"RCTErrorDomain";
NSString *const RCTJSStackTraceKey = @"RCTJSStackTraceKey";
NSString *const RCTJSRawStackTraceKey = @"RCTJSRawStackTraceKey";
NSString *const RCTFatalExceptionName = @"RCTFatalException";

static NSString *const RCTAssertFunctionStack = @"RCTAssertFunctionStack";

RCTAssertFunction RCTCurrentAssertFunction = nil;
RCTFatalHandler RCTCurrentFatalHandler = nil;
MttRCTExceptionHandler MttRCTCurrentExceptionHandler = nil;

NSException *_RCTNotImplementedException(SEL, Class);
NSException *_RCTNotImplementedException(SEL cmd, Class cls)
{
    NSString *msg = [NSString stringWithFormat:@"%s is not implemented "
                     "for the class %@", sel_getName(cmd), cls];
    return [NSException exceptionWithName:@"RCTNotDesignatedInitializerException"
                                   reason:msg userInfo:nil];
}

void RCTSetAssertFunction(RCTAssertFunction assertFunction)
{
    RCTCurrentAssertFunction = assertFunction;
}

RCTAssertFunction RCTGetAssertFunction(void)
{
    return RCTCurrentAssertFunction;
}

void RCTAddAssertFunction(RCTAssertFunction assertFunction)
{
    RCTAssertFunction existing = RCTCurrentAssertFunction;
    if (existing) {
        RCTCurrentAssertFunction = ^(NSString *condition,
                                     NSString *fileName,
                                     NSNumber *lineNumber,
                                     NSString *function,
                                     NSString *message) {
            
            existing(condition, fileName, lineNumber, function, message);
            assertFunction(condition, fileName, lineNumber, function, message);
        };
    } else {
        RCTCurrentAssertFunction = assertFunction;
    }
}

/**
 * returns the topmost stacked assert function for the current thread, which
 * may not be the same as the current value of RCTCurrentAssertFunction.
 */
static RCTAssertFunction RCTGetLocalAssertFunction()
{
    NSMutableDictionary *threadDictionary = [NSThread currentThread].threadDictionary;
    NSArray<RCTAssertFunction> *functionStack = threadDictionary[RCTAssertFunctionStack];
    RCTAssertFunction assertFunction = functionStack.lastObject;
    if (assertFunction) {
        return assertFunction;
    }
    return RCTCurrentAssertFunction;
}

void RCTPerformBlockWithAssertFunction(void (^block)(void), RCTAssertFunction assertFunction)
{
    NSMutableDictionary *threadDictionary = [NSThread currentThread].threadDictionary;
    NSMutableArray<RCTAssertFunction> *functionStack = threadDictionary[RCTAssertFunctionStack];
    if (!functionStack) {
        functionStack = [NSMutableArray new];
        threadDictionary[RCTAssertFunctionStack] = functionStack;
    }
    [functionStack addObject:assertFunction];
    block();
    [functionStack removeLastObject];
}

NSString *RCTCurrentThreadName(void)
{
    NSThread *thread = [NSThread currentThread];
    NSString *threadName = RCTIsMainQueue() || thread.isMainThread ? @"main" : thread.name;
    if (threadName.length == 0) {
        const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
        if (label && strlen(label) > 0) {
            threadName = @(label);
        } else {
            threadName = [NSString stringWithFormat:@"%p", thread];
        }
    }
    return threadName;
}

void _RCTAssertFormat(
                      const char *condition,
                      const char *fileName,
                      int lineNumber,
                      const char *function,
                      NSString *format, ...)
{
    RCTAssertFunction assertFunction = RCTGetLocalAssertFunction();
    if (assertFunction) {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        assertFunction(@(condition), @(fileName), @(lineNumber), @(function), message);
    }
}

void RCTFatal(NSError *error)
{
    NSString *failReason = error.localizedFailureReason;
    if (failReason && failReason.length >= 100) {
        failReason = [[failReason substringToIndex:100] stringByAppendingString:@"(...Description Too Long)"];
    }
    if (failReason) {
        _RCTLogNativeInternal(RCTLogLevelFatal, NULL, 0, @"%@[Reason]: %@", error.localizedDescription, failReason);
    } else {
        _RCTLogNativeInternal(RCTLogLevelFatal, NULL, 0, @"%@", error.localizedDescription);
    }
    
    
    RCTFatalHandler fatalHandler = RCTGetFatalHandler();
    if (fatalHandler) {
        fatalHandler(error);
    } else {
#ifdef DEBUG
        @try {
            NSString *name = [NSString stringWithFormat:@"%@: %@", RCTFatalExceptionName, error.localizedDescription];
            NSString *message = RCTFormatError(error.localizedDescription, error.userInfo[RCTJSStackTraceKey], 75);
            
            if (failReason) {
                name = [NSString stringWithFormat:@"%@: %@[Reason]: %@", RCTFatalExceptionName, error.localizedDescription, failReason];
            }
            
            [NSException raise:name format:@"%@", message];
        } @catch (NSException *e) {}
#endif
    }
}

void MttRCTException(NSException *exception) {
    _RCTLogNativeInternal(RCTLogLevelFatal, NULL, 0, @"%@", exception.description);
    MttRCTExceptionHandler exceptionHandler = MttRCTGetExceptionHandler();
    if (exceptionHandler) {
        exceptionHandler(exception);
    }
}

void RCTSetFatalHandler(RCTFatalHandler fatalhandler)
{
    RCTCurrentFatalHandler = fatalhandler;
}

RCTFatalHandler RCTGetFatalHandler(void)
{
    return RCTCurrentFatalHandler;
}

void MttRCTSetExceptionHandler(MttRCTExceptionHandler exceptionhandler)
{
    MttRCTCurrentExceptionHandler = exceptionhandler;
}

MttRCTExceptionHandler MttRCTGetExceptionHandler(void)
{
    return MttRCTCurrentExceptionHandler;
}

//NSString *RCTFormatError(NSString *message, NSArray<NSDictionary<NSString *, id> *> *stackTrace, NSUInteger maxMessageLength)
RCT_EXTERN NSString *RCTFormatError(NSString *message, NSArray<RCTJSStackFrame *> *stackTrace, NSUInteger maxMessageLength)
{
    if (maxMessageLength > 0 && message.length > maxMessageLength) {
        message = [[message substringToIndex:maxMessageLength] stringByAppendingString:@"..."];
    }
    
    NSMutableString *prettyStack = [NSMutableString string];
    if (stackTrace) {
        [prettyStack appendString:@", stack:\n"];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+\\.js)$"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:NULL];
        for (RCTJSStackFrame *frame in stackTrace) {
            NSString *fileName = frame.file;
            if (fileName && [regex numberOfMatchesInString:fileName options:0 range:NSMakeRange(0, [fileName length])]) {
                fileName = [fileName stringByAppendingString:@":"];
            } else {
                fileName = @"";
            }
            [prettyStack appendFormat:@"%@@%@%ld:%ld\n", frame.methodName, fileName, (long)frame.lineNumber, (long)frame.column];
        }
    }
    
    return [NSString stringWithFormat:@"%@%@", message, prettyStack];
}
