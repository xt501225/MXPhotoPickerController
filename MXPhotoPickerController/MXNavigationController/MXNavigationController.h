//
//  MXNavigationController.h
//  MXNavigationController
//
//  Created by 韦纯航 on 15/11/18.
//  Copyright © 2015年 韦纯航. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  设定导航栏背景颜色
 *  可根据实际需要修改
 */
#define NAV_TINT_COLOR [UIColor colorWithRed:0 green:175/255.0 blue:240/255.0 alpha:1.0]

/**
 *  设定导航栏标题文字颜色
 *  可根据实际需要修改
 */
#define NAV_TITLE_COLOR [UIColor whiteColor]

/**
 *  设定导航栏标题文字字体
 *  可根据实际需要修改字体样式和字体大小
 */
#define NAV_TITLE_FONT [UIFont boldSystemFontOfSize:19.0]

@interface UINavigationBar (MXNavigationBar)

/**
 *  动态改变导航栏背景颜色
 *
 *  @param backgroundColor 背景颜色
 */
- (void)mx_setBackgroundColor:(UIColor *)backgroundColor;

/**
 *  重置到初始状态
 */
- (void)mx_reset;

@end


@interface MXNavigationController : UINavigationController

/**
 *  控制全屏pop手势是否可用（为YES时可用）
 */
@property (assign, readwrite, nonatomic) BOOL interactivePopGestureRecognizerEnabled;

@end
