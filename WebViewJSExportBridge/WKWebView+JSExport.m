//
//  WKWebView+JSExport.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/17.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WKWebView+JSExport.h"
#import "WebViewJSExportBridgeProxy.h"
#import <objc/runtime.h>

@interface WKWebView ()

@property (nonatomic, strong) WebViewJSExportBridgeProxy *WebViewJSExportBridgeProxy;

@end

@implementation WKWebView (JSExport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethodFromSelector:@selector(setUIDelegate:) toSelector:@selector(js_setUIDelegate:)];
        [self swizzleMethodFromSelector:@selector(UIDelegate) toSelector: @selector(js_UIDelegate)];
    });
}

+ (void)swizzleMethodFromSelector:(SEL)originalSelector toSelector:(SEL)swizzledSelector {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (id)WebViewJSExportBridge {
    return self.WebViewJSExportBridgeProxy.target;
}

- (void)setWebViewJSExportBridge:(id)WebViewJSExportBridge {
    self.WebViewJSExportBridgeProxy = [WebViewJSExportBridgeProxy proxyWithTarget:WebViewJSExportBridge UIDelegate:self.UIDelegate];
    self.UIDelegate = self.UIDelegate;
}

- (WebViewJSExportBridgeProxy *)WebViewJSExportBridgeProxy {
    return objc_getAssociatedObject(self, @selector(WebViewJSExportBridgeProxy));
}

- (void)setWebViewJSExportBridgeProxy:(WebViewJSExportBridgeProxy *)WebViewJSExportBridgeProxy {
    objc_setAssociatedObject(self, @selector(WebViewJSExportBridgeProxy), WebViewJSExportBridgeProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Override Method
- (id<WKUIDelegate>)js_UIDelegate {
    return self.WebViewJSExportBridgeProxy.UIDelegate;
}

- (void)js_setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    self.WebViewJSExportBridgeProxy = [WebViewJSExportBridgeProxy proxyWithTarget:self.WebViewJSExportBridge UIDelegate:UIDelegate];
    
    [self js_setUIDelegate:self.WebViewJSExportBridgeProxy];
}


@end
