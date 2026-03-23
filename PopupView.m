#import "PopupView.h"
#import <UIKit/UIKit.h>

#define kPopupNotShowAgainKey @"RednoteToolsPopupNotShowAgain"
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define kSafeAreaInsets ([[self class] getSafeAreaInsets])

// 类扩展必须在 #import "PopupView.h" 之后
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
+ (void)showPopupIfNeeded {
    NSLog(@"🔥 showPopupIfNeeded 被调用了");

    BOOL notShowAgain = [[NSUserDefaults standardUserDefaults] boolForKey:kPopupNotShowAgainKey];
    if (notShowAgain) {
        NSLog(@"🔥 因为不再提示，所以不显示");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *validWindow = [self getValidWindow];
        if (!validWindow) return;
        
        PopupView *popup = [[PopupView alloc] initWithFrame:validWindow.bounds];
        [validWindow addSubview:popup];
        
        popup.alpha = 0;
        popup.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseOut animations:^{
            popup.alpha = 1;
            popup.contentView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

+ (UIEdgeInsets)getSafeAreaInsets {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [self getValidWindow];
        return window.safeAreaInsets;
    }
    return UIEdgeInsetsZero;
}

+ (UIWindow *)getValidWindow {
    UIWindow *validWindow = nil;
    
    if (@available(iOS 13.0, *)) {
        NSArray *connectedScenes = [[UIApplication sharedApplication].connectedScenes allObjects];
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        validWindow = window;
                        break;
                    }
                }
                if (!validWindow) validWindow = windowScene.windows.firstObject;
                if (validWindow) break;
            }
        }
    }
    
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
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.userInteractionEnabled = YES;
        [self setupUI];
        [self loadUserAvatar];
        [self setupInstructionView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blankAreaTap)];
        tap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setupUI {
    CGFloat contentY = (kScreenHeight - 420 - kSafeAreaInsets.top - kSafeAreaInsets.bottom) / 2 + kSafeAreaInsets.top;
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(30, contentY, kScreenWidth - 60, 420)];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 16;
    self.contentView.layer.masksToBounds = NO;
    self.contentView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 8;
    self.contentView.layer.shadowOpacity = 1;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds cornerRadius:16].CGPath;
    [self addSubview:self.contentView];
    
    self.avatarImgView = [[UIImageView alloc] initWithFrame:CGRectMake((self.contentView.frame.size.width - 80)/2, 25, 80, 80)];
    self.avatarImgView.layer.cornerRadius = 40;
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.backgroundColor = [UIColor colorWithRed:0xF5/255.0 green:0xF5/255.0 blue:0xF5/255.0 alpha:1.0];
    self.avatarImgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.avatarImgView];
    
    self.titleLab1 = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.avatarImgView.frame) + 20, self.contentView.frame.size.width - 40, 30)];
    self.titleLab1.text = @"RednoteTools";
    self.titleLab1.font = [UIFont boldSystemFontOfSize:22];
    self.titleLab1.textColor = [UIColor colorWithRed:0x22/255.0 green:0x22/255.0 blue:0x22/255.0 alpha:1.0];
    self.titleLab1.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLab1];
    
    self.titleLab2 = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.titleLab1.frame) + 8, self.contentView.frame.size.width - 40, 24)];
    self.titleLab2.text = @"喜爱民谣";
    self.titleLab2.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.titleLab2.textColor = [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0];
    self.titleLab2.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLab2];
    
    self.instructionBtn = [self createButtonWithTitle:@"使用说明" bgColor:[UIColor colorWithRed:0x00/255.0 green:0x88/255.0 blue:0xFF/255.0 alpha:1.0] textColor:[UIColor whiteColor] frame:CGRectMake(25, CGRectGetMaxY(self.titleLab2.frame) + 25, self.contentView.frame.size.width - 50, 48)];
    [self.instructionBtn addTarget:self action:@selector(instructionBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.instructionBtn];
    
    self.notShowAgainBtn = [self createButtonWithTitle:@"不再提示" bgColor:[UIColor colorWithRed:0xE6/255.0 green:0xE6/255.0 blue:0xE6/255.0 alpha:1.0] textColor:[UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0] frame:CGRectMake(25, CGRectGetMaxY(self.instructionBtn.frame) + 12, (self.contentView.frame.size.width - 60)/2, 48)];
    [self.notShowAgainBtn addTarget:self action:@selector(notShowAgainBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.notShowAgainBtn];
    
    self.knowBtn = [self createButtonWithTitle:@"我知道了" bgColor:[UIColor colorWithRed:0x00/255.0 green:0x88/255.0 blue:0xFF/255.0 alpha:1.0] textColor:[UIColor whiteColor] frame:CGRectMake(CGRectGetMaxX(self.notShowAgainBtn.frame) + 10, CGRectGetMaxY(self.instructionBtn.frame) + 12, (self.contentView.frame.size.width - 60)/2, 48)];
    [self.knowBtn addTarget:self action:@selector(knowBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.knowBtn];
}

- (void)setupInstructionView {
    self.instructionView = [[UIView alloc] initWithFrame:self.bounds];
    self.instructionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.instructionView.hidden = YES;
    self.instructionView.userInteractionEnabled = YES;
    [self addSubview:self.instructionView];
    
    CGFloat instructionContentY = (kScreenHeight - 450 - kSafeAreaInsets.top - kSafeAreaInsets.bottom) / 2 + kSafeAreaInsets.top;
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(30, instructionContentY, kScreenWidth - 60, 450)];
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    content.layer.masksToBounds = YES;
    [self.instructionView addSubview:content];
    
    self.instructionLab = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, content.frame.size.width - 40, content.frame.size.height - 80)];
    self.instructionLab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.instructionLab.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0];
    self.instructionLab.numberOfLines = 0;
    self.instructionLab.lineBreakMode = NSLineBreakByWordWrapping;
    self.instructionLab.text = @"一只傻娟子提示\n\n图片去水印-图片预览页左下角出现 2 个下载按钮\n\n左按钮：无水印保存当前图片\n\n右按钮：无水印批量保存全部图片\n\n视频去水印-原生保存，无水印、无片头、无尾标\n\nLive Photo 实况图去水印-与图片保存逻辑通用\n\n评论区图片去水印-原生保存\n\n表情包去水印保存-原生保存";
    [content addSubview:self.instructionLab];
    
    UIButton *closeBtn = [self createButtonWithTitle:@"关闭" bgColor:[UIColor colorWithRed:0x00/255.0 green:0x88/255.0 blue:0xFF/255.0 alpha:1.0] textColor:[UIColor whiteColor] frame:CGRectMake(20, CGRectGetMaxY(self.instructionLab.frame) + 10, content.frame.size.width - 40, 48)];
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
    [btn setBackgroundImage:[self imageWithColor:[bgColor colorWithAlphaComponent:0.8]] forState:UIControlStateHighlighted];
    if (@available(iOS 15.0, *)) {
        btn.configuration = nil;
    }
    return btn;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)loadUserAvatar {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(80, 80), NO, [UIScreen mainScreen].scale);
        [[UIColor colorWithRed:0x00/255.0 green:0x88/255.0 blue:0xFF/255.0 alpha:1.0] setFill];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 80, 80)];
        [path fill];
        UIImage *avatarImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatarImgView.image = avatarImage;
        });
    });
}

- (void)blankAreaTap {
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPopupNotShowAgainKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss];
}

- (void)knowBtnClick {
    [self dismiss];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
