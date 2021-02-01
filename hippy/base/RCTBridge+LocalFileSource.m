//
//  RCTBridge+LocalFileSource.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/25.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RCTBridge+LocalFileSource.h"
#import "objc/runtime.h"
static const void *RCTWorkerFolderKey = &RCTWorkerFolderKey;
NSErrorDomain const RCTLocalFileReadErrorDomain = @"RCTLocalFileReadErrorDomain";
NSInteger RCTLocalFileNOFilExist = 100;
@implementation RCTBridge (LocalFileSource)
- (void) setWorkFolder:(NSString *)workFolder {
    objc_setAssociatedObject(self, RCTWorkerFolderKey, workFolder, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *) workFolder {
    NSString *string = objc_getAssociatedObject(self, RCTWorkerFolderKey);
    return string;
}

+ (NSString *) defaultRCTLocalFileScheme {
    //hpfile://
    static dispatch_once_t onceToken;
    static NSString *defaultScheme = nil;
    static NSString *pFile = @"pfile";
    dispatch_once(&onceToken, ^{
        defaultScheme = [[@"h" stringByAppendingString:pFile] stringByAppendingString:@"://"];
    });
    return defaultScheme;
}

+ (BOOL) isRCTLocalFileURLString:(NSString *)string {
    return [string hasPrefix:[RCTBridge defaultRCTLocalFileScheme]];
}

- (NSString *)absoluteStringFromRCTLocalFileURLString:(NSString *)string {
    if ([RCTBridge isRCTLocalFileURLString:string]) {
        NSString *filePrefix = [RCTBridge defaultRCTLocalFileScheme];
        NSString *relativeString = string;
        if ([string hasPrefix:filePrefix]) {
            NSRange range = NSMakeRange(0, [filePrefix length]);
            relativeString = [string stringByReplacingOccurrencesOfString:filePrefix withString:@"" options:0 range:range];
        }
        NSURL *workURL = [NSURL URLWithString:self.workFolder];
        NSURL *localFileURL = [NSURL URLWithString:relativeString relativeToURL:workURL];
        if ([localFileURL isFileURL]) {
            return [localFileURL path];
        }
    }
    return nil;
}
@end
