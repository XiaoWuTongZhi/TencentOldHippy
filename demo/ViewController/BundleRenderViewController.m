//
//  BundleRenderViewController.m
//  demo
//
//  Created by pennyli on 2018/7/31.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "BundleRenderViewController.h"
#import "RCTRootView.h"
#import "SSZipArchive.h"
#import "QBAddress.h"
#import "RCTUtils.h"
@interface BundleRenderViewController ()
@property (nonatomic, strong) QBAddress *qbAddress;
@end

@implementation BundleRenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
	[self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (instancetype)initWithBundleUrl:(NSString *)url
{
	if (self = [super initWithNibName: nil bundle: nil]) {
		self.qbAddress = [QBAddress qbWithString: url];
	}
	return self;
}

- (void)setup
{
	NSString *prefix = [self.qbAddress getPrefix];
	if (![prefix isEqualToString: @"hippy://bundle"]) {
		return;
	}
	
	NSString *url = [self.qbAddress getParaForKey: @"url"];
	NSString *component = [self.qbAddress getParaForKey: @"component"];
	NSString *module = [self.qbAddress getParaForKey: @"module"];
	
	
	if (!(url.length && component.length)) {
		return;
	}
    NSURL *requestURL = RCTURLWithString(url, NULL);
	NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:requestURL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (!error) {
			NSString *folder = [NSTemporaryDirectory() stringByAppendingPathComponent: @"hippy_zip"];
			NSString *unZipPath = [folder stringByAppendingPathComponent: module];
			if (![[NSFileManager defaultManager] fileExistsAtPath: unZipPath]) {
				[[NSFileManager defaultManager] createDirectoryAtPath: unZipPath withIntermediateDirectories: YES attributes: nil error: nil];
			}
			if([SSZipArchive unzipFileAtPath: [location path] toDestination: unZipPath]) {
				NSURL *bundleURL = [NSURL fileURLWithPath:[unZipPath stringByAppendingPathComponent: @"index.ios.jsbundle"]];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self createRootView: component module: module bundlePath: bundleURL];
				});
			}
		}
	}];
	
	[task resume];
}

- (void)createRootView:(NSString *)component module:(NSString *)module bundlePath:(NSURL *)bundleURL
{
	NSString *commonBundlePath = [[NSBundle mainBundle] pathForResource: @"common.ios" ofType: @"jsbundle"];
	RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL: [NSURL fileURLWithPath: commonBundlePath] moduleProvider: nil launchOptions: nil executorKey:nil];
	BOOL isSimulator = NO;
#if TARGET_IPHONE_SIMULATOR
	isSimulator = YES;
#endif
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge: bridge
                                                    businessURL: bundleURL
                                                     moduleName: component
                                              initialProperties: @{@"isSimulator": @(isSimulator)}
                                                  launchOptions: nil
                                                   shareOptions: nil
                                                      debugMode: YES
                                                       delegate: nil];
	rootView.backgroundColor = [UIColor whiteColor];
	rootView.frame = self.view.bounds;
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview: rootView];
}

@end
