//
//  AlertBlockTips.m
//  RssReadNeed
//
//  Created by Xu小波 on 2017/12/12.
//  Copyright © 2017年 Livesxu. All rights reserved.
//

#import "LXAlertBlockTips.h"


@interface LXAlertBlockTips (){
    
    UILabel *_titleLabel;
    
    NSString *titleText;
}

@property (nonatomic, strong) UIScrollView *viewHold;

@property (nonatomic, strong) UIView *alertView;

@property (nonatomic, strong) UIView *containView;

@property (nonatomic, strong) NSArray<NSString *> *clicks;

@property (nonatomic, strong) UIImage *clickBgHighlightedImage;

@property (nonatomic, strong) UIImage *clickBgNomalImage;

@property (nonatomic, strong) UIFont *clickFont;///<按钮字号

@property (nonatomic, assign) CGRect alertFrame;

@property(nullable, nonatomic) UIView *textFieldView;//接受操作弹出的输入对象

@property (nonatomic, strong) NSNotification *willShowNotification;//弹出键盘的willShow通知

@property (nonatomic, assign) BOOL isKbShow;

@end

@implementation LXAlertBlockTips

- (void)dealloc{
    
    [self unregisterAllNotifications];
    NSLog(@"%@ %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        [self registerAllNotifications];
    }
    return self;
}

- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                 Config:(UIView *(^)(void))configBlock
            ClickAction:(ClickBlockAction)clickBlock; {
    
    titleText = title;
    self.clicks = clicks;
    _clickBlock = clickBlock;
    _containView = configBlock();
    
}

- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                Message:(NSString *)message
            ClickAction:(ClickBlockAction)clickBlock;{
    
    __weak typeof(self) weakSelf = self;
    [self configWithTitle:title ClickTitles:clicks Config:^UIView *{
        
        CGFloat messageWidth = weakSelf.width - kLXAlertCLDis - kLXAlertCLDis;
        CGFloat messageHeight = [message boundingRectWithSize:CGSizeMake(messageWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(16, UIFontWeightRegular)}context:nil].size.height;
        
        UILabel *messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, messageWidth, messageHeight)];
        
        messageLabel.font = kSysFont(16, UIFontWeightRegular);
        messageLabel.text = message;
        
        CGFloat onelineHeight = [kSysFont(16, UIFontWeightRegular) lineHeight];
        if ((messageHeight > onelineHeight) || (title && title.length)) {//多余一行或者有标题时靠左
            
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = NSTextAlignmentLeft;
            
        } else {//无标题，仅一行时居中
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageLabel.numberOfLines = 1;
            messageLabel.textAlignment = NSTextAlignmentCenter;
        }
        
        return messageLabel;
        
    } ClickAction:clickBlock];
}

/**
 *  显示alertView
 */
- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self needsDisplay];
        UIWindow *window = [self keyWindow];
        [window addSubview:self];
        [window endEditing:YES];
        
        if (self.alertLayoutEndBlock) {
            
            self.alertLayoutEndBlock();
        }
        [self performPresentationAnimation];
    });
}

/**
 *  隐藏AlertView
 */
- (void)dismiss {
    
    [self endEditing:YES];
    _alertFrame = CGRectZero;
    
    [self removeFromSuperview];
}

