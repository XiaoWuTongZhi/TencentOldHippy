//
//  RCTBaseListViewManager.m
//  React
//
//  Created by pennyli on 2018/4/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RCTBaseListViewManager.h"
#import "RCTBaseListView.h"
#import "RCTVirtualNode.h"

@implementation RCTBaseListViewManager

RCT_EXPORT_MODULE(ListView)

RCT_EXPORT_VIEW_PROPERTY(scrollEventThrottle, NSTimeInterval)
RCT_EXPORT_VIEW_PROPERTY(initialListReady, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScrollBeginDrag, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onScroll, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onScrollEndDrag, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMomentumScrollBegin, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMomentumScrollEnd, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRowWillDisplay, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onEndReached, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(preloadItemNumber, NSUInteger)
RCT_EXPORT_VIEW_PROPERTY(bounces, BOOL)
RCT_EXPORT_VIEW_PROPERTY(initialContentOffset, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(showScrollIndicator, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scrollEnabled, BOOL)

- (UIView *)view
{
	return [[RCTBaseListView alloc] initWithBridge: self.bridge];
}

- (RCTVirtualNode *)node:(NSNumber *)tag name:(NSString *)name props:(NSDictionary *)props
{
	return [RCTVirtualList createNode: tag viewName: name props: props];
}

RCT_EXPORT_METHOD(scrollToIndex:(nonnull NSNumber *)reactTag
									xIndex:(__unused NSNumber *)xIndex
									yIndex:(__unused NSNumber *)yIndex
									animation:(nonnull NSNumber *)animation)
{
	[self.bridge.uiManager addUIBlock:
	 ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
		 RCTBaseListView *view = (RCTBaseListView *)viewRegistry[reactTag];
		 if (view == nil) return ;
		 if (![view isKindOfClass:[RCTBaseListView class]]) {
			 RCTLogError(@"Invalid view returned from registry, expecting RCTBaseListView, got: %@", view);
		 }
		 [view scrollToIndex: yIndex.integerValue animated: [animation boolValue]];
	 }];
}

RCT_EXPORT_METHOD(scrollToContentOffset:(nonnull NSNumber *)reactTag
									x:(nonnull NSNumber *)x
									y:(nonnull NSNumber *)y
									animation:(nonnull NSNumber *)animation)
{
	[self.bridge.uiManager addUIBlock:
	 ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
		 RCTBaseListView *view = (RCTBaseListView *)viewRegistry[reactTag];
		 if (view == nil) return ;
		 if (![view isKindOfClass:[RCTBaseListView class]]) {
			 RCTLogError(@"Invalid view returned from registry, expecting RCTBaseListView, got: %@", view);
		 }
		 [view scrollToContentOffset:CGPointMake([x floatValue], [y floatValue]) animated: [animation boolValue]];
	 }];
}



@end
