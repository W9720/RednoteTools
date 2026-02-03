/**
 * RednoteTools v1.0
 * 版权动画
 * 
 * Author: COOKIEODD
 * Homepage: https://t.me/COOKIEODD
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static NSArray *rainbowColors(void) {
    return @[
        [UIColor colorWithRed:1.0 green:0.0 blue:0.4 alpha:1.0],
        [UIColor colorWithRed:1.0 green:0.4 blue:0.0 alpha:1.0],
        [UIColor colorWithRed:1.0 green:0.85 blue:0.0 alpha:1.0],
        [UIColor colorWithRed:0.0 green:1.0 blue:0.3 alpha:1.0],
        [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0],
        [UIColor colorWithRed:0.3 green:0.0 blue:1.0 alpha:1.0],
        [UIColor colorWithRed:0.7 green:0.0 blue:1.0 alpha:1.0],
    ];
}

@interface CopyrightAnimationView : UIView
@property (nonatomic, strong) NSMutableArray *charLabels;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat textY;
@end

@implementation CopyrightAnimationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.charLabels = [NSMutableArray array];
        self.centerX = frame.size.width / 2;
        self.textY = frame.size.height / 2 - 15;
    }
    return self;
}

- (void)startAnimation {
    [self showText];
}


- (void)showText {
    NSString *text = @"DEV BY @COOKIEODD";
    CGFloat fontSize = 22;
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    
    CGFloat totalWidth = 0;
    NSMutableArray *widths = [NSMutableArray array];
    for (NSInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        CGFloat w = [ch sizeWithAttributes:@{NSFontAttributeName: font}].width;
        [widths addObject:@(w)];
        totalWidth += w;
    }
    
    CGFloat x = _centerX - totalWidth / 2;
    
    for (NSInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        CGFloat w = [widths[i] floatValue];
        
        UILabel *lbl = [[UILabel alloc] init];
        lbl.text = ch;
        lbl.font = font;
        
        CGFloat progress = (CGFloat)i / (text.length - 1);
        UIColor *textColor;
        if (progress < 0.33) {
            CGFloat t = progress / 0.33;
            textColor = [UIColor colorWithRed:1.0 green:0.85 - 0.1*t blue:0.9 + 0.1*t alpha:1.0];
        } else if (progress < 0.66) {
            CGFloat t = (progress - 0.33) / 0.33;
            textColor = [UIColor colorWithRed:1.0 - 0.15*t green:0.75 + 0.15*t blue:1.0 alpha:1.0];
        } else {
            CGFloat t = (progress - 0.66) / 0.34;
            textColor = [UIColor colorWithRed:0.85 + 0.1*t green:0.9 + 0.08*t blue:1.0 alpha:1.0];
        }
        lbl.textColor = textColor;
        
        lbl.frame = CGRectMake(x, _textY, w, fontSize + 4);
        lbl.alpha = 0;
        lbl.transform = CGAffineTransformMakeScale(0.2, 0.2);
        
        lbl.layer.shadowColor = textColor.CGColor;
        lbl.layer.shadowOffset = CGSizeZero;
        lbl.layer.shadowRadius = 8;
        lbl.layer.shadowOpacity = 0.9;
        
        [self addSubview:lbl];
        [_charLabels addObject:lbl];
        x += w;
        
        [UIView animateWithDuration:0.25 delay:i * 0.018 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:0 animations:^{
            lbl.alpha = 1;
            lbl.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addGlow];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self explodeChars];
    });
}

- (void)addGlow {
    NSArray *colors = rainbowColors();
    for (NSInteger i = 0; i < _charLabels.count; i++) {
        UILabel *lbl = _charLabels[i];
        
        CABasicAnimation *g = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
        g.fromValue = @6;
        g.toValue = @12;
        g.duration = 0.35;
        g.autoreverses = YES;
        g.repeatCount = HUGE_VALF;
        [lbl.layer addAnimation:g forKey:@"g"];
        
        CAKeyframeAnimation *c = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
        NSInteger idx = i % colors.count;
        c.values = @[(id)[colors[idx] CGColor], (id)[colors[(idx+2)%colors.count] CGColor], (id)[colors[idx] CGColor]];
        c.duration = 0.8;
        c.repeatCount = HUGE_VALF;
        [lbl.layer addAnimation:c forKey:@"c"];
    }
}


- (void)explodeChars {
    NSString *text = @"DEV BY @COOKIEODD";
    NSInteger idx = 0;
    
    for (NSInteger i = 0; i < _charLabels.count; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        if ([ch isEqualToString:@" "]) continue;
        
        UILabel *lbl = _charLabels[i];
        CGFloat delay = idx * 0.045;
        idx++;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self popChar:lbl];
        });
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((idx * 0.045 + 0.35) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}

- (void)popChar:(UILabel *)lbl {
    [lbl.layer removeAllAnimations];
    CGPoint c = lbl.center;
    NSArray *colors = rainbowColors();
    
    [UIView animateWithDuration:0.05 animations:^{
        lbl.transform = CGAffineTransformMakeScale(1.15, 1.15);
        lbl.alpha = 0.6;
    } completion:^(BOOL finished) {
        for (NSInteger i = 0; i < 5; i++) {
            UIColor *col = colors[arc4random_uniform((uint32_t)colors.count)];
            CGFloat sz = 3 + arc4random_uniform(4);
            
            UIView *p = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sz, sz)];
            p.backgroundColor = [col colorWithAlphaComponent:0.8];
            p.layer.cornerRadius = sz / 2;
            p.center = c;
            p.layer.shadowColor = col.CGColor;
            p.layer.shadowRadius = 3;
            p.layer.shadowOpacity = 0.7;
            p.layer.shadowOffset = CGSizeZero;
            [self insertSubview:p belowSubview:lbl];
            
            CGFloat ang = (2 * M_PI / 5) * i + (arc4random_uniform(30) - 15) * M_PI / 180.0;
            CGFloat dist = 15 + arc4random_uniform(18);
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                p.center = CGPointMake(c.x + cos(ang) * dist, c.y + sin(ang) * dist);
                p.alpha = 0;
                p.transform = CGAffineTransformMakeScale(0.15, 0.15);
            } completion:^(BOOL finished) {
                [p removeFromSuperview];
            }];
        }
        
        [UIView animateWithDuration:0.08 animations:^{
            lbl.transform = CGAffineTransformMakeScale(1.25, 1.25);
            lbl.alpha = 0;
        } completion:^(BOOL finished) {
            [lbl removeFromSuperview];
        }];
    }];
}

@end

#pragma mark - 入口

static BOOL shown = NO;

void showCopyrightAnimation(void) {
    if (shown) return;
    shown = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *w = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
                if (s.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *win in s.windows) {
                        if (win.isKeyWindow) { w = win; break; }
                    }
                }
                if (w) break;
            }
        }
        if (!w) w = [UIApplication sharedApplication].windows.firstObject;
        if (!w) return;
        
        CopyrightAnimationView *v = [[CopyrightAnimationView alloc] initWithFrame:w.bounds];
        [w addSubview:v];
        [v startAnimation];
    });
}
