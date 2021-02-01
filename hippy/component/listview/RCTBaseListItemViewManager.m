//
//  RCTBaseListItemViewManager.m
//  QBCommonRNLib
//
//  Created by pennyli on 2018/8/28.
//  Copyright © 2018年 刘海波. All rights reserved.
//

#import "RCTBaseListItemViewManager.h"
#import "RCTBaseListItemView.h"
#import "RCTVirtualNode.h"

@implementation RCTBaseListItemViewManager
RCT_EXPORT_MODULE(ListViewItem)

RCT_EXPORT_VIEW_PROPERTY(type, id)
RCT_EXPORT_VIEW_PROPERTY(isSticky, BOOL)

- (UIView *)view
{
	return [RCTBaseListItemView new];
}

- (RCTVirtualNode *)node:(NSNumber *)tag name:(NSString *)name props:(NSDictionary *)props
{
	return [RCTVirtualCell createNode: tag viewName: name props: props];
}


@end
