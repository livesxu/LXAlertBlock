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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    LXAlertBlockTips *alert = [[LXAlertBlockTips alloc]init];
    [alert configWithTitle:@"提示" ClickTitles:@[@"取消",@"确定"] Message:@"我的示例弹窗" ClickAction:nil];
    
    [alert show];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
