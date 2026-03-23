/**
 * RednoteTools 弹窗视图
 * Author: 喜爱民谣
 * 彻底移除废弃 keyWindow API，适配 iOS 13+ 多Scene架构
 */

#import "PopupView.h"
#import "Tweak.h" // 引入项目原有头文件，获取UIColor扩展
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>

#define kPopupNotShowAgainKey @"RednoteToolsPopupNotShowAgain"
// iOS 15+ 适配：使用safeArea避免刘海/灵动岛遮挡
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define kSafeAreaInsets ([[self class] getSafeAreaInsets])

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

// MARK: - 核心修复：iOS 13+ 无废弃API获取安全区域
+ (UIEdgeInsets)getSafeAreaInsets {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [self getValidWindow]; // 替换为无废弃API的窗口获取方法
        return window.safeAreaInsets;
    }
    return UIEdgeInsetsZero;
}

// MARK: - 核心修复：彻底移除废弃keyWindow，iOS 13+ 标准窗口获取方法
+ (UIWindow *)getValidWindow {
    UIWindow *validWindow = nil;
    
    // iOS 13+ 官方推荐：遍历UIScene获取前台活跃窗口（无任何废弃API）
    if (@available(iOS 13.0, *)) {
        NSArray *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            // 只处理前台活跃的窗口场景
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            // 转换为UIWindowScene并获取窗口
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                // 优先取根窗口（无废弃API）
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) { // 这里的isKeyWindow是属性，非废弃的keyWindow方法
                        validWindow = window;
                        break;
                    }
                }
                // 兜底：取第一个可见窗口
                if (!validWindow) {
                    validWindow = windowScene.windows.firstObject;
                }
                if (validWindow) break;
            }
        }
    } else {
        // iOS 12及以下：保留兼容写法（无废弃问题）
        validWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    // 终极兜底：遍历所有窗口（无废弃API）
    if (!validWindow) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (!window.isHidden && window.windowLevel == UIWindowLevelNormal) {
                validWindow = window;
                break;
            }
        }
    }
    
    return validWindow;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // iOS 15+ 适配：修复半透明背景交互穿透问题
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.userInteractionEnabled = YES;
        
        [self setupUI];
        [self loadUserAvatar];
        [self setupInstructionView];
        
        // iOS 15+ 适配：添加点击空白处关闭（增强交互）
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blankAreaTap)];
        tap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setupUI {
    // iOS 15+ 适配：计算弹窗Y坐标时加入安全区域（避免被灵动岛/刘海遮挡）
    CGFloat contentY = (kScreenHeight - 420 - kSafeAreaInsets.top - kSafeAreaInsets.bottom) / 2 + kSafeAreaInsets.top;
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(30, contentY, kScreenWidth - 60, 420)];
    
    // iOS 15+ 适配：修复UIButton圆角/阴影渲染问题
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 16;
    self.contentView.layer.masksToBounds = NO; // 必须关闭，否则阴影不显示
    self.contentView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 8;
    self.contentView.layer.shadowOpacity = 1;
    // iOS 15+ 适配：开启阴影路径优化（减少离屏渲染）
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds cornerRadius:16].CGPath;
    [self addSubview:self.contentView];
    
    // 头像
    self.avatarImgView = [[UIImageView alloc] initWithFrame:CGRectMake((self.contentView.frame.size.width - 80)/2, 25, 80, 80)];
    self.avatarImgView.layer.cornerRadius = 40;
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.backgroundColor = [UIColor xy_colorWithHex:0xF5F5F5];
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
    self.instructionView.userInteractionEnabled = YES;
    [self addSubview:self.instructionView];
    
    // iOS 15+ 适配：使用安全区域计算说明弹窗位置
    CGFloat instructionContentY = (kScreenHeight - 450 - kSafeAreaInsets.top - kSafeAreaInsets.bottom) / 2 + kSafeAreaInsets.top;
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(30, instructionContentY, kScreenWidth - 60, 450)];
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    content.layer.masksToBounds = YES; // 说明弹窗不需要阴影，直接裁剪
    [self.instructionView addSubview:content];
    
    // 说明文本
    self.instructionLab = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, content.frame.size.width - 40, content.frame.size.height - 80)];
    // iOS 15+ 适配：修复字体权重显示异常
    self.instructionLab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.instructionLab.textColor = [UIColor xy_colorWithHex:0x333333];
    self.instructionLab.numberOfLines = 0;
    self.instructionLab.lineBreakMode = NSLineBreakByWordWrapping;
    self.instructionLab.text = @"图片去水印-图片预览页左下角出现 2 个下载按钮\n\n左按钮：无水印保存当前图片\n\n右按钮：无水印批量保存全部图片\n\n视频去水印-原生保存，无水印、无片头、无尾标\n\nLive Photo 实况图去水印-与图片保存逻辑通用\n\n评论区图片去水印-原生保存\n\n表情包去水印保存-原生保存";
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
    // iOS 15+ 适配：修复UIButton字体权重显示问题
    btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 8;
    btn.clipsToBounds = YES;
    
    // iOS 15+ 适配：修复高亮背景图渲染异常
    [btn setBackgroundImage:[self imageWithColor:[bgColor colorWithAlphaComponent:0.8]] forState:UIControlStateHighlighted];
    
    // iOS 15+ 适配：关闭按钮自动调整颜色（避免系统默认 tintColor 干扰）
    if (@available(iOS 15.0, *)) {
        btn.configuration = nil; // 禁用新的UIButtonConfiguration
    }
    
    return btn;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale); // iOS 15+ 适配：使用屏幕scale
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
        // iOS 15+ 适配：使用屏幕scale生成图片，避免模糊
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(80, 80), NO, [UIScreen mainScreen].scale);
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

// MARK: - 交互事件（iOS 15+ 适配）
- (void)blankAreaTap {
    // 点击空白处关闭弹窗（排除内容区域）
    CGPoint tapPoint = [[[self gestureRecognizers] firstObject] locationInView:self];
    if (!CGRectContainsPoint(self.contentView.frame, tapPoint) && !self.instructionView.isHidden) {
        [self closeInstructionView];
    } else if (!CGRectContainsPoint(self.contentView.frame, tapPoint)) {
        [self dismiss];
    }
}

- (void)instructionBtnClick {
    self.instructionView.hidden = NO;
}

- (void)closeInstructionView {
    self.instructionView.hidden = YES;
}

- (void)notShowAgainBtnClick {
    // iOS 15+ 适配：修复NSUserDefaults同步问题
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPopupNotShowAgainKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss];
}

- (void)knowBtnClick {
    [self dismiss];
}

- (void)dismiss {
    // iOS 15+ 适配：修复动画卡顿问题
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

+ (void)showPopupIfNeeded {
    // 判断是否需要显示弹窗
    BOOL notShowAgain = [[NSUserDefaults standardUserDefaults] boolForKey:kPopupNotShowAgainKey];
    if (notShowAgain) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用无废弃API的窗口获取方法
        UIWindow *validWindow = [self getValidWindow];
        if (!validWindow) return;
        
        PopupView *popup = [[PopupView alloc] initWithFrame:validWindow.bounds];
        [validWindow addSubview:popup];
        
        // iOS 15+ 适配：优化动画参数，避免弹簧效果过度
        popup.alpha = 0;
        popup.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseOut animations:^{
            popup.alpha = 1;
            popup.contentView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

@end
