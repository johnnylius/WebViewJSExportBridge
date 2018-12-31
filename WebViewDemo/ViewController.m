//
//  ViewController.m
//  WebViewDemo
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
    
    self.textField.text = @"http://10.144.232.224/yaokan-js.html";
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
