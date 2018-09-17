//
//  SUPRequestBaseViewController.h
//  SuperProject
//
//  Created by NShunJian on 2018/1/20.
//  Copyright © 2018年 superMan. All rights reserved.
//

#import "SUPTextViewController.h"
#import <Reachability.h>

@class SUPRequestBaseViewController;
@protocol SUPRequestBaseViewControllerDelegate <NSObject>

@optional
#pragma mark - 网络监听
/*
 NotReachable = 0,
 ReachableViaWiFi = 2,
 ReachableViaWWAN = 1,
 ReachableVia2G = 3,
 ReachableVia3G = 4,
 ReachableVia4G = 5,
 */
- (void)networkStatus:(NetworkStatus)networkStatus inViewController:(SUPRequestBaseViewController *)inViewController;

@end



@interface SUPRequestBaseViewController : SUPTextViewController<SUPRequestBaseViewControllerDelegate>

#pragma mark - 加载框
- (void)showLoading;

- (void)dismissLoading;

@end
