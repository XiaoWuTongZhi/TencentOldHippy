//
//  RCTBaseListView.h
//  QBCommonRNLib
//
//  Created by pennyli on 2018/4/16.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTScrollView.h"
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "RCTBaseListViewProtocol.h"
#import "RCTBaseListViewDataSource.h"

@interface RCTBaseListViewCell : UITableViewCell

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) UIView *cellView;
@property (nonatomic, weak) RCTVirtualCell *node;

@end

@interface RCTBaseListView : UIView <RCTBaseListViewProtocol, RCTScrollableProtocol, UITableViewDelegate, UITableViewDataSource, RCTInvalidating>
@property (nonatomic, copy) RCTDirectEventBlock initialListReady;
@property (nonatomic, copy) RCTDirectEventBlock onScrollBeginDrag;
@property (nonatomic, copy) RCTDirectEventBlock onScroll;
@property (nonatomic, copy) RCTDirectEventBlock onScrollEndDrag;
@property (nonatomic, copy) RCTDirectEventBlock onMomentumScrollBegin;
@property (nonatomic, copy) RCTDirectEventBlock onMomentumScrollEnd;
@property (nonatomic, copy) RCTDirectEventBlock onRowWillDisplay;
@property (nonatomic, copy) RCTDirectEventBlock onEndReached;
@property (nonatomic, assign) NSUInteger preloadItemNumber;
@property (nonatomic, assign) CGFloat initialContentOffset;
@property (nonatomic, assign) BOOL manualScroll;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL showScrollIndicator;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong, readonly) RCTBaseListViewDataSource *dataSource;
@property (nonatomic, assign) NSTimeInterval scrollEventThrottle;
- (void)reloadData;
- (Class)listViewCellClass;
- (instancetype)initWithBridge:(RCTBridge *)bridge;
- (void)scrollToContentOffset:(CGPoint)point animated:(BOOL)animated;
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;
@end
