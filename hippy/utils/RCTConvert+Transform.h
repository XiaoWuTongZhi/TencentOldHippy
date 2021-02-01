//
//  HPConvert+Transform.h
//  Hippy
//
//  Created by pennyli on 2018/1/6.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTConvert.h"

@interface RCTConvert(Transform)
+ (CATransform3D)CATransform3D:(id)json;
+ (CGFloat)convertToRadians:(id)json;
@end
