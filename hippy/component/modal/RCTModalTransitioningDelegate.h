//
//  RCTModalTransitioningDelegate.h
//  hippy
//
//  Created by 万致远 on 2019/11/26.
//

#import <UIKit/UIKit.h>
#import "RCTModalHostViewInteractor.h"
@class RCTModalHostView;
@class RCTModalHostViewController;

@protocol RCTModalHostViewInteractor;
typedef void (^RCTModalViewInteractionBlock)(UIViewController *reactViewController, UIViewController *viewController, BOOL animated, dispatch_block_t completionBlock);


@interface RCTModalTransitioningDelegate : NSObject<RCTModalHostViewInteractor, UIViewControllerTransitioningDelegate>
/**
 * `presentationBlock` and `dismissalBlock` allow you to control how a Modal interacts with your case,
 * e.g. in case you have a native navigator that has its own way to display a modal.
 * If these are not specified, it falls back to the UIViewController standard way of presenting.
 */
@property (nonatomic, strong) RCTModalViewInteractionBlock presentationBlock;
@property (nonatomic, strong) RCTModalViewInteractionBlock dismissalBlock;
- (void)presentModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;
- (void)dismissModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;

@end


