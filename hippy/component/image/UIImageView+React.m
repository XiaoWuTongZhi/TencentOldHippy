//
//  UIImageView+React.m
//  React
//
//  Created by jesonwang on 2018/7/6.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "UIImageView+React.h"
#import <objc/runtime.h>
#import "UIView+React.h"
#define RCTEventMethod(name, value, type) \
- (void)set##name:(type)value \
{ \
objc_setAssociatedObject(self, @selector(value), value, OBJC_ASSOCIATION_COPY_NONATOMIC);\
} \
- (type)value \
{ \
return objc_getAssociatedObject(self, _cmd); \
}

@implementation UIImageView (React)

RCTEventMethod(OnClick, onClick, RCTDirectEventBlock)
RCTEventMethod(OnPressIn, onPressIn, RCTDirectEventBlock)
RCTEventMethod(OnPressOut, onPressOut, RCTDirectEventBlock)
RCTEventMethod(OnLongClick, onLongClick, RCTDirectEventBlock)

RCTEventMethod(OnTouchDown, onTouchDown, RCTDirectEventBlock)
RCTEventMethod(OnTouchMove, onTouchMove, RCTDirectEventBlock)
RCTEventMethod(OnTouchCancel, onTouchCancel, RCTDirectEventBlock)
RCTEventMethod(OnTouchEnd, onTouchEnd, RCTDirectEventBlock)
RCTEventMethod(OnAttachedToWindow, onAttachedToWindow, RCTDirectEventBlock)
RCTEventMethod(OnDetachedFromWindow, onDetachedFromWindow, RCTDirectEventBlock)

@end
