//
//  UIWebViewJSExportBridge.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "UIWebViewJSExportBridge.h"
#import "WebViewJSExportBridgeProxy.h"
#import "NSObject+JSExport.h"

@interface UIWebViewJSExportBridge ()

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) NSMapTable *objectTable;
@property (nonatomic, strong) JSContext *context;

@end

@implementation UIWebViewJSExportBridge

- (instancetype)initWithWebView:(UIWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
    }
    return self;
}

- (void)dealloc {
    [self removeAllJSExportObject];
}

#pragma mark - Public Method
+ (instancetype)bridgeWithWebView:(UIWebView *)webView {
    return [[self alloc] initWithWebView:webView];
}

- (void)bindJSExportObject:(NSString *)name object:(NSObject<JSExport> *)object {
    if (self.objectTable.count == 0) {
        [self createJavaScriptContext];
    }
    
    [self.objectTable setObject:object forKey:name];
}

- (void)removeJSExportObject:(NSString *)name {
    self.context[name] = nil;
    [self.objectTable removeObjectForKey:name];
    if (self.objectTable.count == 0) {
        [self removeAllJSExportObject];
    }
}

- (void)removeAllJSExportObject {
    for (NSString *name in self.objectTable.keyEnumerator) {
        self.context[name] = nil;
    }
    [self.objectTable removeAllObjects];
    self.UIWebViewJSExportBridge = nil;
    self.context = nil;
}

- (void)startBindJSExportObject {
    for (NSString *name in self.objectTable.keyEnumerator) {
        id object = [self.objectTable objectForKey:name];
        self.context[name] = [WebViewJSExportBridgeProxy proxyWithTarget:object];
    }
}

+ (instancetype)currentBridge {
    JSContext *context = [JSContext currentContext];
    return context.UIWebViewJSExportBridge;
}

- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    JSValue *value = [self.context evaluateScript:script];
    id result = [value toObject];
    completionHandler(result, nil);
}

#pragma mark - Private Method
- (void)createJavaScriptContext {
    NSString *javaScriptContext = @"documentView.webView.mainFrame.javaScriptContext";
    self.context = [self.webView valueForKeyPath:javaScriptContext];
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception){
        context.exception = exception;
        NSLog(@"JSContext Error: %@", exception);
    };
    self.context.UIWebViewJSExportBridge = self;
}

#pragma mark - Getter and Setter
- (NSMapTable *)objectTable {
    if (_objectTable == nil) {
        _objectTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _objectTable;
}

@end
