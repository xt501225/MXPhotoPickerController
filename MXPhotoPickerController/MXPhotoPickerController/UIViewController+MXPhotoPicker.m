//
//  UIViewController+MXPhotoPicker.m
//  MXPhotoPickerController
//
//  Created by Apple on 15/12/8.
//  Copyright © 2015年 韦纯航. All rights reserved.
//

#import "UIViewController+MXPhotoPicker.h"

#import <objc/runtime.h>
#import "MXPhotoPickerController.h"

#pragma mark - MXImagePickerController

static NSString *const kPhotoLibraryTitle = @"从手机相册选择";
static NSString *const kCameraTitle = @"拍照";

@interface MXImagePickerController : UIImagePickerController

@property (strong, nonatomic) UIFont *titleFont;     //图片选择器导航栏标题字体，默认17.0
@property (strong, nonatomic) UIColor *titleColor;   //图片选择器导航栏标题颜色，默认黑色
@property (strong, nonatomic) UIColor *barItemColor; //图片选择器导航栏左右两边按钮的颜色，默认黑色
@property (strong, nonatomic) UIColor *barBackColor; //图片选择器导航栏背景的颜色，默认白色
@property (assign, nonatomic) UIStatusBarStyle statusBarStyle; //图片选择器状态栏样式，默认黑色样式

@end

@implementation MXImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 打开相机时导航栏看不到，不需要设置导航栏属性
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) return;
    
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    [titleTextAttributes setValue:self.titleColor forKey:NSForegroundColorAttributeName];
    [titleTextAttributes setValue:self.titleFont forKey:NSFontAttributeName];
    [self.navigationBar setTitleTextAttributes:titleTextAttributes];
    
    [self.navigationBar setTintColor:self.barItemColor];
    [self.navigationBar setBarTintColor:self.barBackColor];
}

- (UIFont *)titleFont
{
    if (_titleFont) {
        return _titleFont;
    }
    
    return [UIFont systemFontOfSize:17.0];
}

- (UIColor *)titleColor
{
    if (_titleColor) {
        return _titleColor;
    }
    
    return [UIColor blackColor];
}

- (UIColor *)barItemColor
{
    if (_barItemColor) {
        return _barItemColor;
    }
    
    return [UIColor blackColor];
}

- (UIColor *)barBackColor
{
    if (_barBackColor) {
        return _barBackColor;
    }
    
    return [UIColor whiteColor];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

@end

#pragma mark - UIActionSheet

#define NSArrayObjectMaybeNil(__ARRAY__, __INDEX__) ((__INDEX__ >= [__ARRAY__ count]) ? nil : [__ARRAY__ objectAtIndex:__INDEX__])
// This is a hack to turn an array into a variable argument list. There is no good way to expand arrays into variable argument lists in Objective-C. This works by nil-terminating the list as soon as we overstep the bounds of the array. The obvious glitch is that we only support a finite number of buttons.
#define NSArrayToVariableArgumentsList(__ARRAYNAME__) NSArrayObjectMaybeNil(__ARRAYNAME__, 0), NSArrayObjectMaybeNil(__ARRAYNAME__, 1), NSArrayObjectMaybeNil(__ARRAYNAME__, 2), NSArrayObjectMaybeNil(__ARRAYNAME__, 3), NSArrayObjectMaybeNil(__ARRAYNAME__, 4), NSArrayObjectMaybeNil(__ARRAYNAME__, 5), NSArrayObjectMaybeNil(__ARRAYNAME__, 6), NSArrayObjectMaybeNil(__ARRAYNAME__, 7), NSArrayObjectMaybeNil(__ARRAYNAME__, 8), NSArrayObjectMaybeNil(__ARRAYNAME__, 9), nil

typedef void (^UIActionSheetClickBlock)(UIActionSheet *actionSheet, NSInteger buttonIndex);

@interface MXActionSheet : UIActionSheet

@property (copy, nonatomic) UIActionSheetClickBlock clickBlock;

+ (id)actionSheetWithTitle:(NSString *)title
         cancelButtonTitle:(NSString *)cancelButtonTitle
    destructiveButtonTitle:(NSString *)destructiveButtonTitle
         otherButtonTitles:(NSArray *)otherButtonTitles;

- (void)addClickBlock:(UIActionSheetClickBlock)clickBlock;

@end

@implementation MXActionSheet

+ (id)actionSheetWithTitle:(NSString *)title
         cancelButtonTitle:(NSString *)cancelButtonTitle
    destructiveButtonTitle:(NSString *)destructiveButtonTitle
         otherButtonTitles:(NSArray *)otherButtonTitles
{
    MXActionSheet *actionSheet = [[self alloc] initWithTitle:title
                                                    delegate:nil
                                           cancelButtonTitle:cancelButtonTitle
                                      destructiveButtonTitle:destructiveButtonTitle
                                           otherButtonTitles:NSArrayToVariableArgumentsList(otherButtonTitles)];
    return actionSheet;
}

- (void)addClickBlock:(UIActionSheetClickBlock)clickBlock
{
    [self _checkActionSheetOriginalDelegate];
    _clickBlock = [clickBlock copy];
}

- (void)_checkActionSheetOriginalDelegate {
    if (self.delegate != (id<UIActionSheetDelegate>)self) {
        self.delegate = (id<UIActionSheetDelegate>)self;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet isKindOfClass:[self class]]) {
        MXActionSheet *mxActionSheet = (MXActionSheet *)actionSheet;
        UIActionSheetClickBlock completion = mxActionSheet.clickBlock;
        if (completion) {
            completion(actionSheet, buttonIndex);
        }
    }
}

