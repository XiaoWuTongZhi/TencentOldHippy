//
//  QRCodeScanViewController.h
//  demo
//
//  Created by pennyli on 2018/7/31.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRCodeScanViewController : UIViewController

- (instancetype)initWithScanCompletedBlock:(void (^)(NSString *))completedBlock;
@end
