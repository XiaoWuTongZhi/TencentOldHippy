//
//  RCTWebView.m
//  Hippy
//
//  Created by 万致远 on 2019/3/30.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RCTSimpleWebView.h"
#import "RCTAssert.h"
#import "RCTUtils.h"

@implementation RCTSimpleWebView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.UIDelegate = self;
        self.navigationDelegate = self;
    }
    return self;
}

- (void)setSource:(NSDictionary *)source {
    _source = source;
    if (source && [source[@"uri"] isKindOfClass:[NSString class]]) {
        NSString *urlString = source[@"uri"];
        [self loadUrl:urlString];
    }
}

- (void)loadUrl:(NSString *)urlString  {
    _url = urlString;
    NSURL *url = RCTURLWithString(urlString, NULL);
    if (!url) {
        RCTFatal(RCTErrorWithMessage(@"Error in [RCTWebview setUrl]: illegal url"));
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self loadRequest:request];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (_onLoadStart) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
        NSString *url = [[webView URL] absoluteString];
        if (url) {
            [dic setObject:url forKey:@"url"];
        }
        _onLoadStart(dic);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:2];
    NSString *url = [[webView URL] absoluteString];
    if (url) {
        [dic setObject:url forKey:@"url"];
    }
    if (_onLoad) {
        _onLoad(dic);
    }
    if (_onLoadEnd) {
        [dic setObject:@(YES) forKey:@"success"];
        _onLoadEnd(dic);
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (_onLoadEnd) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:3];
        NSString *url = [[webView URL] absoluteString];
        NSString *errString = [error localizedFailureReason];
        if (url) {
            [dic setObject:url forKey:@"url"];
        }
        if (errString) {
            [dic setObject:errString forKey:@"error"];
        }
        [dic setObject:@(NO) forKey:@"success"];
        _onLoadEnd(dic);
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (_onLoadEnd) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:3];
        NSString *url = [[webView URL] absoluteString];
        NSString *errString = [error localizedFailureReason];
        if (url) {
            [dic setObject:url forKey:@"url"];
        }
        if (errString) {
            [dic setObject:errString forKey:@"error"];
        }
        [dic setObject:@(NO) forKey:@"success"];
        _onLoadEnd(dic);
    }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    [webView loadRequest:navigationAction.request];
    return nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
