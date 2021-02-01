//
//  RCTVirtualTextNode.h
//  RCTText
//
//  Created by pennyli on 2017/10/10.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RCTVirtualNode.h"

@interface RCTVirtualTextNode : RCTVirtualNode
@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, assign) CGRect textFrame;
@property (nonatomic, copy) NSDictionary *extraInfo;
@property (nonatomic, strong) UIColor *textColor;
@end
