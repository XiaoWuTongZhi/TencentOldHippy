//
//  QBRNVirtualNode.m
//  mtt
//
//  Created by pennyli on 2017/8/17.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "RCTVirtualNode.h"

@implementation UIView (RCTRemoveNode)
- (void)removeView:(RCTRemoveViewForShadow)removeBlock
{
	removeBlock(self.reactTag);
	
	for (UIView *view in self.subviews) {
		[view removeView: removeBlock];
	}
}
@end

@implementation RCTVirtualNode

@synthesize viewName = _viewName;
@synthesize reactTag = _reactTag;
@synthesize props = _props;
@synthesize frame = _frame;
@synthesize parent = _parent;
@synthesize rootTag = _rootTag;

+ (RCTVirtualNode *)createNode:(NSNumber *)reactTag
                      viewName:(NSString *)viewName
                         props:(NSDictionary *)props
{
	RCTAssertParam(reactTag);
	RCTAssertParam(viewName);
	
	RCTVirtualNode *node = [[[self class] alloc] initWithTag: reactTag viewName: viewName props: props];
	return node;
}

- (instancetype)initWithTag:(NSNumber *)reactTag viewName:(NSString *)viewName props:(NSDictionary *)props
{
	if (self = [super init]) {
		self.reactTag = reactTag;
		_viewName = viewName;
		_subNodes = [NSMutableArray array];
		_props = [props copy];
	}
	return self;
}


- (void)reactSetFrame:(CGRect)frame
{
	self.frame = frame;
}

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(__unused NSInteger)atIndex
{
	[self.subNodes insertObject: subview atIndex: atIndex];
}

- (void)removeReactSubview:(id<RCTComponent>)subview
{
	[self.subNodes removeObject: subview];
}

- (NSArray<id<RCTComponent>> *)reactSubviews
{
	return self.subNodes;
}

- (id<RCTComponent>)reactSuperview
{
	return self.parent;
}

- (NSNumber *)reactTagAtPoint:(__unused CGPoint)point
{
	return self.reactTag;
}

- (BOOL)isReactRootView
{
	return NO;
}

- (BOOL)isList
{
	return NO;
}

- (NSString *)description
{
	return [NSString stringWithFormat: @"reactTag: %@, viewName: %@, props:%@, frame:%@", self.reactTag, self.viewName, self.props, NSStringFromCGRect(self.frame)];
}

- (BOOL)isListSubNode
{
	return [self listNode] != nil;
}

- (RCTVirtualNode *)cellNode
{
	if (_cellNode != nil) {
		return _cellNode;
	}
	
	RCTVirtualNode *cell = self;
	if ([cell isKindOfClass: [RCTVirtualCell class]]) {
		_cellNode = (RCTVirtualCell *)cell;
	} else {
		RCTVirtualNode *parent = (RCTVirtualNode *)[cell parent];
		_cellNode = [parent cellNode];
	}
	
	return _cellNode;
}

- (RCTVirtualList *)listNode
{
	if (_listNode != nil) {
		return _listNode;
	}
	
	RCTVirtualNode *list = self;
	if ([list isKindOfClass: [RCTVirtualList class]]) {
		_listNode = (RCTVirtualList *)list;
	} else {
		RCTVirtualNode *parent = (RCTVirtualNode *)[list parent];
		_listNode = [parent listNode];
	}
	
	return _listNode;
}

- (UIView *)createView:(RCTCreateViewForShadow)createBlock insertChildrens:(RCTInsertViewForShadow)insertChildrens
{
	UIView *containerView = createBlock(self);
	NSMutableArray *childrens = [NSMutableArray new];
	for (RCTVirtualNode *node in self.subNodes) {
		UIView *view = [node createView: createBlock insertChildrens: insertChildrens];
		if (view) {
			[childrens addObject: view];
		}
	}
	insertChildrens(containerView, childrens);
	return containerView;
}

- (void)removeView:(RCTRemoveViewForShadow)removeBlock
{
	removeBlock(self.reactTag);
	
	for (RCTVirtualNode *child in self.subNodes) {
		[child removeView: removeBlock];
	}
}

- (void)updateView:(RCTUpdateViewForShadow)updateBlock withOldNode:(RCTVirtualNode *)oldNode
{
  updateBlock(self, oldNode);
  
  NSInteger index = 0;
  for (RCTVirtualNode *node in self.subNodes) {
    [node updateView: updateBlock withOldNode: oldNode.subNodes[index++]];
  }
}

