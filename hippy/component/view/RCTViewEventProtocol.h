//
//  HPViewEventProtocol.h
//  Hippy
//
//  Created by pennyli on 2017/12/29.
//  Copyright © 2017年 pennyli. All rights reserved.
//

#ifndef HPViewEventProtocol_h
#define HPViewEventProtocol_h

#import <Foundation/Foundation.h>
#import "RCTComponent.h"

@protocol RCTViewEventProtocol

@property (nonatomic, copy) RCTDirectEventBlock onClick;
@property (nonatomic, copy) RCTDirectEventBlock onLongClick;
@property (nonatomic, copy) RCTDirectEventBlock onPressIn;
@property (nonatomic, copy) RCTDirectEventBlock onPressOut;

@property (nonatomic, copy) RCTDirectEventBlock onTouchDown;
@property (nonatomic, copy) RCTDirectEventBlock onTouchMove;
@property (nonatomic, copy) RCTDirectEventBlock onTouchEnd;
@property (nonatomic, copy) RCTDirectEventBlock onTouchCancel;
@property (nonatomic, copy) RCTDirectEventBlock onAttachedToWindow;
@property (nonatomic, copy) RCTDirectEventBlock onDetachedFromWindow;

@property (nonatomic, assign) BOOL onInterceptTouchEvent;

@end

@protocol RCTViewTouchHandlerProtocol

- (BOOL)interceptTouchEvent;

@end


#endif /* HPViewEventProtocol_h */
