//
//  WKWebViewController.m
//  WebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "SGWebView.h"
#import "RNJavaScriptManager.h"

@interface WKWebViewController ()

@property (nonatomic, strong) SGWebView *webView;
@property (nonatomic, strong) RNJavaScriptManager *manager;

@end

@implementation WKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    Protocol *protocol = objc_getProtocol("SG_JSExport");
//    unsigned count;
//    struct objc_method_description* methods = protocol_copyMethodDescriptionList(protocol, NO, YES, &count);
//    for (unsigned i = 0; i < count; ++i) {
//        SEL sel = methods[i].name;
//        char *types = methods[i].types;
//        //callback(methods[i].name, methods[i].types);
//        NSLog(@"sel = %@, %s", sel, types);
//    }
//
//    free(methods);
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = [[WKPreferences alloc] init];
    config.processPool = [[WKProcessPool alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    
    self.webView = [[SGWebView alloc] initWithFrame:self.view.bounds
                                      configuration:config];
    self.manager = [[RNJavaScriptManager alloc] init];
    [self.webView createWithObject:self.manager];
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

@end
