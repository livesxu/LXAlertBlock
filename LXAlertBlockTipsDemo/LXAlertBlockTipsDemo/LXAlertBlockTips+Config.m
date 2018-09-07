//
//  LXAlertBlockTips+Config.m
//  LXAlertBlockTipsDemo
//
//  Created by livesxu on 2018/9/7.
//  Copyright © 2018年 Livesxu. All rights reserved.
//

#import "LXAlertBlockTips+Config.h"

@implementation LXAlertBlockTips (Config)

/**
 类目修改配置
 
 @return 放回btn样式
 */
- (UIButton *)configButtonStyle; {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

    btn.layer.cornerRadius = 6;
    btn.layer.masksToBounds = YES;
    
    btn.backgroundColor = [UIColor redColor];
    
    return btn;
}

@end
