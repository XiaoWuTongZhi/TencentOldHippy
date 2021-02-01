//
//  RCTJSEnginesMapper.h
//  hippy
//
//  Created by ozonelmy on 2020/5/27.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "engine.h"

@interface RCTJSEnginesMapper : NSObject

+ (instancetype)defaultInstance;

- (std::shared_ptr<Engine>)JSEngineForKey:(NSString *)key;

- (std::shared_ptr<Engine>)createJSEngineForKey:(NSString *)key;

- (void)removeEngineForKey:(NSString *)key;

@end
