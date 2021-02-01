//
//  RCTBaseListViewDataSource.h
//  QBCommonRNLib
//
//  Created by pennyli on 2018/4/16.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTVirtualNode.h"

@interface RCTBaseListViewDataSource : NSObject

- (void)setDataSource:(NSArray <RCTVirtualCell *> *)dataSource;
- (RCTVirtualCell *)cellForIndexPath:(NSIndexPath *)indexPath;
- (RCTVirtualCell *)headerForSection:(NSInteger)section;
- (NSInteger)numberOfSection;
- (NSInteger)numberOfCellForSection:(NSInteger)section;
- (NSIndexPath *)indexPathOfCell:(RCTVirtualCell *)cell;
- (NSIndexPath *)indexPathForFlatIndex:(NSInteger)index;

@end
