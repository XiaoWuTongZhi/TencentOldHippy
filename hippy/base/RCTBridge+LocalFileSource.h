//
//  RCTBridge+LocalFileSource.h
//  Hippy
//
//  Created by mengyanluo on 2018/9/25.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTBridge.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const RCTLocalFileReadErrorDomain;
extern NSInteger RCTLocalFileNOFilExist;

@interface RCTBridge (LocalFileSource)

@property (nonatomic, copy) NSString *workFolder;

+ (BOOL) isRCTLocalFileURLString:(NSString *)string;

- (NSString *)absoluteStringFromRCTLocalFileURLString:(NSString *)string;
@end

NS_ASSUME_NONNULL_END
