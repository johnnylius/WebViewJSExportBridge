//
//  WKWebView+JSExport.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/17.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WKWebView+JSExport.h"
#import <objc/runtime.h>
#import "WebViewJSExportBridgeProxy.h"

@interface WKWebView ()

@property (nonatomic, strong) WebViewJSExportBridgeProxy *JSExportBridgeProxy;

@end

@implementation WKWebView (JSExport)

+ (void)load {
    [self swizzleWKWebViewMethodFromSelector:@selector(setUIDelegate:) toSelector:@selector(js_setUIDelegate:)];
    [self swizzleWKWebViewMethodFromSelector:@selector(UIDelegate) toSelector: @selector(js_UIDelegate)];
}

+ (void)swizzleWKWebViewMethodFromSelector:(SEL)oriSelector toSelector:(SEL)swSelector {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, oriSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swSelector);
    BOOL didAddMethod = class_addMethod(class, oriSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (id)JSExportBridge {
    return objc_getAssociatedObject(self, @selector(JSExportBridge));
}

- (void)setJSExportBridge:(id)JSExportBridge {
    objc_setAssociatedObject(self, @selector(JSExportBridge), JSExportBridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.UIDelegate = self.UIDelegate;
}

- (WebViewJSExportBridgeProxy *)JSExportBridgeProxy {
    return objc_getAssociatedObject(self, @selector(JSExportBridgeProxy));
}

- (void)setJSExportBridgeProxy:(WebViewJSExportBridgeProxy *)JSExportBridgeProxy {
    objc_setAssociatedObject(self, @selector(JSExportBridgeProxy), JSExportBridgeProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Override Method
- (id<WKUIDelegate>)js_UIDelegate {
    return self.JSExportBridgeProxy.UIDelegate;
}

- (void)js_setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    self.JSExportBridgeProxy = [WebViewJSExportBridgeProxy proxyWithTarget:self.JSExportBridge UIDelegate:UIDelegate];
    
    [self js_setUIDelegate:self.JSExportBridgeProxy];
}


@end
