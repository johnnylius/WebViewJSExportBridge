//
//  UIWebViewController.m
//  WebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "UIWebViewController.h"
#import "UIWebViewJSExportBridge.h"
#import "WebViewJavaScriptManager.h"

@interface UIWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIWebViewJSExportBridge *bridge;
@property (nonatomic, strong) WebViewJavaScriptManager *manager;

@end

@implementation UIWebViewController

- (void)dealloc {
    [self.bridge removeJSExportObject:@"App"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
    
    self.manager = [[WebViewJavaScriptManager alloc] init];
    [self.bridge bindJSExportObject:@"App" object:(id<JSExport>)self.manager];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIWebViewJSExportBridge *)bridge {
    if (_bridge == nil) {
        _bridge = [UIWebViewJSExportBridge bridgeWithWebView:self.webView];
    }
    return _bridge;
}

@end
