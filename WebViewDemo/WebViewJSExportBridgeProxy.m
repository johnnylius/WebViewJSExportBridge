//
//  WebViewJSExportBridgeProxy.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WebViewJSExportBridgeProxy.h"
#import <objc/runtime.h>

#pragma mark - WebViewJSExportBridgeProxy

@implementation WebViewJSExportBridgeProxy

- (instancetype)initWithTarget:(WebViewJSExportBridge *)target UIDelegate:(id<WKUIDelegate>)UIDelegate {
    _target = target;
    _UIDelegate = UIDelegate;
    return self;
}

+ (instancetype)proxyWithTarget:(id)target {
    return [self proxyWithTarget:target UIDelegate:nil];
}

+ (instancetype)proxyWithTarget:(id)target UIDelegate:(id<WKUIDelegate>)UIDelegate {
    return [[WebViewJSExportBridgeProxy alloc] initWithTarget:target UIDelegate:UIDelegate];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL responds = [_target respondsToSelector:aSelector];
    if (!responds) {
        responds = [_UIDelegate respondsToSelector:aSelector];
    }
    return responds;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if ([_target respondsToSelector:selector]) {
        return _target;
    } else if ([_UIDelegate respondsToSelector:selector]) {
        return _UIDelegate;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

@end