/// 超出展示区点击退出弹框
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (_willShowNotification) {
        
        [self endEditing:YES];
        _willShowNotification = nil;//添加一个置空
        return;
    }
    
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self.alertView];
    if (point.x < 0 ||
        point.y < 0 ||
        point.x > self.alertView.frame.size.width ||
        point.y > self.alertView.frame.size.height) {
        
        if (!_emptyNotDismiss) {
            
            [self dismiss];
        }
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

/**
 *  刷新
 */
- (void)needsDisplay {
    
    self.frame = [UIScreen mainScreen].bounds;
    
    float width = self.width;
    float height = _containView.frame.size.height;
    
    if (titleText) {
    
        // title
        _titleLabel = [self configTitleStyle:titleText];
    }
    
    //当内容过长时将支持滑动
    _viewHold = [[UIScrollView alloc]init];
    _viewHold.contentSize = _containView.frame.size;
    [_viewHold addSubview:_containView];
    ///以默认场景，除去状态栏之后的80%，减去顶部间距，标题高度，操作栏间距，操作栏高度，底部间距
    CGFloat maxContainHeight = (kLXScreenHeight - 20)*0.8 - kLXAlertLSDis - (titleText ? (kLXAlertLSDis + _titleLabel.frame.size.height + kLXAlertLSDis) : kLXAlertCLDis) - kLXAlertCCDis - (_clicksVertical ? _clicks.count*(kLXAlertClickHeight + kLXAlertCCDis) : (_clicks.count ? 56 : kLXAlertCLDis)) - kLXAlertLSDis;
    if (height > maxContainHeight) {
        
        height = maxContainHeight;
    }
    
    self.alertView.frame = CGRectMake(0, 0, width, height);
    
    if (titleText) {
        
        [_alertView addSubview:_titleLabel];
        
        height += (kLXAlertLSDis + _titleLabel.frame.size.height + kLXAlertLSDis);
        
        _viewHold.frame = CGRectMake(kLXAlertCLDis, (kLXAlertLSDis + _titleLabel.frame.size.height + kLXAlertLSDis), width - kLXAlertCLDis*2, height - (kLXAlertLSDis + _titleLabel.frame.size.height + kLXAlertLSDis));
        
    } else {//顶部无title则与顶部高度kLXAlertCLDis
        
        height += kLXAlertCLDis;
        
        _viewHold.frame = CGRectMake(kLXAlertCLDis, kLXAlertCLDis, width - kLXAlertCLDis*2, height - kLXAlertCLDis);
    }
    
    [_alertView addSubview:_viewHold];
    
    //内容区与下按钮间隔
    height += kLXAlertCCDis;
    
    //按钮高度56
    if (_clicks && _clicks.count > 0) {
        
        UIButton *clickBtn = [self configButtonStyle:0];
        
        clickBtn.frame = CGRectMake(kLXAlertLSDis, height + kLXAlertCCDis, width - kLXAlertLSDis - kLXAlertLSDis, kLXAlertClickHeight);
        
        [_alertView addSubview:clickBtn];
        
        height += (kLXAlertCCDis + kLXAlertClickHeight + kLXAlertCCDis);//补按钮上间隔、按钮高度、底部下间隔
        
        if (!_clicksVertical) {//横排
            
            //横排按钮到两边的间隔kLXAlertLSDis，按钮间隔kLXAlertCCDis
            CGFloat supportWidth = (self.width - kLXAlertLSDis*2 - (_clicks.count -1)*(kLXAlertCCDis))/_clicks.count;
            
            CGFloat supportX = kLXAlertLSDis;
            
            clickBtn.frame = CGRectMake(supportX, height - kLXAlertClickHeight - kLXAlertCCDis, supportWidth, kLXAlertClickHeight);
            
            for (NSInteger i = 1; i < _clicks.count; i++) {
                
                supportX += (supportWidth + kLXAlertCCDis);
                
                UIButton *otherClickBtn = [self configButtonStyle:i];
                otherClickBtn.frame = CGRectMake(supportX, height - kLXAlertClickHeight - kLXAlertCCDis, supportWidth, kLXAlertClickHeight);
                
                [_alertView addSubview:otherClickBtn];
                
            }
            
        } else {//竖排
            
            for (NSInteger i = 1; i < _clicks.count; i++) {
                
                UIButton *clickBtn = [self configButtonStyle:i];
                       
                clickBtn.frame = CGRectMake(kLXAlertLSDis, height, width - kLXAlertLSDis - kLXAlertLSDis, kLXAlertClickHeight);
                
                [_alertView addSubview:clickBtn];
                
                height += (kLXAlertClickHeight + kLXAlertCCDis);
                
            }
        }
        
    } else {//底部按钮不存在则间距高度kLXAlertCLDis
        
        height += (kLXAlertCLDis - kLXAlertCCDis);
    }
    
    CGRect rect2 = _alertView.frame;
    rect2.size.height = height;
    rect2.origin.x = (kLXScreenWidth - self.width)/2;
    rect2.origin.y = (kLXScreenHeight - height)/2;
    _alertView.frame = rect2;
    [_alertView bringSubviewToFront:_viewHold];
    _alertFrame = rect2;
}

- (void)clickAction:(UIButton *)btn {
    
    if (self.clickBlock) {
        
        self.clickBlock(btn.tag - 1000);
        
        if (!_clickNotDismiss) {//默认点击按钮dismiss
            
            [self dismiss];
        }
    } else {
        
        [self dismiss];
    }
}
///标题样式
- (UILabel *)configTitleStyle:(NSString *)title;{
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor colorWithWhite:0 alpha:1];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = title;
    CGFloat titleWidth = self.width - kLXAlertCLDis*2;
    CGFloat oneLineHeight = [kSysFont(15, UIFontWeightMedium) lineHeight];
    CGFloat currentHeight = [title boundingRectWithSize:CGSizeMake(titleWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(15, UIFontWeightMedium)}context:nil].size.height;
    
    //title超长处理：先逐级缩小字号到15;继续超长，换行处理，支持换一行;最后，“...“截断。
    if (currentHeight > oneLineHeight *2) {//多行 > 2
        label.frame = CGRectMake(kLXAlertCLDis, kLXAlertLSDis, self.width - kLXAlertCLDis*2, oneLineHeight * 2);
        label.font = kSysFont(15, UIFontWeightMedium);
        label.adjustsFontSizeToFitWidth = NO;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.numberOfLines = 2;//最长两行
        
    } else if (currentHeight > oneLineHeight) {//多行 == 2 这时无法确定字号，先确定字号
        
        CGFloat fontxx = 20;
        do {
            CGFloat fontxxOneLineHeight = [kSysFont(fontxx, UIFontWeightMedium) lineHeight];
            CGFloat fontxxCurrentHeight = [title boundingRectWithSize:CGSizeMake(titleWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(fontxx, UIFontWeightMedium)}context:nil].size.height;
            if (fontxxCurrentHeight > fontxxOneLineHeight *2) {
                
                fontxx -= 1;
            } else {
                break;
            }
            
        } while (fontxx > 15);
        
        label.font = kSysFont(fontxx, UIFontWeightMedium);
        label.adjustsFontSizeToFitWidth = NO;
        label.numberOfLines = 2;
        label.frame = CGRectMake(kLXAlertCLDis, kLXAlertLSDis, titleWidth, [kSysFont(fontxx, UIFontWeightMedium) lineHeight] *2);
        
    } else {//一行
        label.frame = CGRectMake(kLXAlertCLDis, kLXAlertLSDis, self.width - kLXAlertCLDis*2, LXLayout(24));
        label.font = kSysFont(20, UIFontWeightMedium);
        label.adjustsFontSizeToFitWidth = YES;
        label.numberOfLines = 1;
    }
    
    return label;
}

