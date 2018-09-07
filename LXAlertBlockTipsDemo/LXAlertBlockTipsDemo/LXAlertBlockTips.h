//
//  AlertBlockTips.h
//  RssReadNeed
//
//  Created by Xu小波 on 2017/12/12.
//  Copyright © 2017年 Livesxu. All rights reserved.
//

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define Layout(xxx) (xxx)/375.0 *kScreenWidth

#import <UIKit/UIKit.h>

typedef void(^ClickBlockAction)(NSInteger index);

@interface LXAlertBlockTips : UIView {
    
    UILabel *_titleLabel;
}

// alertView
@property (nonatomic, strong) UIView *alertView;

/// 是否忽略关闭按钮 Default is NO
@property (nonatomic, assign) BOOL isIgnoreClose;

@property (nonatomic, strong) UIView *containView;

@property (nonatomic,   copy) ClickBlockAction clickBlock;

/**
 alert + title + clicks + custom + clickAction

 @param title 标题
 @param clicks 响应btn，最多两个
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
 @param clicks 响应btn，最多两个
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

/**
 类目修改配置

 @return 返回titleLabel
 */
- (UILabel *)configTitleStyle;

/**
 类目修改配置

 @return 返回closeBtn
 */
- (UIButton *)configCloseStyle;

/**
 类目修改配置

 @return 放回btn样式
 */
- (UIButton *)configButtonStyle;

@end
