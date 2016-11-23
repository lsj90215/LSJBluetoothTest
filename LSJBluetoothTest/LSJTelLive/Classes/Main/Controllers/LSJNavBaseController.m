//
//  LSJNavBaseController.m
//  LSJTelLive
//
//  Created by 李思俊 on 16/10/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "LSJNavBaseController.h"

@interface LSJNavBaseController ()

@end

@implementation LSJNavBaseController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* -----------  nav背景图片  -----------*/
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav"] forBarMetrics:UIBarMetricsDefault];
    
    /* -----------  nav字体颜色  -----------*/
    [self.navigationBar setTitleTextAttributes:@{
                                                 NSForegroundColorAttributeName : [UIColor whiteColor]
                                                 }];
    
    /* -----------  nav渲染颜色  -----------*/
    self.navigationBar.tintColor = [UIColor whiteColor];
}

#pragma mark - 更改电池颜色
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


@end
