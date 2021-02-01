//
//  RCTVirtualNode
//  mtt
//
//  Created by pennyli on 2017/8/17.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTUIManager.h"

@class RCTVirtualNode;
@class RCTVirtualList;
@class RCTVirtualCell;

@protocol RCTVirtualListComponentUpdateDelegate
- (void)virtualListDidUpdated;
@end


@interface RCTVirtualNode : NSObject <RCTComponent>

+ (RCTVirtualNode *)createNode:(NSNumber *)reactTag viewName:(NSString *)viewName props:(NSDictionary *)props;

- (instancetype)initWithTag:(NSNumber *)reactTag viewName:(NSString *)viewName props:(NSDictionary *)props;

@property (nonatomic, retain) NSMutableArray <RCTVirtualNode *> *subNodes;

@property (nonatomic, weak) RCTVirtualList *listNode;
@property (nonatomic, weak) RCTVirtualCell *cellNode;
@property (nonatomic, copy) NSNumber *rootTag;

- (BOOL)isListSubNode;


typedef UIView * (^RCTCreateViewForShadow)(RCTVirtualNode *node);
typedef UIView * (^RCTUpdateViewForShadow)(RCTVirtualNode *newNode, RCTVirtualNode *oldNode);
typedef void (^RCTInsertViewForShadow)(UIView *container, NSArray<UIView *> *childrens);
typedef void (^RCTRemoveViewForShadow)(NSNumber * reactTag);
typedef void (^RCTVirtualNodeManagerUIBlock)(RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTVirtualNode *> *virtualNodeRegistry);

- (UIView *)createView:(RCTCreateViewForShadow)createBlock insertChildrens:(RCTInsertViewForShadow)insertChildrens;
- (NSDictionary *)diff:(RCTVirtualNode *)newNode;

- (void)removeView:(RCTRemoveViewForShadow)removeBlock;

@end

@interface RCTVirtualCell: RCTVirtualNode
@property (nonatomic, copy) NSString *itemViewType;
@property (nonatomic, assign) BOOL sticky;
@property (nonatomic, weak) UIView *cell;
@end


@interface RCTVirtualList: RCTVirtualNode
@property (nonatomic, assign) BOOL needFlush;
@end

@interface UIView (RCTRemoveNode)
- (void)removeView:(RCTRemoveViewForShadow)removeBlock;
@end