- (NSDictionary *)diff:(RCTVirtualNode *)newNode
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	//key: new node tag value: parent tag,
	[result setObject: [NSMutableDictionary dictionary] forKey: @"insert"];
	// old tags
	[result setObject: [NSMutableArray array] forKey: @"remove"];
	// key: new tag, value: old tag
	[result setObject: [NSMutableDictionary dictionary] forKey: @"update"];
	// key: new tag, value: old tag
	[result setObject: [NSMutableDictionary dictionary] forKey: @"tag"];
	
	if ([self.viewName isEqualToString: newNode.viewName]) {
		if (![self.props isEqualToDictionary: newNode.props]) {
			[result[@"update"] setObject: self.reactTag forKey: newNode.reactTag];
		}
	} else {
		return nil;
	}
	
	[result[@"tag"] setObject: self.reactTag forKey: newNode.reactTag];
	
	[self _diff: newNode withResult: result];
	
	return result;
}

- (void)_diff:(RCTVirtualNode *)newNode withResult:(NSMutableDictionary *)result
{
	for (NSUInteger index = 0; index < MAX(self.subNodes.count, newNode.subNodes.count); index++) {
		
		RCTVirtualNode *oldSubNode = nil;
		RCTVirtualNode *newSubNode = nil;
		
		if (index < self.subNodes.count) {
			oldSubNode = self.subNodes[index];
		}
		if (index < newNode.subNodes.count) {
			newSubNode = newNode.subNodes[index];
		}
		
		if (oldSubNode == nil && newSubNode) { // 需要插入新的节点
			NSMutableDictionary *insertDict = result[@"insert"];
			[insertDict setObject: @{@"index": @(index), @"tag": self.reactTag} forKey: newSubNode.reactTag];
		} else if (oldSubNode && newSubNode == nil) { // 需要移除老节点
			NSMutableArray *remove = result[@"remove"];
			[remove addObject: oldSubNode.reactTag];
		} else if (oldSubNode && newSubNode) {
			if (![oldSubNode.viewName isEqualToString: newSubNode.viewName]) { // 需要插入新节点和移除老节点
				NSMutableDictionary *insertDict = result[@"insert"];
				[insertDict setObject: @{@"index": @(index), @"tag": self.reactTag} forKey: newSubNode.reactTag];
				
				NSMutableArray *remove = result[@"remove"];
				[remove addObject: oldSubNode.reactTag];
			} else {
				if (![oldSubNode.props isEqualToDictionary: newSubNode.props]) { // 需要更新节点并且继续比较子节点
					NSMutableDictionary *updateDict = result[@"update"];
					[updateDict setObject: oldSubNode.reactTag forKey: newSubNode.reactTag];
				}
				[oldSubNode _diff: newSubNode withResult: result];
				
				NSMutableDictionary *tagDict = result[@"tag"];
				[tagDict setObject: oldSubNode.reactTag  forKey: newSubNode.reactTag];
			}
		}
	}
}


@end

@implementation RCTVirtualList

- (BOOL)isListSubNode
{
	return NO;
}

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(__unused NSInteger)atIndex
{
	self.needFlush = YES;
	[super insertReactSubview: subview atIndex: atIndex];
}

- (void)removeReactSubview:(id<RCTComponent>)subview
{
	self.needFlush = YES;
	[super removeReactSubview: subview];
}
@end

@implementation RCTVirtualCell

- (NSString *)description
{
	return [NSString stringWithFormat: @"reactTag: %@, viewName: %@, props:%@ type: %@ frame:%@", self.reactTag, self.viewName, self.props, self.itemViewType
					, NSStringFromCGRect(self.frame)];
}

- (instancetype)initWithTag:(NSNumber *)tag
                   viewName:(NSString *)viewName
                      props:(NSDictionary *)props
{
	if (self = [super initWithTag: tag viewName: viewName props: props]) {
		self.itemViewType = [NSString stringWithFormat: @"%@", props[@"type"]];
		self.sticky = [props[@"sticky"] boolValue];
	}
	return self;
}


- (void)setProps:(NSDictionary *)props
{
	[super setProps: props];
	
	self.itemViewType = [NSString stringWithFormat: @"%@", props[@"type"]];
	self.sticky = [props[@"sticky"] boolValue];
}

- (void)reactSetFrame:(CGRect)frame
{
	if (!CGSizeEqualToSize(self.frame.size, CGSizeZero) && !CGSizeEqualToSize(self.frame.size, frame.size)) {
		self.listNode.needFlush = YES;
	}
	[super reactSetFrame: frame];
}

@end



