//
//  RCTVirtualTextNode.m
//  RCTText
//
//  Created by pennyli on 2017/10/10.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RCTVirtualTextNode.h"
#import "RCTText.h"

@implementation RCTVirtualTextNode

- (UIView *)createView:(RCTCreateViewForShadow)createBlock insertChildrens:(RCTInsertViewForShadow)insertChildrens
{
	RCTText *textView = (RCTText *)createBlock(self);
	
	NSMutableArray *childrens = [NSMutableArray new];
	for (RCTVirtualNode *node in self.subNodes) {
//		if (![node isKindOfClass:[RCTVirtualTextNode class]]) {
			UIView *view = [node createView: createBlock insertChildrens: insertChildrens];
			if (view) {
				[childrens addObject: view];
			}
//		}
	}
	insertChildrens(textView, childrens);
	
	textView.textFrame = self.textFrame;
	textView.textStorage = self.textStorage;
	textView.extraInfo = self.extraInfo;
    textView.textColor = self.textColor;

	return textView;
}

@end
