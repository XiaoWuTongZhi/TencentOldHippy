//
//  HPAnimation+Group.h
//  Hippy
//
//  Created by pennyli on 2018/1/10.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTExtAnimation.h"

@interface RCTExtAnimation(Group)
@property (nonatomic, assign) BOOL bFollow;
@property (nonatomic, assign) CFTimeInterval beginTime;
@end
