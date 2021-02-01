//
//  BundleManager.h
//  demo
//
//  Created by pennyli on 2018/6/20.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BundleManager : NSObject

@property (nonatomic, readonly) NSString *bundlePath;

+ (instancetype)sharedInstance;
- (void)checkAndUpdate;

@end
