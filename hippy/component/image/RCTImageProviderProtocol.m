//
//  RCTImageProviderProtocol.m
//  hippy
//
//  Created by ozonelmy on 2020/8/6.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "RCTImageProviderProtocol.h"
#import "objc/runtime.h"
#import "RCTBridge.h"

Class<RCTImageProviderProtocol> imageProviderClass(NSData *data, RCTBridge *bridge) {
    NSSet<Class<RCTImageProviderProtocol>> *classes = [bridge imageProviders];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([evaluatedObject conformsToProtocol:@protocol(RCTImageProviderProtocol)]) {
            Class<RCTImageProviderProtocol> class = (Class<RCTImageProviderProtocol>)evaluatedObject;
            return [class canHandleData:data];
        }
        else {
            return NO;
        }
    }];
    NSSet<Class<RCTImageProviderProtocol>> *sub = [classes filteredSetUsingPredicate:predicate];
    Class<RCTImageProviderProtocol> candidate = nil;
    for (Class<RCTImageProviderProtocol> class in sub) {
        if (nil == candidate) {
            candidate = class;
        }
        else {
            NSUInteger candidatePriority = [candidate priorityForData:data];
            NSUInteger classPriority = [class priorityForData:data];
            if (classPriority > candidatePriority) {
                candidate = class;
            }
        }
    }
    return candidate;
}
