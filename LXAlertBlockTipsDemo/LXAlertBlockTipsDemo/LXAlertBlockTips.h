//
//  AlertBlockTips.h
//  RssReadNeed
//
//  Created by Xu小波 on 2017/12/12.
//  Copyright © 2017年 Livesxu. All rights reserved.
//

#define kLXScreenWidth [UIScreen mainScreen].bounds.size.width
#define kLXScreenHeight [UIScreen mainScreen].bounds.size.height

#define LXLayout(xxx) [LXAlertBlockTips lxLayout:xxx]
#define kSysFont(xxx,yyy) [LXAlertBlockTips lxLayoutWithSize:xxx weight:yyy]

#define kLXAlertCLDis LXLayout(24) //内容到alert边缘距离
#define kLXAlertLSDis LXLayout(16) //alert到屏幕边缘距离
#define kLXAlertCCDis LXLayout(8) //内容间隔距离
#define kLXAlertClickHeight LXLayout(36) //按钮高度

#import <UIKit/UIKit.h>

typedef void(^ClickBlockAction)(NSInteger index);

typedef void(^ClickDeepStyle)(UIButton *deepButton,NSInteger index);

typedef UIColor *(^ClicksColorBlock)(NSInteger index);

typedef void(^AlertLayoutEndBlock)(void);

@interface LXAlertBlockTips : UIView

@property (nonatomic,   copy) ClickBlockAction clickBlock;///<点击按钮回调

@property (nonatomic,   copy) ClicksColorBlock clicksColorBlock;///<自定义设置按钮颜色

@property (nonatomic,   copy) ClickDeepStyle clickStyleBlock;///<对按钮样式进行自定义

@property (nonatomic,   copy) AlertLayoutEndBlock alertLayoutEndBlock;///<布局完成同步回调

@property (nonatomic, assign) BOOL clicksVertical;///<按钮是否竖排

@property (nonatomic, assign) BOOL clickNotDismiss;///<点击按钮是否消失 默认消失 YES:不消失

@property (nonatomic, assign) BOOL emptyNotDismiss;///<点击空白区是否消失 默认消失 YES：不消失

/**
 alert + title + clicks + custom + clickAction

 @param title 标题
 @param clicks 响应btn
 @param configBlock 配置页面
 @param clickBlock 响应事件
 */
- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                 Config:(UIView *(^)(void))configBlock
            ClickAction:(ClickBlockAction)clickBlock;

/**
 alert + title + message

 @param title 标题
 @param clicks 响应btn
 @param message 文本内容
 @param clickBlock 响应事件
 */
- (void)configWithTitle:(NSString *)title
            ClickTitles:(NSArray *)clicks
                Message:(NSString *)message
            ClickAction:(ClickBlockAction)clickBlock;

/**
 *  显示alertView
 */
- (void)show;

/**
 *  移除alertView
 */
- (void)dismiss;


#pragma mark - 适配,使用类目覆盖

/// 使用比例适配生成的新值，以375为标准适配
/// @param origin 原值
+ (CGFloat)lxLayout:(CGFloat)origin;

/// 字体，字号适配
/// @param size 字号
/// @param fontWeight 字重
+ (UIFont *)lxLayoutWithSize:(CGFloat)size weight:(UIFontWeight)fontWeight;

@end
