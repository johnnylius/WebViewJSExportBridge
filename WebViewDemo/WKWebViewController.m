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
#import "WebViewJavaScriptManager.h"

@interface WKWebViewController () <WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WebViewJSExportBridge *bridge;
@property (nonatomic, strong) WebViewJavaScriptManager *manager;

@end

@implementation WKWebViewController

- (void)dealloc {
    [self.bridge removeJSExportObject:@"App"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = [[WKPreferences alloc] init];
    config.processPool = [[WKProcessPool alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                      configuration:config];
    self.manager = [[WebViewJavaScriptManager alloc] init];
    self.bridge = [WebViewJSExportBridge bridgeWithWebView:self.webView];
    [self.bridge bindJSExportObject:@"App" object:(id<JSExport>)self.manager];
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
