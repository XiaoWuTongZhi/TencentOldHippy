//
//  TestModule.m
//  React
//
//  Created by mengyanluo on 2018/6/20.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TestModule.h"
#import "RCTRootView.h"
#import "AppDelegate.h"
#import "QRCodeScanViewController.h"
#import "BundleRenderViewController.h"

@implementation TestModule

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
	return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(debug:(nonnull NSNumber *)instanceId)
{
	AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	UINavigationController *nav = (UINavigationController *)delegate.window.rootViewController;
	UIViewController *vc = [[UIViewController alloc] init];
	BOOL isSimulator = NO;
#if TARGET_IPHONE_SIMULATOR
	isSimulator = YES;
#endif
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:nil businessURL:nil moduleName:@"Demo" initialProperties:@{@"isSimulator": @(isSimulator)} launchOptions:nil shareOptions:nil debugMode:YES delegate:nil];
	rootView.backgroundColor = [UIColor whiteColor];
	rootView.frame = vc.view.bounds;
	[vc.view addSubview:rootView];
	[nav pushViewController: vc animated: YES];
}

RCT_EXPORT_METHOD(scan:(nonnull NSNumber *)instanceId)
{
	AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	UINavigationController *nav = (UINavigationController *)delegate.window.rootViewController;
	QRCodeScanViewController *vc = [[QRCodeScanViewController alloc] initWithScanCompletedBlock:^(NSString *result) {
		BundleRenderViewController *bundleVC = [[BundleRenderViewController alloc] initWithBundleUrl: result];
		[nav pushViewController: bundleVC animated: YES];
	}];
	
	UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController: vc];
	[nav presentViewController: nvc animated: YES completion: NULL];
}

@end
