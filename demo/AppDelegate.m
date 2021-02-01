//
//  AppDelegate.m
//  demo
//
//  Created by pennyli on 2018/6/12.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "BundleManager.h"
#import "RCTBundleURLProvider.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
//    [[BundleManager sharedInstance] checkAndUpdate];
	
	ViewController *vc = [ViewController new];
	UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController: vc];
	[nvc.navigationBar setHidden: YES];
	[self.window setRootViewController: nvc];
    
    //使用真机调试
//    [self useRealMachine];
    
	return YES;
}

//真机调试相关
- (void)useRealMachine {
    //localhostIP为主机局域网地址，localhostPort为拉jsBundle的端口，默认8082
    NSString *localHostIP = @"192.168.43.198"; //填写主机（mac）的实际IP（终端与主机在同一局域网下，终端需要能ping通主机，）
    NSString *port = @"38989";//默认端口为8082
    [[RCTBundleURLProvider sharedInstance] setLocalhostIP:localHostIP localhostPort:port];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
