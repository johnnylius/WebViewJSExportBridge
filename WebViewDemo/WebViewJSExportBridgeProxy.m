//
//  WebViewJSExportBridgeProxy.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WebViewJSExportBridgeProxy.h"
#import <objc/runtime.h>

@implementation WebViewJSExportBridgeProxy

- (instancetype)initWithTarget:(id)target UIDelegate:(id<WKUIDelegate>)UIDelegate {
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

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

@end
