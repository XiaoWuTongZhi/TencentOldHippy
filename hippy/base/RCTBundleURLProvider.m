//
//  RCTBundleURLProvider.m
//  QQKSong
//
//  Created by Yu Abigale on 2018/11/11.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "RCTBundleURLProvider.h"

@interface RCTBundleURLProvider ()

@property (nonatomic, copy) NSString *localhostIP;
@property (nonatomic, copy) NSString *localhostPort;
@property (nonatomic, copy) NSString *debugPathUrl;

@end

@implementation RCTBundleURLProvider

#pragma mark - Life cycle

+ (instancetype)sharedInstance {
    static RCTBundleURLProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RCTBundleURLProvider alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _localhostIP = @"localhost";
        _localhostPort = @"38989";
        _debugPathUrl = @"/index.bundle?platform=ios&dev=true&minify=false";
    }
    return self;
}

#pragma mark - Public

- (void)setLocalhostIP:(NSString *)localhostIP localhostPort:(NSString *)localhostPort {
    if (localhostIP) {
        _localhostIP = localhostIP;
    }
    if (localhostPort) {
        _localhostPort = localhostPort;
    }
}

- (void)setDebugPathUrl:(NSString *)debugPathUrl{
    if (debugPathUrl) {
        _debugPathUrl = debugPathUrl;
    }
}

- (NSString *)localhost {
    return [NSString stringWithFormat:@"%@:%@", _localhostIP, _localhostPort];
}


@end
