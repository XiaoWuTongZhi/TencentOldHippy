//
//  RCTBaseListViewProtocol.h
//  QBCommonRNLib
//
//  Created by pennyli on 2018/4/16.
//  Copyright © 2018年 刘海波. All rights reserved.
//

#ifndef RCTBaseListViewProtocol_h
#define RCTBaseListViewProtocol_h

#import "RCTVirtualNode.h"

@protocol RCTBaseListViewProtocol <NSObject>

- (BOOL)flush;

@property (nonatomic, strong) RCTVirtualList *node;

@end


#endif /* RCTBaseListViewProtocol_h */
