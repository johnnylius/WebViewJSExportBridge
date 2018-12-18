//
//  WKWebViewController.m
//  WebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "WebViewJSExportBridge.h"
#import "RNJavaScriptManager.h"

@interface WKWebViewController () <WKUIDelegate>

@property (nonatomic, strong) WebViewJSExportBridge *webViewBridge;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) RNJavaScriptManager *manager;

@end

@implementation WKWebViewController

- (void)dealloc {
    [self.webViewBridge removeJSExportObject:@"App"];
    [self.webViewBridge removeJSExportObject:@"TestApp"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = [[WKPreferences alloc] init];
    config.processPool = [[WKProcessPool alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                      configuration:config];
    self.manager = [[RNJavaScriptManager alloc] init];
    self.webViewBridge = [[WebViewJSExportBridge alloc] initWithWebView:self.webView];
    [self.webViewBridge bindJSExportObject:@"App" object:self.manager];
    [self.webViewBridge bindJSExportObject:@"TestApp" object:self.manager];
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)back {
    if (self.webView.canGoBack) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    completionHandler(nil);
}

@end
