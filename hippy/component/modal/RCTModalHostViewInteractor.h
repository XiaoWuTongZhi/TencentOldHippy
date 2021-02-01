//
//  RCTModalHostViewInteractor.h
//  hippy
//
//  Created by 万致远 on 2019/11/26.
//

#import <Foundation/Foundation.h>
#import "RCTModalHostView.h"
#import "RCTModalHostViewController.h"


@protocol RCTModalHostViewInteractor <NSObject>
- (void)presentModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;
- (void)dismissModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;

@end


