//
//  SUPEasyBlankPageView.h
//  SuperProject
//
//  Created by NShunJian on 2018/1/20.
//  Copyright © 2018年 superMan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    SUPEasyBlankPageViewTypeNoData
} SUPEasyBlankPageViewType;

@interface SUPEasyBlankPageView : UIView

- (void)configWithType:(SUPEasyBlankPageViewType)blankPageType hasData:(BOOL)hasData hasError:(BOOL)hasError reloadButtonBlock:(void(^)(UIButton *sender))block;

@end
@interface UIView (SUPConfigBlank)
- (void)configBlankPage:(SUPEasyBlankPageViewType)blankPageType hasData:(BOOL)hasData hasError:(BOOL)hasError reloadButtonBlock:(void(^)(id sender))block;
@end
