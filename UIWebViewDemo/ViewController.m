//
//  ViewController.m
//  UIWebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "ViewController.h"
#import "UIWebViewController.h"
#import "WKWebViewController.h"

@interface ViewController ()

@property (nonatomic, strong) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.textField.text = @"https://yaokan.shida.sogou.com/homepage/index.html?user_id=8466533&invite_code=8f2861&pf=iOS&appid=7747&simplejson=1&phone=1&h=6106B337-355F-4F4A-92BE-FBED09C4004F&machineType=iPhone%20Simulator&api=7&v=1.0.0&sys=iOS&pkg=com.sogou.yaokantest&idfa=3F909F56-1869-44B4-A5DC-46A49252C689&task_id=39#invite_code";
    
//    self.textField.text = @"http://10.129.148.198/yaokan/app-jtyk/trunk/build/index.html?invite_code=%E6%9A%82%E6%97%B6%E6%B2%A1%E6%9C%89&user_id=45645&task_id=#invite_code";
    
    self.textField.text = @"http://10.129.148.198/yaokan/app-jtyk/trunk/build/index.html?user_id=8466533&invite_code=8f2861&pf=iOS&appid=7747&simplejson=1&phone=1&h=6106B337-355F-4F4A-92BE-FBED09C4004F&machineType=iPhone%20Simulator&api=7&v=1.0.0&sys=iOS&pkg=com.sogou.yaokantest&idfa=3F909F56-1869-44B4-A5DC-46A49252C689&task_id=39#invite_code";
    
    //self.textField.text = @"http://10.129.148.198/yaokan/app-jtyk/trunk/build/index.html?user_id=8466533&invite_code=8f2861&pf=iOS&appid=7747&simplejson=1&phone=1&h=6106B337-355F-4F4A-92BE-FBED09C4004F&machineType=iPhone%20Simulator&api=7&v=1.0.0&sys=iOS&pkg=com.sogou.yaokantest&idfa=3F909F56-1869-44B4-A5DC-46A49252C689&task_id=43#invite";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clearButtonClick:(id)sender {
    self.textField.text = @"";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UIWebView"]) {
        UIWebViewController *controller = segue.destinationViewController;
        controller.url = [NSURL URLWithString:self.textField.text];
    } else if ([segue.identifier isEqualToString:@"WKWebView"]) {
        WKWebViewController *controller = segue.destinationViewController;
        controller.url = [NSURL URLWithString:self.textField.text];
    }
}


@end