@end

#pragma mark - MXPhotoPicker

@interface UIViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MXPhotoPickerControllerDelegate>

@end

@implementation UIViewController (MXPhotoPicker)

static MXPhotoPickerSingleBlock _pickerSingleBlock;
static MXPhotoPickerMultipleBlock _pickerMultipleBlock;

/**
 *  照相 + 相册（均单选）
 *
 *  @param title      选择栏标题
 *  @param completion 回调
 */
- (void)showMXPhotoPickerWithTitle:(NSString *)title completion:(MXPhotoPickerSingleBlock)completion
{
    NSMutableArray *otherButtonTitles = [NSMutableArray array];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [otherButtonTitles addObject:kCameraTitle];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [otherButtonTitles addObject:kPhotoLibraryTitle];
    }
    
    if (otherButtonTitles.count == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"当前设备不支持拍照和图库" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        return;
    }
    
    _pickerSingleBlock = completion;
    
    typeof(self) __weak weakSelf = self;
    MXActionSheet *actionSheet = [MXActionSheet actionSheetWithTitle:title cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:otherButtonTitles];
    [actionSheet addClickBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        [weakSelf actionSheet:actionSheet didClickButtonAtIndex:buttonIndex];
    }];
    [actionSheet performSelectorOnMainThread:@selector(showInView:) withObject:self.view waitUntilDone:YES];
}

/**
 *  照相（单选）
 *
 *  @param completion 回调
 */
- (void)showMXPhotoCamera:(MXPhotoPickerSingleBlock)completion
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"当前设备不支持拍照" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil] show];
        return;
    }
    
    [self showMXPhotoCamera];
    _pickerSingleBlock = completion;
}

/**
 *  相册（单选）
 *
 *  @param completion 回调
 */
- (void)showMXPhotoPickerController:(MXPhotoPickerSingleBlock)completion
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"当前设备不支持图库" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil] show];
        return;
    }
    
    [self showMXPhotoPickerController];
    _pickerSingleBlock = completion;
}

/**
 *  相册（多选）
 *
 *  @param maximumNumberOfSelectionalPhotos 最多允许选择的图片张数
 *  @param completion                       回调
 */
- (void)showMXPickerWithMaximumPhotosAllow:(NSInteger)maximumNumberOfSelectionalPhotos
                                completion:(MXPhotoPickerMultipleBlock)completion
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"当前设备不支持图库" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil] show];
        return;
    }
    
    [self showMXPhotosPickerController:maximumNumberOfSelectionalPhotos];
    _pickerMultipleBlock = completion;
}

#pragma mark - Private

- (void)actionSheet:(UIActionSheet *)actionSheet didClickButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        return;
    }
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:kCameraTitle]) {
        [self showMXPhotoCamera];
    }
    else if ([title isEqualToString:kPhotoLibraryTitle]) {
        [self showMXPhotoPickerController];
    }
}

- (void)showMXPhotoCamera
{
    MXImagePickerController *imagePicker = [[MXImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imagePicker setDelegate:self];
    [imagePicker setAllowsEditing:YES];
    
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (void)showMXPhotoPickerController
{
    MXImagePickerController *imagePicker = [[MXImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePicker setDelegate:self];
    [imagePicker setAllowsEditing:YES];
    
    // 设置自定义属性（不设置则使用默认）
    [imagePicker setBarBackColor:[UIColor colorWithRed:0 green:175/255.0 blue:240/255.0 alpha:1.0]];
    [imagePicker setStatusBarStyle:UIStatusBarStyleLightContent];
    [imagePicker setBarItemColor:[UIColor whiteColor]];
    [imagePicker setTitleColor:[UIColor whiteColor]];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)showMXPhotosPickerController:(NSInteger)maximumNumberOfSelectionalPhotos
{
    MXPhotoPickerController *picker = [[MXPhotoPickerController alloc] init];
    [picker setMaximumNumberOfSelectionalPhotos:maximumNumberOfSelectionalPhotos];
    [picker setFinishedDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *imageOriginal = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *imageEdited = [info valueForKey:UIImagePickerControllerEditedImage];
    CGRect cutRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
    if (_pickerSingleBlock) _pickerSingleBlock(imageEdited, imageOriginal, cutRect);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MXPhotoPickerControllerDelegate

- (void)imagePickerController:(MXPhotoPickerController *)picker didFinishPickingWithAssets:(NSArray *)assets
{
    if (_pickerMultipleBlock) _pickerMultipleBlock(assets);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
