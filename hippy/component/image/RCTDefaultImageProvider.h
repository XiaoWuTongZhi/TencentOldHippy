//
//  RCTDefaultImageProvider.h
//  hippy
//
//  Created by ozonelmy on 2020/8/4.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTImageProviderProtocol.h"

@class RCTBridge;

@interface RCTDefaultImageProvider : NSObject<RCTImageProviderProtocol>

@property(nonatomic, assign) BOOL needsDownSampling;
@property(nonatomic, assign) CGSize imageViewSize;

@end
