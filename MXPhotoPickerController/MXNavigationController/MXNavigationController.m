//
//  MXNavigationController.m
//  MXNavigationController
//
//  Created by 韦纯航 on 15/11/18.
//  Copyright © 2015年 韦纯航. All rights reserved.
//

#import "MXNavigationController.h"
#import <objc/runtime.h>

@implementation UINavigationBar (MXNavigationBar)

static char OverlayViewKey;

- (UIView *)overlayView
{
    return objc_getAssociatedObject(self, &OverlayViewKey);
}

- (void)setOverlayView:(UIView *)overlayView
{
    objc_setAssociatedObject(self, &OverlayViewKey, overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 *  动态改变导航栏背景颜色
 *
 *  @param backgroundColor 背景颜色
 */
- (void)mx_setBackgroundColor:(UIColor *)backgroundColor
{
    if (!self.overlayView) {
        [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        
        CGRect overlayViewRect = [UIScreen mainScreen].bounds;
        overlayViewRect.origin.y = -20.0;
        overlayViewRect.size.height = CGRectGetHeight(self.bounds) + 20.0;
        
        self.overlayView = [[UIView alloc] initWithFrame:overlayViewRect];
        self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.overlayView.userInteractionEnabled = NO;
        [self insertSubview:self.overlayView atIndex:0];
    }
    
    [self.overlayView setBackgroundColor:backgroundColor];
}

/**
 *  重置到初始状态
 */
- (void)mx_reset
{
    [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.overlayView removeFromSuperview];
    [self setOverlayView:nil];
}

@end


@interface MXNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@end

@implementation MXNavigationController

#pragma mark - Initialize

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     *  设定导航栏背景颜色
     *  若设置了导航栏的背景图片，则设置背景颜色失效
     */
    if ([UINavigationBar instancesRespondToSelector:@selector(setBarTintColor:)]) {
        [self.navigationBar setBarTintColor:NAV_TINT_COLOR];
    }
    
    /**
     *  设定导航栏是否半透明
     *  如果值为YES，原点坐标为屏幕的左上角
     *  如果值为NO，原点坐标为导航栏左下角
     */
    if ([UINavigationBar instancesRespondToSelector:@selector(setTranslucent:)]) {
        [self.navigationBar setTranslucent:YES];
    }
    
    /**
     *  设定导航栏标题的文字属性
     *  @param NSForegroundColorAttributeName 文字颜色
     *  @param NSFontAttributeName 文字字体
     */
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    [titleTextAttributes setValue:NAV_TITLE_COLOR forKey:NSForegroundColorAttributeName];
    [titleTextAttributes setValue:NAV_TITLE_FONT forKey:NSFontAttributeName];
    [self.navigationBar setTitleTextAttributes:titleTextAttributes];
    
    /**
     *  将系统自带的导航栏返回手势禁用掉
     */
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        [self.interactivePopGestureRecognizer setEnabled:NO];
    }
    
    /**
     *  默认全屏pop手势可用
     */
    self.interactivePopGestureRecognizerEnabled = YES;
    
    /**
     *  获取到系统自带的导航栏返回手势所在view
     */
    UIView *targetView = self.interactivePopGestureRecognizer.view;
    
    /**
     *  获取系统自带的导航栏返回手势的target数组
     */
    NSMutableArray *_targets = [self.interactivePopGestureRecognizer valueForKey:@"_targets"];
    
    /**
     *  获取target数组的唯一对象，是一个叫UIGestureRecognizerTarget的私有类
     */
    id gestureRecognizerTarget = [_targets firstObject];
    
    /**
     *  target数组的唯一对象有一个属性叫_target，获取这个_target:_UINavigationInteractiveTransition
     */
    id navigationInteractiveTransition = [gestureRecognizerTarget valueForKey:@"_target"];
    
    /**
     *  这个_target:_UINavigationInteractiveTransition有一个方法名叫handleNavigationTransition:
     */
    SEL handleTransition = NSSelectorFromString(@"handleNavigationTransition:");
    
    /**
     *  初始化自定义全屏手势
     *  target设定为系统自带的导航栏返回手势的target
     *  响应方法设定为系统自带的导航栏返回手势的响应方法
     *  用自定义手势替换系统自带的导航栏返回手势
     */
    UIPanGestureRecognizer *interactivePopGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
    [interactivePopGestureRecognizer setDelegate:self];
    [interactivePopGestureRecognizer setMaximumNumberOfTouches:1];
    [interactivePopGestureRecognizer addTarget:navigationInteractiveTransition action:handleTransition];
    [targetView addGestureRecognizer:interactivePopGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIStatusBarStyle Adjust

/**
 *  状态栏设置
 *
 *  @return 返回导航栏的topViewController
 */
- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}

#pragma mark - Override Method

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.viewControllers && [self.viewControllers count]) {
        /**
         *  如果hidesBackButton值为NO，说明用户并没有自定义导航栏左边的按钮
         *  则新建一个自定义默认样式的返回按钮
         */
        if (!viewController.navigationItem.hidesBackButton) {
            UIImage *backImage = [UIImage imageNamed:@"nav_back_image.png"];
            UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [backButton setFrame:(CGRect){CGPointZero, backImage.size}];
            [backButton setImage:backImage forState:UIControlStateNormal];
            [backButton addTarget:self action:@selector(popViewControllerAnimated) forControlEvents:UIControlEventTouchUpInside];
            
            UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
            viewController.navigationItem.leftBarButtonItem = backBarButtonItem;
        }
    }
    
    [super pushViewController:viewController animated:animated];
}

