//
//  LSJMainTabbarController.m
//  LSJTelLive
//
//  Created by 李思俊 on 16/10/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "LSJMainTabbarController.h"


@interface LSJMainTabbarController ()

@end

@implementation LSJMainTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* -----------  tabBar背景图片  -----------*/
    self.tabBar.backgroundImage = [UIImage imageNamed:@"tabBar"];
    /* -----------  tabBar渲染颜色  -----------*/
    self.tabBar.tintColor = LSJMainColor;
    /* -----------  添加子模块  -----------*/
    [self addChildControllers];
    
}

#pragma mark - 添加子模块
-(void)addChildControllers{
    /* -----------  接收广播  -----------*/
    LSJNavBaseController *centralNav = [self viewControllerWithViewName:@"LSJCentralViewController"];
    /* -----------  发送广播  -----------*/
    LSJNavBaseController *perNav = [self viewControllerWithViewName:@"LSJPeripheralViewController"];
    
    /* -----------  添加子模块数组  -----------*/
    self.viewControllers = @[centralNav,perNav];
}

#pragma mark - 新建子模块,同时添加选择图片
-(LSJNavBaseController *)viewControllerWithViewName:(NSString *)viewName{
    /* -----------  创建viewController  -----------*/
    LSJBaseViewController *baseView = [[NSClassFromString(viewName) alloc]init];
    
    /* -----------  分别添加各子模块的选择图标和名称  -----------*/
    if ([viewName isEqualToString:@"LSJPeripheralViewController"]) {
        baseView.navigationItem.title = @"Peripheral";
        baseView.tabBarItem.title = @"Peripheral";
        baseView.tabBarItem.image = [UIImage imageNamed:@"icon_tabbar_me"];
    }else{
        baseView.navigationItem.title = @"Central";
        baseView.tabBarItem.title = @"Central";
        baseView.tabBarItem.image = [UIImage imageNamed:@"icon_tabbar_home"];
        
    }
    
    return [[LSJNavBaseController alloc]initWithRootViewController:baseView];
}

@end
