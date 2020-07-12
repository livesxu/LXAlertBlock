//
//  ViewController.m
//  LXAlertBlockTipsDemo
//
//  Created by livesxu on 2018/9/6.
//  Copyright © 2018年 Livesxu. All rights reserved.
//

#import "ViewController.h"

#import "LXAlertBlockTips.h"
//#import "LXAlertBlockTips+Config.h"

@interface ViewController ()

@property (nonatomic, strong) LXAlertBlockTips *alert;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _alert = [[LXAlertBlockTips alloc]init];
    [_alert configWithTitle:@"提示" ClickTitles:@[@"第一个按钮",@"第二个按钮",@"第三个按钮",@"第四个按钮"] Message:@"我的示例弹窗" ClickAction:nil];
    _alert.clickStyleBlock = ^(UIButton *deepButton, NSInteger index) {
        
        [deepButton setBackgroundColor:[UIColor redColor]];
    };
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [_alert show];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
