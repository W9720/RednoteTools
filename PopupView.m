/**
 * RednoteTools 弹窗视图
 * Author: 喜爱民谣
 */

#import "PopupView.h"
#import "Tweak.h" // 引入项目原有头文件，获取UIColor扩展
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>

#define kPopupNotShowAgainKey @"RednoteToolsPopupNotShowAgain"
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface PopupView ()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *avatarImgView;
@property (nonatomic, strong) UILabel *titleLab1;
@property (nonatomic, strong) UILabel *titleLab2;
@property (nonatomic, strong) UIButton *instructionBtn;
@property (nonatomic, strong) UIButton *notShowAgainBtn;
@property (nonatomic, strong) UIButton *knowBtn;
@property (nonatomic, strong) UIView *instructionView;
@property (nonatomic, strong) UILabel *instructionLab;
@end

@implementation PopupView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self setupUI];
        [self loadUserAvatar];
        [self setupInstructionView];
    }
    return self;
}

- (void)setupUI {
    // 内容容器
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(30, (kScreenHeight - 420)/2, kScreenWidth - 60, 420)];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 16;
    self.contentView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 8;
    self.contentView.layer.shadowOpacity = 1;
    [self addSubview:self.contentView];
    
    // 头像
    self.avatarImgView = [[UIImageView alloc] initWithFrame:CGRectMake((self.contentView.frame.size.width - 80)/2, 25, 80, 80)];
    self.avatarImgView.layer.cornerRadius = 40;
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.backgroundColor = [UIColor xy_colorWithHex:0xF5F5F5]; // 改用项目原有扩展
    self.avatarImgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.avatarImgView];
    
    // 标题1: RednoteTools
    self.titleLab1 = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.avatarImgView.frame) + 20, self.contentView.frame.size.width - 40, 30)];
    self.titleLab1.text = @"RednoteTools";
    self.titleLab1.font = [UIFont boldSystemFontOfSize:22];
    self.titleLab1.textColor = [UIColor xy_colorWithHex:0x222222];
    self.titleLab1.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLab1];
    
    // 标题2: 喜爱民谣
    self.titleLab2 = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.titleLab1.frame) + 8, self.contentView.frame.size.width - 40, 24)];
    self.titleLab2.text = @"喜爱民谣";
    self.titleLab2.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.titleLab2.textColor = [UIColor xy_colorWithHex:0x666666];
    self.titleLab2.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLab2];
    
    // 查看使用说明按钮
    self.instructionBtn = [self createButtonWithTitle:@"查看使用说明" 
                                               bgColor:[UIColor xy_colorWithHex:0x0088FF] 
                                              textColor:[UIColor whiteColor] 
                                                  frame:CGRectMake(25, CGRectGetMaxY(self.titleLab2.frame) + 25, self.contentView.frame.size.width - 50, 48)];
    [self.instructionBtn addTarget:self action:@selector(instructionBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.instructionBtn];
    
    // 不再提示按钮
    self.notShowAgainBtn = [self createButtonWithTitle:@"不再提示" 
                                               bgColor:[UIColor xy_colorWithHex:0xE6E6E6] 
                                              textColor:[UIColor xy_colorWithHex:0x666666] 
                                                  frame:CGRectMake(25, CGRectGetMaxY(self.instructionBtn.frame) + 12, (self.contentView.frame.size.width - 60)/2, 48)];
    [self.notShowAgainBtn addTarget:self action:@selector(notShowAgainBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.notShowAgainBtn];
    
    // 朕已阅按钮
    self.knowBtn = [self createButtonWithTitle:@"朕已阅" 
                                       bgColor:[UIColor xy_colorWithHex:0x0088FF] 
                                      textColor:[UIColor whiteColor] 
                                          frame:CGRectMake(CGRectGetMaxX(self.notShowAgainBtn.frame) + 10, CGRectGetMaxY(self.instructionBtn.frame) + 12, (self.contentView.frame.size.width - 60)/2, 48)];
    [self.knowBtn addTarget:self action:@selector(knowBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.knowBtn];
}

- (void)setupInstructionView {
    // 使用说明弹窗
    self.instructionView = [[UIView alloc] initWithFrame:self.bounds];
    self.instructionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.instructionView.hidden = YES;
    [self addSubview:self.instructionView];
    
    // 说明内容容器
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(30, (kScreenHeight - 450)/2, kScreenWidth - 60, 450)];
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    [self.instructionView addSubview:content];
    
    // 说明文本
    self.instructionLab = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, content.frame.size.width - 40, content.frame.size.height - 80)];
    self.instructionLab.font = [UIFont systemFontOfSize:16];
    self.instructionLab.textColor = [UIColor xy_colorWithHex:0x333333];
    self.instructionLab.numberOfLines = 0;
    self.instructionLab.lineBreakMode = NSLineBreakByWordWrapping;
    self.instructionLab.text = @"图片去水印-图片预览页左下角 → 出现 2 个下载按钮，左按钮：保存当前图片，右按钮：批量保存全部图片（无水印）。\n\n视频去水印-原生保存，无水印、无片头、无尾标。\n\nLive Photo 实况图去水印-与图片保存通用。\n\n评论区图片去水印-原生保存。\n\n表情包去水印保存-原生保存。";
    [content addSubview:self.instructionLab];
    
    // 关闭按钮
    UIButton *closeBtn = [self createButtonWithTitle:@"关闭" 
                                           bgColor:[UIColor xy_colorWithHex:0x0088FF] 
                                          textColor:[UIColor whiteColor] 
                                              frame:CGRectMake(20, CGRectGetMaxY(self.instructionLab.frame) + 10, content.frame.size.width - 40, 48)];
    [closeBtn addTarget:self action:@selector(closeInstructionView) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:closeBtn];
}

- (UIButton *)createButtonWithTitle:(NSString *)title bgColor:(UIColor *)bgColor textColor:(UIColor *)textColor frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.backgroundColor = bgColor;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:textColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 8;
    btn.clipsToBounds = YES;
    
    // 按钮点击高亮效果
    [btn setBackgroundImage:[self imageWithColor:[bgColor colorWithAlphaComponent:0.8]] forState:UIControlStateHighlighted];
    return btn;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)loadUserAvatar {
    // 简化版：使用占位图（实际可后续替换为小红书真实头像逻辑）
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 生成纯色占位头像
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(80, 80), NO, 0);
        [[UIColor xy_colorWithHex:0x0088FF] setFill];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 80, 80)];
        [path fill];
        UIImage *avatarImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatarImgView.image = avatarImage;
        });
    });
}

#pragma mark - 按钮点击事件
- (void)instructionBtnClick {
    self.instructionView.hidden = NO;
}

- (void)closeInstructionView {
    self.instructionView.hidden = YES;
}

- (void)notShowAgainBtnClick {
    // 存储不再提示状态
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPopupNotShowAgainKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss];
}

- (void)knowBtnClick {
    [self dismiss];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

+ (void)showPopupIfNeeded {
    // 判断是否需要显示弹窗
    BOOL notShowAgain = [[NSUserDefaults standardUserDefaults] boolForKey:kPopupNotShowAgainKey];
    if (notShowAgain) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    keyWindow = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!keyWindow) return;
        
        PopupView *popup = [[PopupView alloc] initWithFrame:keyWindow.bounds];
        [keyWindow addSubview:popup];
        
        // 弹窗入场动画
        popup.alpha = 0;
        popup.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.8 options:0 animations:^{
            popup.alpha = 1;
            popup.contentView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

@end
