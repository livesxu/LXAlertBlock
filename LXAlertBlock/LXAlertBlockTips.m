//
//  AlertBlockTips.m
//  RssReadNeed
//
//  Created by Xu小波 on 2017/12/12.
//  Copyright © 2017年 Livesxu. All rights reserved.
//

#import "LXAlertBlockTips.h"


@interface LXAlertBlockTips (){
    
    NSString *titleText;
    NSString *btnTitleText;
    NSString *otherBtnTitleText;
}

@end

@implementation LXAlertBlockTips

- (void)dealloc{
    
    NSLog(@"%@ %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                 Config:(UIView *(^)(void))configBlock
            ClickAction:(ClickBlockAction)clickBlock {
    
    titleText = title;
    btnTitleText = clicks.firstObject;
    if (clicks.count == 2) {//只两个btn..多余自定义
        
        otherBtnTitleText = clicks.lastObject;
    }
    _clickBlock = clickBlock;
    _containView = configBlock();
    
}

- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                Message:(NSString *)message
            ClickAction:(ClickBlockAction)clickBlock;{
    
    [self configWithTitle:title ClickTitles:clicks Config:^UIView *{
        
        CGFloat messageWidth = kScreenWidth - Layout(120);
        CGFloat messageHeight = [message boundingRectWithSize:CGSizeMake(messageWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:Layout(14)]}context:nil].size.height + Layout(10);
        
        UILabel *messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, messageWidth, messageHeight)];
        messageLabel.textColor = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1];
        messageLabel.font = [UIFont systemFontOfSize:Layout(14)];
        messageLabel.text = message;
        
        return messageLabel;
        
    } ClickAction:clickBlock];
}

/**
 *  显示alertView
 */
- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self needsDisplay];
        /*UIWindow *window = ((UIWindow *)[[UIApplication sharedApplication] windows][0]);*/
        UIWindow *window = ((UIWindow *)[UIApplication sharedApplication].keyWindow);
        [window addSubview:self];
        [window endEditing:YES];
        [self performPresentationAnimation];
    });
}

/**
 *  隐藏AlertView
 */
- (void)dismiss {
    [self removeFromSuperview];
}

/**
 *  点击空白处,收键盘
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (self.isIgnoreClose) {
        
        [self dismiss];
    }
}

/**
 *  显示动画
 */
- (void)performPresentationAnimation {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animation];
    bounceAnimation.duration = 0.3;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:1.05],
                              [NSNumber numberWithFloat:0.98],
                              [NSNumber numberWithFloat:1.0],
                              nil];
    
    [_alertView.layer addAnimation:bounceAnimation forKey:@"transform.scale"];
    [UIView animateWithDuration:0.15 animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    }];
}

CGRect getScreenBounds() {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) &&
        UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGRectMake(0, 0, screenBounds.size.height, screenBounds.size.width);
    }
    return screenBounds;
}
/**
 *  刷新
 */
- (void)needsDisplay {
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = [[[UIApplication sharedApplication].keyWindow subviews] objectAtIndex:0].transform;
        }];
    }
    self.frame = [UIScreen mainScreen].bounds;
    
    CGRect screenBounds = getScreenBounds();
    
    float width = _containView.frame.size.width + Layout(30);
    float height = _containView.frame.size.height;
    
    self.alertView.frame = CGRectMake(0, 0, width, height);
    
    // 2.title
    _titleLabel = [self configTitleStyle];
    _titleLabel.frame = CGRectMake(0, 0, CGRectGetWidth(_alertView.frame), Layout(36));
    [_alertView addSubview:_titleLabel];
    
    _titleLabel.text = titleText;
    
    if (!self.isIgnoreClose) {
        
        UIButton *closeBtn = [self configCloseStyle];
        closeBtn.frame = CGRectMake(CGRectGetWidth(_alertView.frame) - Layout(29), Layout(7), Layout(22), Layout(22));
        
        [closeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        
        [_alertView addSubview:closeBtn];
    }
    
    height += Layout(36);
    
    _containView.frame = CGRectMake(Layout(15), Layout(36), width - Layout(30), height - Layout(36));
    
    [_alertView addSubview:_containView];
    
    if (btnTitleText) {
        
        UIButton *clickBtn = [self configButtonStyle];
        
        clickBtn.frame = CGRectMake(width*(1-0.37f)/2, CGRectGetMaxY(_containView.frame) + Layout(10), width*0.37f, width*0.37f *0.3f);
        [clickBtn setTitle:btnTitleText forState:UIControlStateNormal];
        
        clickBtn.tag = 1000;
        
        [clickBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [_alertView addSubview:clickBtn];
        
        height += width*0.37f *0.3f;
        
        if (otherBtnTitleText) {
            clickBtn.frame = CGRectMake(0.1 * width, CGRectGetMaxY(_containView.frame) + Layout(10), width * 0.37f, width * 0.37f * 0.3);
            UIButton *otherClickBtn = [self configButtonStyle];
            otherClickBtn.frame = CGRectMake(width * (1 - 0.45), CGRectGetMaxY(_containView.frame) + Layout(10), width*0.37f, width*0.35f *0.3f);
            [otherClickBtn setTitle:otherBtnTitleText forState:UIControlStateNormal];
            
            otherClickBtn.tag = 1001;
            
            [otherClickBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];

            [_alertView addSubview:otherClickBtn];
        }
    }
    
    height += Layout(20);
    
    CGRect rect2 = _alertView.frame;
    rect2.size.height = height;
    _alertView.frame = rect2;
    _alertView.center = CGPointMake(screenBounds.size.width/2, screenBounds.size.height/2);
    [_alertView bringSubviewToFront:_containView];
}

- (void)clickAction:(UIButton *)btn {
    
    if (self.clickBlock) {
        
        self.clickBlock(btn.tag - 1000);
    } else {
        
        [self dismiss];
    }
}

- (UILabel *)configTitleStyle;{
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.font = [UIFont boldSystemFontOfSize:Layout(16)];
    label.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    
    return label;
}

- (UIButton *)configCloseStyle;{
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageNamed:@"alert_close_icon"] forState:UIControlStateNormal];
    
    return closeBtn;
}

- (UIButton *)configButtonStyle;{
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

    btn.titleLabel.font = [UIFont systemFontOfSize:Layout(16)];
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    btn.layer.cornerRadius = 2;
    btn.layer.masksToBounds = YES;
    
    btn.backgroundColor = [UIColor colorWithRed:66/255.0 green:211/255.0 blue:249/255.0 alpha:1];
    
    return btn;
}

//页面设置，alert设置放在懒加载里面表示外部可改
- (UIView *)alertView {
    
    if (!_alertView) {
        
        _alertView = [[UIView alloc]init];
        _alertView.layer.cornerRadius = 4;
        _alertView.layer.masksToBounds = YES;
        _alertView.backgroundColor=[UIColor whiteColor];//设置背景颜色
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];//设置背影半透明
        
        [self addSubview:_alertView];
    }
    return _alertView;
}

@end