///按钮样式
- (UIButton *)configButtonStyle:(NSInteger)index;{
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

    btn.titleLabel.font = self.clickFont;
    [btn setTitleColor:[self defaultClicksColor] forState:UIControlStateNormal];
    
    if (!self.clickBgHighlightedImage) {

        self.clickBgHighlightedImage = [self createImageWithColor:[UIColor colorWithWhite:0 alpha:0.05]];
    }
    if (!self.clickBgNomalImage) {

        self.clickBgNomalImage = [self createImageWithColor:[UIColor colorWithWhite:1 alpha:1]];
    }

    [btn setBackgroundImage:self.clickBgHighlightedImage forState:UIControlStateHighlighted];
    [btn setBackgroundImage:self.clickBgNomalImage forState:UIControlStateNormal];
    
    btn.layer.cornerRadius = kLXAlertClickHeight/2;
    btn.layer.masksToBounds = true;
    
    [btn setTitle:_clicks[index] forState:UIControlStateNormal];
    //自定义颜色
    if (self.clicksColorBlock && self.clicksColorBlock(index)) {
        
        [btn setTitleColor:self.clicksColorBlock(index) forState:UIControlStateNormal];
    }
    
    //自定义样式
    if (self.clickStyleBlock) {
        
        self.clickStyleBlock(btn, index);
    }
    
    btn.tag = 1000 + index;
    
    [btn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)setClicks:(NSArray<NSString *> *)clicks {
    _clicks = clicks;
    
    if (_clicks && _clicks.count > 1 && _clicksVertical == NO) {//表示有按钮同时按钮没有强制竖排，那么需要计算横排字号和是否需要改为竖排
        
        if (_clicks.count > 3) {//大于三个按钮直接竖排
            
            _clicksVertical = YES;
            self.clickFont = kSysFont([self planVerticalClicksFontSize], UIFontWeightMedium);
            return;
        }
        
        CGFloat fontSize = [self planHorizontalClicksFontSize];
        
        if (fontSize < 9) {//最小为9，则改为竖排
            
            _clicksVertical = YES;
            
            self.clickFont = kSysFont([self planVerticalClicksFontSize], UIFontWeightMedium);
            return;
            
        } else {
            
            self.clickFont = kSysFont(fontSize, UIFontWeightMedium);
        }
        
        
    } else if (_clicks.count == 1 || _clicksVertical == YES) {//如果只有一个按钮或者确定竖排
        
        self.clickFont = kSysFont([self planVerticalClicksFontSize], UIFontWeightMedium);
        return;
        
    } else {
        
        self.clickFont = kSysFont(kLXAlertLSDis, UIFontWeightMedium);
    }
}

/// 计算横排按钮文字字号
- (CGFloat)planHorizontalClicksFontSize {
    
    //横排按钮到两边的间隔kLXAlertLSDis，按钮间隔kLXAlertCCDis，按钮中文字到边沿kLXAlertCCDis(横排把边沿加上，抵着边沿会比较难看)
    //默认字号 16
    NSString *clicksString = @"";//拿到最长的那个子串，它决定了字号大小
    CGFloat fontxx = 16;
    CGFloat fontxxMaxWidth = 0;
    for (NSInteger i = 0; i < _clicks.count; i++) {
        
        CGFloat fontxxCurrentWidth = [_clicks[i] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(fontxx, UIFontWeightMedium)}context:nil].size.width;
        
        if (fontxxMaxWidth < fontxxCurrentWidth) {//拿到最长的那个按钮文字
            
            fontxxMaxWidth = fontxxCurrentWidth;
            clicksString = _clicks[i];
        }
    }
    
    CGFloat supportWidth = (self.width - kLXAlertLSDis*2 - (_clicks.count -1)*(kLXAlertCCDis) - _clicks.count*kLXAlertCCDis*2)/_clicks.count;
    
    do {
        CGFloat fontxxCurrentWidth = [clicksString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(fontxx, UIFontWeightMedium)}context:nil].size.width;
        if (fontxxCurrentWidth > supportWidth) {
            
            fontxx -= 1;
        } else {
            break;
        }
        
    } while (fontxx > 8);
    
    return fontxx;
}

