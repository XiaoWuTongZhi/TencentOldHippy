//
//  RCTWebView.h
//  Hippy
//
//  Created by 万致远 on 2019/3/30.
//  Copyright © 2019 Tencent. All rights reserved.
//


#import <WebKit/WebKit.h>
#import "RCTComponent.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCTSimpleWebView : WKWebView<WKUIDelegate, WKNavigationDelegate>
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *source;
@property (nonatomic, copy) RCTDirectEventBlock onLoadStart;
@property (nonatomic, copy) RCTDirectEventBlock onLoadEnd;
@property (nonatomic, copy) RCTDirectEventBlock onLoad;

@end

NS_ASSUME_NONNULL_END
