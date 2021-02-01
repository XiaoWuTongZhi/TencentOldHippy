//
//  HPModalCustomPresentationController.m
//  Hippy
//
//  Created by pennyli on 2018/3/26.
//  Copyright © 2018年 pennyli. All rights reserved.
//

#import "RCTModalCustomPresentationController.h"

@implementation RCTModalCustomPresentationController {
	
}

- (void)presentationTransitionWillBegin
{
	self.presentedView.frame = self.containerView.frame;
	[self.containerView addSubview:self.presentedView];
}

- (void)dismissalTransitionDidEnd:(__unused BOOL)completed
{
	[self.presentedView removeFromSuperview];
}

@end
