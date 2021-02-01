//
//  ViewController.m
//  demo
//
//  Created by pennyli on 2018/6/12.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "RCTRootView.h"
#import "BundleManager.h"

@interface ViewController () {
}
@property (nonatomic, strong) RCTRootView *rootView;
@property (nonatomic, assign) NSUInteger ns_index;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib
    NSString *commonBundlePath = [[NSBundle mainBundle] pathForResource: @"common.ios" ofType: @"jsbundle"];
    BOOL isSimulator = NO;
#if TARGET_IPHONE_SIMULATOR
    isSimulator = YES;
#endif
    
    if (isSimulator == YES) {
//        return;
    }

    RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL: [NSURL URLWithString: commonBundlePath] moduleProvider: nil launchOptions: nil executorKey:nil];

    self.rootView = [[RCTRootView alloc] initWithBridge: bridge
                                            businessURL: [NSURL fileURLWithPath: [BundleManager sharedInstance].bundlePath]
                                             moduleName: @"Demo"
                                      initialProperties: @{@"isSimulator": @(isSimulator)}
                                          launchOptions:nil
                                           shareOptions: nil
                                            debugMode: NO
                                               delegate: nil];

    self.rootView.backgroundColor = [UIColor whiteColor];
    self.rootView.frame = self.view.bounds;
    self.rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview: self.rootView];
}

@end
