//
//  HPExceptionModule.m
//  Hippy
//
//  Created by mengyanluo on 2018/1/19.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import "RCTExceptionModule.h"
#import "RCTLog.h"
#import "RCTAssert.h"

@implementation RCTExceptionModule

RCT_EXPORT_MODULE(ExceptionModule)

RCT_EXPORT_METHOD(handleException:(NSString *)title detail:(NSString *)detail timeInterval:(nonnull NSNumber *)timeInterval resolver:(__unused RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
	
	NSArray *stack = [detail componentsSeparatedByString: @"\n"];
	NSMutableArray *formatStacks = [[NSMutableArray alloc] initWithCapacity: stack.count];
	for(NSString *record in stack) {
		NSArray *components = [record componentsSeparatedByString: @"@"];
		if (components.count == 2) {
			NSString *method = @"unknow";
			NSString *file = @"unknow";
			NSString *line = @"-1";
			NSString *column = @"-1";
			
			method = [components firstObject];
			NSString *elsp = [components lastObject];
			NSArray *elsps = [elsp componentsSeparatedByString: @":"];
			if (elsps.count == 4) {
				file = [NSString stringWithFormat: @"%@:%@", elsps[0], elsps[1]];
				line = elsps[2];
				column = [elsps lastObject];
			}
			[formatStacks addObject: @{@"methodName": method, @"file": file, @"lineNumber": line, @"column": column}];
		}
	}
	NSDictionary *errorInfo = @{
															NSLocalizedDescriptionKey:title?:@"unknown",
                                                            NSLocalizedFailureReasonErrorKey: detail?:@"unkonwn",
															RCTJSStackTraceKey:formatStacks,
															@"RCTTimeIntervalKey":timeInterval ?:@(0),
														};

  NSError *error = [NSError errorWithDomain:RCTErrorDomain code:1 userInfo:errorInfo];
    RCTFatal(error);
}

@end
