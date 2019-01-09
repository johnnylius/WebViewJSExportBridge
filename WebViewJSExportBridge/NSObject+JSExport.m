//
//  NSObject+JSExport.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "NSObject+JSExport.h"
#import "UIWebViewJSExportBridge.h"
#import <objc/runtime.h>

@interface NSObject ()

- (void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id)frame;

@end

@implementation NSObject (JSExport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethodFromSelector:@selector(webView:didCreateJavaScriptContext:forFrame:) toSelector:@selector(js_webView:didCreateJavaScriptContext:forFrame:)];
    });
}

+ (void)swizzleMethodFromSelector:(SEL)originalSelector toSelector:(SEL)swizzledSelector {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        if (originalMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_setImplementation(swizzledMethod, imp_implementationWithBlock(^(id self, SEL _cmd) {}));
        }
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)js_webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id)frame {
    UIWebViewJSExportBridge *bridge = context.UIWebViewJSExportBridge;
    NSObject *webViewObject = webView;
    if (bridge == nil) {
        bridge = webViewObject.UIWebViewJSExportBridge;
    } else {
        webViewObject.UIWebViewJSExportBridge = bridge;
    }
    // 真正开始绑定JS对象
    if ([bridge isKindOfClass:[UIWebViewJSExportBridge class]]) {
        [bridge startBindJSExportObject];
    }
    
    [self js_webView:webView didCreateJavaScriptContext:context forFrame:frame];
}

- (UIWebViewJSExportBridge *)UIWebViewJSExportBridge {
    UIWebViewJSExportBridge *bridge = objc_getAssociatedObject(self, @selector(UIWebViewJSExportBridge));
    return bridge;
}

- (void)setUIWebViewJSExportBridge:(UIWebViewJSExportBridge *)UIWebViewJSExportBridge {
    objc_setAssociatedObject(self, @selector(UIWebViewJSExportBridge), UIWebViewJSExportBridge, OBJC_ASSOCIATION_ASSIGN);
}

@end
