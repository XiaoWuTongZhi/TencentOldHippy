//
//  Created by rainywan
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RCTNavigatorDirection) {
    RCTNavigatorDirectionTypeRight = 0,
    RCTNavigatorDirectionTypeLeft,
    RCTNavigatorDirectionTypeTop,
    RCTNavigatorDirectionTypeBottom,
};

@interface RCTNavigationControllerAnimator : NSObject <UIViewControllerAnimatedTransitioning>

+ (NSObject <UIViewControllerAnimatedTransitioning> *)animatorWithAction:(UINavigationControllerOperation)action diretion:(RCTNavigatorDirection)direction;
@end