- (void)popViewControllerAnimated
{
    [self popViewControllerAnimated:YES];
}

#pragma mark - UINavigationControllerDelegate

/**
 *  导航栏将要显示某个viewController时调用
 *
 *  @param navigationController 导航栏
 *  @param viewController       将要显示的viewController
 *  @param animated             是否启用动画
 */
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    /* 在这里可以加上自己的处理代码 */
}

/**
 *  导航栏完成显示某个viewController时调用
 *
 *  @param navigationController 导航栏
 *  @param viewController       将要显示的viewController
 *  @param animated             是否启用动画
 */
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    /* 在这里可以加上自己的处理代码 */
}

#pragma mark - UIGestureRecognizerDelegate

/**
 *  此代理方法为处理全屏pop手势是否可用的首调方法
 *  在此方法中可以根据touch中的view类型来设置手势是否可用
 *  比如：界面中触摸到了按钮，则禁止使用手势
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    /*
     UIView *touchView = [touch view];
     if ([touchView isKindOfClass:[UIButton class]]) {
         return NO;
     }
     */
    
    return self.interactivePopGestureRecognizerEnabled;
}

/**
 *  当方法gestureRecognizer:shouldReceiveTouch:返回的值为NO，此方法将不再被调用
 *  当此方法被调用时，全屏pop手势是否可用要根据四个情况来确定
 *
 *  第一种情况：当前控制器为根控制器了，全屏pop手势手势不可用
 *  第二种情况：如果导航栏push、pop动画正在执行（私有属性）时，全屏pop手势不可用
 *  第三种情况：手势是上下移动方向，全屏pop手势不可用
 *  第四种情况：手势是右往左移动方向，全屏pop手势不可用
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint vTranslationPoint = [recognizer translationInView:recognizer.view];
        if (fabs(vTranslationPoint.x) > fabs(vTranslationPoint.y)) { //左右滑动
            
            BOOL isRootViewController = (self.viewControllers.count == 1);
            BOOL isTransitioning = [[self valueForKey:@"_isTransitioning"] boolValue];
            BOOL isPanPortraitToLeft = (vTranslationPoint.x < 0);
            
            return !isRootViewController && !isTransitioning && !isPanPortraitToLeft;
        }
    }
    
    return NO;
}

@end
