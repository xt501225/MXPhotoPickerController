//
//  MainViewController.m
//  MXPhotoPickerController
//
//  Created by Apple on 15/12/8.
//  Copyright © 2015年 韦纯航. All rights reserved.
//

#import "MainViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "Masonry.h"
#import "MXNavigationController.h"
#import "JFImagePickerController.h"
#import "UIViewController+MXPhotoPicker.h"

#define WEAKSELF typeof(self) __weak weakSelf = self;

@interface MainViewController ()

@property (retain, nonatomic) UIImageView *imageView;

@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setBackgroundColor:[UIColor cyanColor]];
    [button1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button1 setTitle:@"打开图库一" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(openMXImagePickerControllerEvent:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setBackgroundColor:[UIColor cyanColor]];
    [button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button2 setTitle:@"打开图库二" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(openImagePickerControllerEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button1];
    [self.view addSubview:button2];
    
    [button1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20.0);
        make.width.equalTo(button2);
        make.height.mas_equalTo(60.0);
        make.bottom.equalTo(self.view).offset(-20.0);
    }];
    
    [button2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(button1.mas_right).offset(10.0);
        make.right.equalTo(self.view).offset(-20.0);
        make.bottom.height.equalTo(button1);
    }];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.layer.borderWidth = 1.0;
    self.imageView.layer.borderColor = [UIColor cyanColor].CGColor;
    [self.view addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20.0);
        make.top.equalTo(self.view).offset(20.0 + 64.0);
        make.right.equalTo(self.view).offset(-20.0);
        make.bottom.equalTo(button1.mas_top).offset(-20.0);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MXPhotoPickerController";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)openMXImagePickerControllerEvent:(UIButton *)button
{
    WEAKSELF
    
//    [self showMXPhotoPickerWithTitle:nil completion:^(UIImage *image, UIImage *originImage, CGRect cutRect) {
//        NSLog(@"sizeA = %@", NSStringFromCGSize(image.size));
//        NSLog(@"sizeB = %@", NSStringFromCGSize(originImage.size));
//        NSLog(@"sizeC = %@", NSStringFromCGSize(cutRect.size));
//
//        weakSelf.imageView.image = image;
//    }];
    
    [self showMXPickerWithMaximumPhotosAllow:9 completion:^(NSArray *assets) {
        NSLog(@"assets = %@", assets);
        if (assets.count > 0) {
            ALAsset *asset = assets.firstObject;
            UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
            weakSelf.imageView.image = image;
        }
    }];
}

// 参考的例子
- (void)openImagePickerControllerEvent:(UIButton *)button
{
    JFImagePickerController *picker = [[JFImagePickerController alloc] initWithRootViewController:self];
    picker.pickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - JFImagePickerDelegate

- (void)imagePickerDidFinished:(JFImagePickerController *)picker
{
    WEAKSELF
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"assets = %@", picker.assets);
        
        if (picker.assets.count > 0) {
            ALAsset *asset = picker.assets.firstObject;
            UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
            weakSelf.imageView.image = image;
        }
 
        [JFImagePickerController clear];
    }];
}

- (void)imagePickerDidCancel:(JFImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [JFImagePickerController clear];
    }];
}

@end
