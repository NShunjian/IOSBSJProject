//
//  SUPRequestBaseViewController.m
//  SuperProject
//
//  Created by NShunJian on 2018/1/20.
//  Copyright © 2018年 superMan. All rights reserved.
//

#import "SUPRequestBaseViewController.h"

@interface SUPRequestBaseViewController ()

/** <#digest#> */
@property (nonatomic, strong) Reachability *reachHost;

@end

@implementation SUPRequestBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self reachHost];
}


#pragma mark - 加载框
- (void)showLoading
{
//    [MBProgressHUD showLoadToView:self.view];
    
    [MBProgressHUD showProgressToView:self.view Text:@"加载中..."];
}

- (void)dismissLoading
{
    [MBProgressHUD hideHUDForView:self.view];
}


#define kURL_Reachability__Address @"www.baidu.com"
#pragma mark - 监听网络状态
- (Reachability *)reachHost
{
    if(_reachHost == nil)
    {
        _reachHost = [Reachability reachabilityWithHostName:kURL_Reachability__Address];
        
        SUPWeakSelf(self);
        [_reachHost setUnreachableBlock:^(Reachability * reachability){
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakself networkStatus:reachability.currentReachabilityStatus inViewController:weakself];
                
            });
            
        }];
        
        
        [_reachHost setReachableBlock:^(Reachability * reachability){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakself networkStatus:reachability.currentReachabilityStatus inViewController:weakself];
                
            });
            
        }];
        
        [_reachHost startNotifier];
        
    }
    return _reachHost;
}


#pragma mark - SUPRequestBaseViewControllerDelegate
- (void)networkStatus:(NetworkStatus)networkStatus inViewController:(SUPRequestBaseViewController *)inViewController
{
    //判断网络状态
    switch (networkStatus) {
        case NotReachable:
            [MBProgressHUD showError:@"当前网络连接失败，请查看设置" ToView:self.view];
            break;
        case ReachableViaWiFi:
            NSLog(@"wifi上网2");
            break;
        case ReachableViaWWAN:
            NSLog(@"手机上网2");
            break;
        default:
            break;
    }
    
}


- (void)dealloc
{
    if ([self isViewLoaded]) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
    }
    [_reachHost stopNotifier];
    _reachHost = nil;
}

@end
