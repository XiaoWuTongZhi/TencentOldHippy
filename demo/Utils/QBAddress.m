//
//  QBAddress.m
//  mtt
//
//  Created by vectorliu on 13-5-24.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QBAddress.h"

@implementation QBAddress
@synthesize originURL = _originString;

- (id)initWithString:(NSString *)address {
    self = [super init];
    if (self) {
        _originString = address;
        _paraAndValues = [[NSMutableDictionary alloc] init];
        _isPhased = NO;
    }
    return self;
}

+ (id)qbWithString:(NSString *)address {
    return [[[self class] alloc] initWithString:address];
}


- (id)getParaForKey:(NSString *)key {
    id value = nil;
    if (!_isPhased) {
        [self phase];
    }
    value = [_paraAndValues valueForKey:key];
    
    return value ? value : @"";
}

- (NSString *)getPrefix {
    return [self getParaForKey: @"prefix"];
}
- (NSMutableDictionary *)getParaAndValues
{
    if (!_isPhased) {
        [self phase];
    }
    return _paraAndValues;
}
- (BOOL)phase {
    _isPhased = YES;
    
    if (_paraAndValues) {
        [_paraAndValues removeAllObjects];
    }
    else {
        _paraAndValues = [[NSMutableDictionary alloc] init];
    }
    
    if (!([_originString length] > 0)) {
        return NO;
    }
    
    NSString *parameterName = nil;
    NSString *parameterValue = nil;
    
    NSRange questionMarkRange = [_originString rangeOfString:@"?"];
    
    if (questionMarkRange.location == NSNotFound) {
        return NO;
    }
    
    NSString * prefix = [_originString substringToIndex:questionMarkRange.location];
    [_paraAndValues setObject:prefix forKey: @"prefix"];
    
    NSString *parameters = [_originString substringFromIndex:questionMarkRange.location + 1];
    NSArray *parameterArray = [parameters componentsSeparatedByString:@"&"];
    
    for(NSString *parameter in parameterArray){
        NSRange paramRanger = [parameter rangeOfString:@"="];
        if(paramRanger.location != NSNotFound){
            parameterName = [parameter substringToIndex: paramRanger.location];
			parameterValue = [[parameter substringFromIndex: NSMaxRange(paramRanger)] stringByRemovingPercentEncoding];
            if (parameterValue.length && parameterName.length) {
                if (![[_paraAndValues allKeys] containsObject: parameterName]) {
                    [_paraAndValues setObject:parameterValue forKey:parameterName];
                }
            }
        }
    }
    
    return YES;
}
@end

