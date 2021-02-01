//
//  BundleManager.m
//  demo
//
//  Created by pennyli on 2018/6/20.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "BundleManager.h"
#import "SSZipArchive.h"
#import "RCTUtils.h"
NSString * const BUNDLE_UPDATE_URL = @"http://qbrnweb.html5.qq.com/config.json";
NSString * const BUNDLE_VERSION = @"BUNDLE_VERSION";

@interface BundleManager()
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, strong) NSString *bundlePath;
@end

@implementation BundleManager {
	NSInteger _version;
	NSString *_bundlePath;
}

+ (instancetype)sharedInstance
{
	static BundleManager *shared_manager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared_manager = [[BundleManager alloc] init];
	});
	return shared_manager;
}

- (instancetype)init
{
	if (self = [super init]) {
		// first launch
		if (![[NSUserDefaults standardUserDefaults] objectForKey: BUNDLE_VERSION]) {
			[[NSUserDefaults standardUserDefaults] setObject: @(0) forKey: BUNDLE_VERSION];
			NSString *bundle_path = [[NSBundle mainBundle] pathForResource: @"hippy-expo" ofType: @"zip"];
			NSURL *defaultBundleURL = [NSURL fileURLWithPath: bundle_path];
			NSString *bundleZipPath = [self _bundleZipPath: 0];
			NSError *error = nil;
			[[NSFileManager defaultManager] copyItemAtURL: defaultBundleURL toURL: [NSURL fileURLWithPath: bundleZipPath] error: &error];
			if (!error) {
				NSString *destUnzipPath = [self _bundleUnzipPath: _version];
				if([SSZipArchive unzipFileAtPath: bundleZipPath toDestination: destUnzipPath]) {
					self.version = 0;
					self.bundlePath = [destUnzipPath stringByAppendingPathComponent: @"index.ios.jsbundle"];
				}
			} else {
				[self _handError: error];
			}
		} else {
			self.version = [[[NSUserDefaults standardUserDefaults] objectForKey: BUNDLE_VERSION] integerValue];
			self.bundlePath = [[self _bundleUnzipPath: self.version] stringByAppendingPathComponent: @"index.ios.jsbundle"];
		}
	}
	return self;
}

- (NSString *)bundlePath
{
	return _bundlePath;
}

- (void)checkAndUpdate
{
	NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL: [NSURL URLWithString: BUNDLE_UPDATE_URL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (error == nil) {
			if (data.length) {
				NSDictionary *config = [NSJSONSerialization JSONObjectWithData: data options: kNilOptions error: &error];
				if (!error) {
					[self _updateBundle: config];
				} else {
					[self _handError: error];
				}
			}
		} else {
			[self _handError: error];
		}
	}];
	[task resume];
}

- (void)_updateBundle:(NSDictionary *)config
{
	NSInteger version = [config[@"version"] integerValue];
	NSString *url = [config[@"url"] stringByRemovingPercentEncoding];
	
	if (version > _version) {
		__weak typeof(self) weakSelf = self;
        NSURL *requestURL = RCTURLWithString(url, NULL);
		NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:requestURL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			if (!error) {
				NSString *destZipPath = [self _bundleZipPath: version];
				if([[NSFileManager defaultManager] fileExistsAtPath: destZipPath isDirectory: nil]) {
					[[NSFileManager defaultManager] removeItemAtPath: destZipPath error: nil];
				}
				[[NSFileManager defaultManager] copyItemAtURL: location toURL: [NSURL fileURLWithPath: destZipPath] error: &error];
				if (!error) {
					NSString *destUnzipPath = [self _bundleUnzipPath: version];
					if([SSZipArchive unzipFileAtPath: destZipPath toDestination: destUnzipPath]) {
						weakSelf.version = version;
						weakSelf.bundlePath = destUnzipPath;
						[[NSUserDefaults standardUserDefaults] setObject: @(version) forKey: BUNDLE_VERSION];
						[[NSUserDefaults standardUserDefaults] synchronize];
					}
				} else {
					[self _handError: error];
				}
			} else {
				[self _handError: error];
			}
		}];
		
		[downloadTask resume];
	}
}

#pragma mark -

- (NSString *)_bundleFolderPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *cacheFolderPath = [paths firstObject];
	cacheFolderPath = [cacheFolderPath stringByAppendingPathComponent: @"bundle"];
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (![[NSFileManager defaultManager] fileExistsAtPath: cacheFolderPath]) {
			NSError *error = nil;
			[[NSFileManager defaultManager] createDirectoryAtPath: cacheFolderPath withIntermediateDirectories: YES attributes: nil error: &error];
			if (error) {
				[self _handError: error];
			}
		}
	});
	return cacheFolderPath;
}

- (NSString *)_bundleZipPath:(NSInteger)version
{
	return [[self _bundleFolderPath] stringByAppendingPathComponent: [NSString stringWithFormat: @"bundle_%@.zip", @(version)]];
}

- (NSString *)_bundleUnzipPath:(NSInteger)version
{
	return [[self _bundleFolderPath] stringByAppendingPathComponent: [NSString stringWithFormat: @"bundle_%@", @(version)]];
}

- (void)_handError:(NSError *)error
{
}

@end
