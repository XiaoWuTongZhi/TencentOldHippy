//
//  Created by rainywan
//
#import "RCTNavigationControllerAnimator.h"

const NSTimeInterval kTrainsitionDurationDefault = 0.4;

const CGPoint leftPageOrigin = {-1, 0};
const CGPoint rightPageOrigin = {1, 0};
const CGPoint topPageOrigin = {0, -1};
const CGPoint bottomPageOrigin = {0, 1};

@interface RCTNavigationControllerAnimator()
@property (assign, nonatomic) RCTNavigatorDirection direction;
@property (assign, nonatomic) UINavigationControllerOperation action;

@end

@implementation RCTNavigationControllerAnimator

+ (NSObject <UIViewControllerAnimatedTransitioning> *)animatorWithAction:(UINavigationControllerOperation)action diretion:(RCTNavigatorDirection)direction {
    if (action == UINavigationControllerOperationNone) {
        return nil;
    }
    RCTNavigationControllerAnimator *animator = [RCTNavigationControllerAnimator new];
    animator.action = action;
    animator.direction = direction;
    return animator;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kTrainsitionDurationDefault;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if (self.action == UINavigationControllerOperationPush) {
        [[transitionContext containerView] addSubview:fromViewController.view];
        [[transitionContext containerView] addSubview:toViewController.view];
        
        toViewController.view.frame = [self pageFrameWithDirection:self.direction];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else if (self.action == UINavigationControllerOperationPop) {
        [[transitionContext containerView] addSubview:toViewController.view];
        [[transitionContext containerView] addSubview:fromViewController.view];
        
        fromViewController.view.frame = [UIScreen mainScreen].bounds;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.frame = [self pageFrameWithDirection:self.direction];;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (CGRect)pageFrameWithDirection:(RCTNavigatorDirection)direction {
    CGPoint pageOrigin = CGPointZero;
    switch (direction) {
        case RCTNavigatorDirectionTypeLeft:
            pageOrigin.x = leftPageOrigin.x;
            pageOrigin.y = leftPageOrigin.y;
            break;
        case RCTNavigatorDirectionTypeTop:
            pageOrigin.x = topPageOrigin.x;
            pageOrigin.y = topPageOrigin.y;
            break;
        case RCTNavigatorDirectionTypeBottom:
            pageOrigin.x = bottomPageOrigin.x;
            pageOrigin.y = bottomPageOrigin.y;
            break;
        case RCTNavigatorDirectionTypeRight:
        default:
            pageOrigin.x = rightPageOrigin.x;
            pageOrigin.y = rightPageOrigin.y;
            break;
            
            
    }
    CGRect kScreen = [UIScreen mainScreen].bounds;
    CGFloat kScreenWidth = kScreen.size.width;
    CGFloat kScreenHeight = kScreen.size.height;
    pageOrigin.x *= kScreenWidth;
    pageOrigin.y *= kScreenHeight;
    CGRect pageFrame = {pageOrigin, kScreen.size};
    return pageFrame;
    
}

@end
