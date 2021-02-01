//
//  RCTBaseListItemView.m
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/28.
//  Copyright © 2018年 刘海波. All rights reserved.
//

#import "RCTBaseListItemView.h"
#import "UIView+React.h"

@implementation RCTBaseListItemView

- (void)reactSetFrame:(CGRect)frame
{
	[super reactSetFrame: frame];
	self.frame = self.bounds;
}

@end