/// 计算竖排按钮文字字号
- (CGFloat)planVerticalClicksFontSize {
    
    //竖排按钮到两边的间隔kLXAlertLSDis
    //默认字号 kLXAlertLSDis
    NSString *clicksString = @"";//拿到最长的那个子串，它决定了字号大小
    CGFloat fontxx = 16;
    CGFloat fontxxMaxWidth = 0;
    for (NSInteger i = 0; i < _clicks.count; i++) {
        
        CGFloat fontxxCurrentWidth = [_clicks[i] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(fontxx, UIFontWeightMedium)}context:nil].size.width;
        
        if (fontxxMaxWidth < fontxxCurrentWidth) {//拿到最长的那个按钮文字
            
            fontxxMaxWidth = fontxxCurrentWidth;
            clicksString = _clicks[i];
        }
    }
     
    CGFloat supportWidth = self.width - kLXAlertLSDis*2;
    
    do {
        CGFloat fontxxCurrentWidth = [clicksString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kSysFont(fontxx, UIFontWeightMedium)}context:nil].size.width;
        if (fontxxCurrentWidth > supportWidth) {
            
            fontxx -= 1;
        } else {
            break;
        }
        
    } while (fontxx > 9);
    
    return fontxx;//kSysFont(fontxx, UIFontWeightMedium);
}

- (UIView *)alertView {
    
    if (!_alertView) {
        
        _alertView = [[UIView alloc]init];
        _alertView.layer.cornerRadius = kLXAlertLSDis;
        _alertView.layer.masksToBounds = YES;
        _alertView.backgroundColor=[UIColor whiteColor];//设置背景颜色
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];//设置背影半透明
        
        [self addSubview:_alertView];
    }
    return _alertView;
}

- (CGFloat)width {
    
    return kLXScreenWidth - kLXAlertLSDis - kLXAlertLSDis;
}

- (UIImage*)createImageWithColor:(UIColor*)color {

    CGRect rect= CGRectMake(0,0,1,1);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGContextFillRect(context, rect);
    
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return colorImage;
}

- (UIColor *)defaultClicksColor {
    
    if (@available(iOS 10.0, *)) {//支持P3色域
        return [UIColor colorWithDisplayP3Red:0.0f/255.0f green:125.0f/255.0f blue:255.0f/255.0f alpha:1];
    }else {
        return [UIColor colorWithRed:0.0f/255.0f green:125.0f/255.0f blue:255.0f/255.0f alpha:1];
    }
}

