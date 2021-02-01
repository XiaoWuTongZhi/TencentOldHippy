//
//  HPAnimation+Value.h
//  Hippy
//
//  Created by pennyli on 2018/1/25.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTExtAnimation.h"
#import <UIKit/UIKit.h>

@interface RCTExtAnimation(Value)

@property (nonatomic, strong) id fromValue;
@property (nonatomic, strong) id toValue;
@property (nonatomic, strong) id byValue;

- (void)calcValueWithCenter:(CGPoint)center forProp:(NSString *)prop;
@end
