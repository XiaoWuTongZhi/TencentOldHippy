//
//  RCTNavigatorHostView.m
//  Hippy
//
//  Created by mengyanluo on 2018/9/28.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "RCTNavigatorHostView.h"
#import "RCTNavigationControllerAnimator.h"
#import "RCTRootView.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "UIView+React.h"
#import "RCTNavigatorItemViewController.h"
#import "RCTNavigatorRootViewController.h"
#import "RCTAssert.h"

@interface RCTNavigatorHostView() {
    NSDictionary *_initProps;
    NSString *_appName;
    RCTBridge *_bridge;
    RCTNavigatorRootViewController *_navigatorRootViewController;
    BOOL _isPresented;
}
@property (nonatomic, assign) RCTNavigatorDirection nowDirection;
@end

@implementation RCTNavigatorHostView
- (instancetype) initWithBridge:(RCTBridge *)bridge props:(nonnull NSDictionary *)props{
    self = [super init];
    if (self) {
        _initProps = props[@"initialRoute"][@"initProps"];
        _appName = props[@"initialRoute"][@"routeName"];
        _bridge = bridge;
        _isPresented = NO;
        _nowDirection = RCTNavigatorDirectionTypeRight;
    }
    return self;
}

- (void) didMoveToWindow {
    [self presentRootView];
}

- (RCTRootView *)createRootViewForModuleName:(NSString *)moduleName initProperties:(NSDictionary *)props {
    RCTBridge *tempBridge = _bridge;
    if ([tempBridge isKindOfClass:[RCTBatchedBridge class]]) {
        tempBridge = [(RCTBatchedBridge *)tempBridge parentBridge];
    }
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:tempBridge moduleName:moduleName initialProperties:props shareOptions:@{} delegate:nil];
    rootView.backgroundColor = [UIColor whiteColor];
    [rootView bundleFinishedLoading:tempBridge];
    return rootView;
}

- (void) presentRootView {
    if (!_isPresented && self.window) {
        _isPresented = YES;
        RCTRootView *rootView = [self createRootViewForModuleName:_appName initProperties:_initProps];
        RCTNavigatorItemViewController *itemViewController = [[RCTNavigatorItemViewController alloc] initWithView:rootView];
        UIViewController *presentingViewController = [self reactViewController];
        RCTAssert(presentingViewController, @"no presenting view controller for navigator module");
        _navigatorRootViewController = [[RCTNavigatorRootViewController alloc] initWithRootViewController:itemViewController];
        _navigatorRootViewController.navigationBar.hidden = YES;
        _navigatorRootViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _navigatorRootViewController.delegate = self;
        [presentingViewController presentViewController:_navigatorRootViewController animated:YES completion:^{
            
        }];
    }
}

- (void) insertReactSubview:(UIView *)subview atIndex:(NSInteger)atIndex {
    [super insertReactSubview:subview atIndex:0];
}

- (void) push:(NSDictionary *)params {
    BOOL animated = [params[@"animated"] boolValue];
    NSString *appName = params[@"routeName"];
    NSDictionary *initProps = params[@"initProps"];
    NSString *direction = params[@"fromDirection"];
    self.nowDirection = [self findDirection:direction];
    
    RCTRootView *rootView = [self createRootViewForModuleName:appName initProperties:initProps];
    RCTNavigatorItemViewController *itemViewController = [[RCTNavigatorItemViewController alloc] initWithView:rootView];
    [_navigatorRootViewController pushViewController:itemViewController animated:animated];
    
}

- (void) pop:(NSDictionary *)params {
    BOOL animated = [params[@"animated"] boolValue];
    NSString *direction = params[@"toDirection"];
    self.nowDirection = [self findDirection:direction];
    
    [_navigatorRootViewController popViewControllerAnimated:animated];
}

- (RCTNavigatorDirection)findDirection:(NSString *)directionString {
    //默认方向
    if (!directionString || [directionString isEqualToString:@""]) {
        return RCTNavigatorDirectionTypeRight;
    }
    RCTNavigatorDirection result = RCTNavigatorDirectionTypeRight;
    if ([directionString isEqualToString:@"left"]) {
        result = RCTNavigatorDirectionTypeLeft;
    } else if ([directionString isEqualToString:@"bottom"]) {
        result = RCTNavigatorDirectionTypeBottom;
    } else if ([directionString isEqualToString:@"top"]) {
        result = RCTNavigatorDirectionTypeTop;
    } else if ([directionString isEqualToString:@"right"]) {
        result = RCTNavigatorDirectionTypeRight;
    }
    return result;
}

- (void) invalidate {
    if (_isPresented) {
        [_navigatorRootViewController dismissViewControllerAnimated:YES completion:NULL];
        _isPresented = NO;
    }
}


- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (self.nowDirection == RCTNavigatorDirectionTypeRight) {
        //用系统默认的
        return nil;
    }
    return [RCTNavigationControllerAnimator animatorWithAction:operation diretion:self.nowDirection];
}


- (void) dealloc {
    
}
@end