#pragma mark - input control
- (BOOL)judgeCurrentAlert {
    
    if (self.window) {
        
        return YES;
    }
    return NO;
}

- (void)registerAllNotifications
{
    //  Registering for keyboard notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //  Registering for UITextField notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:nil];
   
    //  Registering for UITextView notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    
}

- (void)unregisterAllNotifications
{
    //  Unregistering for keyboard notification.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];

    //  Unregistering for UITextField notification.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidEndEditingNotification object:nil];
    
    //  Unregistering for UITextView notification.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    
}

- (void)textFieldViewDidBeginEditing:(NSNotification*)notification
{
    if (![self isNotiResponse]) return;
    
    //  Getting object
    _textFieldView = notification.object;
    
    if (_textFieldView && _willShowNotification) {
        
        //使用延时在于解决三方键盘在键盘弹出时出现的首次二次动画无法调用情况
        [self performSelector:@selector(adjustAlertWithKb) withObject:nil afterDelay:0.01f];
//        [self adjustAlertWithKb];
    }
}

- (void)textFieldViewDidEndEditing:(NSNotification*)notification
{
    if (![self isNotiResponse]) return;
    
    _textFieldView = nil;
    _willShowNotification = nil;
    
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    if (![self isNotiResponse]) return;
    
    _willShowNotification = aNotification;
    
    if (_textFieldView && _willShowNotification) {
        
        //使用延时在于解决三方键盘在键盘弹出时出现的首次二次动画无法调用情况
        [self performSelector:@selector(adjustAlertWithKb) withObject:nil afterDelay:0.01f];
//        [self adjustAlertWithKb];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification {
    
    if (![self isNotiResponse]) return;
        
        if (_textFieldView && _willShowNotification && _isKbShow) {
            
            CGRect kbFrame = [[aNotification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
            
            CGRect rect2 = self.alertFrame;
            rect2.origin.y -= kbFrame.size.height;
            self.alertView.frame = rect2;
        }
}

/// 根据键盘调整alert的位置
- (void)adjustAlertWithKb {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (!self) return;
    
    NSNotification *aNotification = _willShowNotification;
    CGRect kbFrame = [[aNotification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect inputRect = [_textFieldView.superview convertRect:_textFieldView.frame toView:[self keyWindow]];
    
    //发生遮挡
    if (kbFrame.origin.y < (inputRect.origin.y + inputRect.size.height)) {
        
        NSInteger curve = [[aNotification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
        curve = curve<<16;
        
        CGFloat duration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0 options:(curve|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            
            __strong __typeof__(self) strongSelf = weakSelf;
            
            CGRect rect2 = strongSelf.alertFrame;
            rect2.origin.y -= kbFrame.size.height;
            strongSelf.alertView.frame = rect2;
            
        } completion:^(BOOL finished) {
            
            __strong __typeof__(self) strongSelf = weakSelf;
            
            strongSelf.isKbShow = YES;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    if (![self isNotiResponse]) return;
    
    NSInteger curve = [[aNotification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    curve = curve<<16;
    
    CGFloat duration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration delay:0 options:(curve|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.alertView.frame = strongSelf.alertFrame;
        
    } completion:^(BOOL finished) {
        
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.isKbShow = NO;
    }];
}


/// 是否响应通知 - 在异常场景下，比如未销毁，只创建未弹出，未展示，多个alert等情况下，不响应通知事件
- (BOOL)isNotiResponse {
    
    if (_alertView && self.window && !CGRectEqualToRect(_alertFrame, CGRectZero)) {
        
        return YES;
    }
    return NO;
}

- (UIWindow *)keyWindow
{
    UIWindow *originalKeyWindow = nil;

    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        originalKeyWindow = window;
                        break;
                    }
                }
            }
        }
    } else
    #endif
    {
    #if __IPHONE_OS_VERSION_MIN_REQUIRED < 130000
        originalKeyWindow = [UIApplication sharedApplication].keyWindow;
    #endif
    }
    return originalKeyWindow;
}

#pragma mark - 适配
+ (CGFloat)lxLayout:(CGFloat)origin; {
    
    return ((origin)/375.0 *kLXScreenWidth);
}

+ (UIFont *)lxLayoutWithSize:(CGFloat)size weight:(UIFontWeight)fontWeight; {
    
    return [UIFont systemFontOfSize:LXLayout(size) weight:fontWeight];
}

@end
