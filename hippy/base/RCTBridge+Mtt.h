//
//  RCTBridge+Mtt.h
//  mtt
//
//  Created by halehuang(黄灏涛) on 2017/2/16.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "RCTBridge.h"

extern NSString *const RCTSecondaryBundleDidStartLoadNotification;
extern NSString *const RCTSecondaryBundleDidLoadSourceCodeNotification;
extern NSString *const RCTSecondaryBundleDidLoadNotification;

typedef void(^SecondaryBundleLoadingCompletion)(NSError *);
typedef void(^SecondaryBundleCompletion)(BOOL);

@interface RCTBridge (Mtt)

- (BOOL)isSecondaryBundleURLLoaded:(NSURL *)secondaryBundleURL;

- (void)loadSecondary:(NSURL *)secondaryBundleURL loadBundleCompletion:(SecondaryBundleLoadingCompletion)loadBundleCompletion enqueueScriptCompletion:(SecondaryBundleLoadingCompletion)enqueueScriptCompletion completion:(SecondaryBundleCompletion)completion;

@end
