//
//  QBAddress.h
//  mtt
//
//  Created by vectorliu on 13-5-24.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

// 这个宏效率不高，string这里如果放一个表达式，就会执行两次！
#define VALID_NSSTRING(string) (string != nil && [string length] > 0)

@interface QBAddress : NSObject
{
    NSString            * _originString;
    NSMutableDictionary * _paraAndValues;
    NSArray             * _paras;
    BOOL                  _isPhased;
}

@property (nonatomic, strong, readonly)           NSString * originURL;
@property (nonatomic, strong, getter = getPrefix) NSString * prefix;

+ (id)qbWithString:(NSString *)address;

- (id)initWithString:(NSString *)address;

- (id)getParaForKey:(NSString *)key;

- (NSMutableDictionary *)getParaAndValues;

@end
