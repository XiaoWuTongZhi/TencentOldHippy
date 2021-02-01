//
//  RCTClipboard.m
//  hippy
//
//  Created by 万致远 on 2019/5/30.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTClipboardModule.h"

@implementation RCTClipboardModule
RCT_EXPORT_MODULE(ClipboardModule)

RCT_EXPORT_METHOD(getString:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *paste = pasteboard.string == nil ? @"" : pasteboard.string;
    resolve(paste);
}

RCT_EXPORT_METHOD(setString:(NSString *)paste) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = paste;
}


@end
