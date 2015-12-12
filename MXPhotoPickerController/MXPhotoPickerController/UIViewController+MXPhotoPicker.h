//
//  UIViewController+MXPhotoPicker.h
//  MXPhotoPickerController
//
//  Created by Apple on 15/12/8.
//  Copyright © 2015年 韦纯航. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (MXPhotoPicker)

/**
 *  选择图片后的回调（单选）
 *
 *  @param image       选择区域中的图片
 *  @param originImage 图片原图
 *  @param cutRect     选中的区域
 */
typedef void (^MXPhotoPickerSingleBlock)(UIImage *image, UIImage *originImage, CGRect cutRect);

/**
 *  选择图片后的回调（多选）
 *
 *  @param assets 选择的图片数组（数组中是ALAsset对象）
 */
typedef void (^MXPhotoPickerMultipleBlock)(NSArray *assets);

/**
 *  照相 + 相册（均单选）
 *
 *  @param title      选择栏标题
 *  @param completion 回调
 */
- (void)showMXPhotoPickerWithTitle:(NSString *)title completion:(MXPhotoPickerSingleBlock)completion;

/**
 *  照相（单选）
 *
 *  @param completion 回调
 */
- (void)showMXPhotoCamera:(MXPhotoPickerSingleBlock)completion;

/**
 *  相册（单选）
 *
 *  @param completion 回调
 */
- (void)showMXPhotoPickerController:(MXPhotoPickerSingleBlock)completion;

/**
 *  相册（多选）
 *
 *  @param maximumNumberOfSelectionalPhotos 最多允许选择的图片张数
 *  @param completion                       回调
 */
- (void)showMXPickerWithMaximumPhotosAllow:(NSInteger)maximumNumberOfSelectionalPhotos
                                completion:(MXPhotoPickerMultipleBlock)completion;

@end
