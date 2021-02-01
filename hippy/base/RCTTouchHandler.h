//
//  HPTouchHandle.h
//  HippyNative
//
//  Created by pennyli on 2017/12/25.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "RCTBridge.h"

@interface RCTTouchHandler : UIGestureRecognizer <UIGestureRecognizerDelegate>

- (instancetype)initWithRootView:(UIView *)view;
- (instancetype)initWithRootView:(UIView *)view bridge:(RCTBridge *)bridge;
- (void)cancelTouch;

@end
