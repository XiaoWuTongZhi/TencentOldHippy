//
//  RCTModalTransitioningDelegate.m
//  hippy
//
//  Created by 万致远 on 2019/11/26.
//

#import "RCTModalTransitioningDelegate.h"
#import "RCTModalCustomPresentationController.h"
#import "RCTModalCustomAnimationTransition.h"

#import "UIView+React.h"
#import "RCTModalHostViewManager.h"
#import "RCTModalHostView.h"

@implementation RCTModalTransitioningDelegate

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(__unused UIViewController *)presenting sourceViewController:(__unused UIViewController *)source NS_AVAILABLE_IOS(8_0)
{
    RCTModalCustomPresentationController *controller = [[RCTModalCustomPresentationController alloc] initWithPresentedViewController: presented presentingViewController: presenting];
    return controller;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(__unused UIViewController *)presented presentingController:(__unused UIViewController *)presenting sourceController:(__unused UIViewController *)source
{
    RCTModalCustomAnimationTransition *transition = [RCTModalCustomAnimationTransition new];
    transition.isPresent = YES;
    return transition;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(__unused UIViewController *)dismissed
{
    RCTModalCustomAnimationTransition *transition = [RCTModalCustomAnimationTransition new];
    transition.isPresent = NO;
    return transition;
}

- (void)presentModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated
{
  dispatch_block_t completionBlock = ^{
    if (modalHostView.onShow) {
      modalHostView.onShow(nil);
    }
  };
  if (_presentationBlock) {
    _presentationBlock([modalHostView reactViewController], viewController, animated, completionBlock);
  } else {
    if ([modalHostView.hideStatusBar boolValue]) {
      viewController.modalPresentationCapturesStatusBarAppearance = YES;
      viewController.hideStatusBar = [modalHostView hideStatusBar];
    }
    [[modalHostView reactViewController] presentViewController:viewController animated:animated completion:completionBlock];
  }
}

- (void)dismissModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated
{
    dispatch_block_t completionBlock = ^{
        NSDictionary *userInfo = nil;
        if (modalHostView.primaryKey.length != 0)
        {
          userInfo = @{@"primaryKey" : modalHostView.primaryKey};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:RCTModalHostViewDismissNotification object:self userInfo:userInfo];
        if (modalHostView.onRequestClose) {
            modalHostView.onRequestClose(nil);
        }
    };
    
  if (_dismissalBlock) {
    _dismissalBlock([modalHostView reactViewController], viewController, animated, nil);
  } else {
    [viewController dismissViewControllerAnimated:animated completion:completionBlock];
  }
}

@end
