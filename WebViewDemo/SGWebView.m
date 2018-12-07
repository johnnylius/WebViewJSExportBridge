//
//  SGWebView.m
//  SGWebView
//
//  Created by Johnny on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "SGWebView.h"
#import "RNJavaScriptManager.h"
#import <objc/runtime.h>

@interface SGWebView () <WKScriptMessageHandler, WKUIDelegate>

@property (nonatomic, strong) NSMutableDictionary *selectorDict;
@property (nonatomic, strong) NSObject *object;

@end

@implementation SGWebView

static NSString *const kCommonScript = @"\
window.App = window.App || {};\
window.App.checkWebkit = function () {\
    var flag = true;\
    var webkit = window.webkit;\
    if (webkit == undefined) {\
        flag = false;\
    }\
    return flag;\
};\
window.appWebKit = true;\
window.App.construct = function (objectName,methodName,param) {\
    var object = {\
        'objectName':objectName,\
        'methodName':methodName,\
        'parameter':param\
    };\
    if (window.appWebKit) {\
        window.webkit.messageHandlers.receiveMethod.postMessage(object);\
    } else {\
        window.SGBridge.receiveMethod(object);\
    }\
};\
window.App.syncGetValue = function (objectName, methodName, param) {\
    var object = {\
        'objectName':objectName,\
        'methodName':methodName,\
        'parameter':param\
    };\
    return window.prompt('syncGetValue', JSON.stringify(object));\
};\
";

static NSString *const kReturnVoidTemplateScript = @"\
window.App.%@ = function(%@) {\
    var param = [\
        %@\
    ];\
    window.App.construct('App','%@',param);\
};\
";

static NSString *const kReturnValueTemplateScript = @"\
window.App.%@ = function(%@) {\
    var param = [\
        %@\
    ];\
    return window.prompt('%@', param);\
};\
";

//NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
//                            [self methodSignatureForSelector:
//                             @selector(drawViewHierarchyInRect:afterScreenUpdates:)]];
//[invocation setTarget:self];
//[invocation setSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)];
//CGRect arg2 = view.bounds;
//BOOL arg3 = YES;
//[invocation setArgument:&arg2 atIndex:2];
//[invocation setArgument:&arg3 atIndex:3];
//[invocation invoke];



const char *_protocol_getMethodTypeEncoding(Protocol *, SEL, BOOL isRequiredMethod, BOOL isInstanceMethod);

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self addUserScript:kCommonScript name:@"CommonScript"];
        super.UIDelegate = self;
    }
    return self;
}

//- (instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self addUserScript:kCommonScript name:@"CommonScript"];
//    }
//    return self;
//}

- (void)createWithObject:(NSObject *)object {
    NSMutableString *script = [[NSMutableString alloc] init];
    unsigned protocolsCount;
    __unsafe_unretained Protocol ** protocols = class_copyProtocolList([object class], &protocolsCount);
    for (unsigned i = 0; i < protocolsCount; ++i) {
        Protocol *protocol = protocols[i];
        unsigned count;
        struct objc_method_description* methods = protocol_copyMethodDescriptionList(protocol, YES, YES, &count);
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (unsigned j = 0; j < count; ++j) {
            SEL selector = methods[j].name;
            char *types = methods[j].types;
            NSLog(@"sel = %@, %s", NSStringFromSelector(selector), types);
            
            NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:selector];
            if (methodSignature.numberOfArguments > 2) {
                const char *str = [methodSignature getArgumentTypeAtIndex:2];
                str = nil;
            }
            
            
            NSString *methodName = NSStringFromSelector(selector);
            NSRange range = [methodName rangeOfString:@":"];
            if (range.location != NSNotFound) {
                methodName = [methodName substringToIndex:range.location];
            }
            dict[methodName] = NSStringFromSelector(selector);
            
            [script appendString:[self createScriptWithMethod:methodSignature method:methodName]];
            

        }
        self.selectorDict[@"App"] = dict;
    }
    if (script.length > 0) {
        //[script insertString:kCommonScript atIndex:0];
        
        [self addUserScript:script name:@"receiveMethod"];
    }
    self.object = object;
}

- (NSString *)filterNumber:(NSString *)types {
    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < types.length; i++) {
        char c = [types characterAtIndex:i];
        if (!isnumber(c)) {
            NSString *str = [NSString stringWithFormat:@"%c", c];
            [string appendString:str];
        }
    }
    return string;
}

//- (NSString *)createScript:(NSString *)types {
//    NSMutableString *args = [NSMutableString string];
//    NSMutableString *params = [NSMutableString string];
//    types = [types substringFromIndex:3];
//    for (int i = 0; i < types.length; i++) {
//        NSString *arg = [NSString stringWithFormat:@"arg%d,", i];
//        [args appendString:arg];
//        NSString *param = [NSString stringWithFormat:@"\"param%d\":arg%d,", i, i];
//        [params appendString:param];
//    }
//
//    if (types.length > 0) {
//        [args deleteCharactersInRange:NSMakeRange(args.length-1, 1)];
//        [params deleteCharactersInRange:NSMakeRange(params.length-1, 1)];
//    }
//
//    NSString *script = [NSString stringWithFormat:kReturnVoidTemplateScript, args, params];
//
//    return @"";
//}

- (NSString *)createScriptWithMethod:(NSMethodSignature *)methodSignature method:method {
    NSMutableString *args = [NSMutableString string];
    for (int i = 2; i < methodSignature.numberOfArguments; i++) {
        NSString *arg = [NSString stringWithFormat:@"arg%d,", i-2];
        [args appendString:arg];
    }
    
    if (methodSignature.numberOfArguments > 2) {
        [args deleteCharactersInRange:NSMakeRange(args.length-1, 1)];
    }
    
    NSString *template = @"";
    if (*methodSignature.methodReturnType == _C_VOID) {
        template = kReturnVoidTemplateScript;
    } else {
        template = kReturnValueTemplateScript;
    }
    
    NSString *script = [NSString stringWithFormat:template, method, args, args, method];
    
    return script;
}


- (void)addUserScript:(NSString *)source name:(NSString *)name {
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    WKWebViewConfiguration *config = self.configuration;
    [config.userContentController addUserScript:script];
    [config.userContentController addScriptMessageHandler:self name:name];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *method = message.body[@"methodName"];
    NSArray *params = message.body[@"parameter"];
    NSString *selectorString = self.selectorDict[@"App"][method];
    SEL selector = NSSelectorFromString(selectorString);
    
    NSMethodSignature *methodSignature = [self.object methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self.object];
    [invocation setSelector:selector];
    [params enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        [invocation setArgument:&arg atIndex:idx+2];
    }];
    [invocation invoke];
    
//    if ([method isEqualToString:@"SendMessage"]) {
//        NSString *name = dict[@"name"];
//        NSString *content = dict[@"content"];
//        NSString *callback = dict[@"callback"];
//        [self newsDetailSendMessageWithName:name content:content callBack:callback];
//    } else if ([method isEqualToString:@"getData"]) {
//        NSString *key = dict[@"key"];
//        [self newsContentForKey:key];
//    }
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
//    NSString *json = nil;
//    if ([prompt isEqualToString:SyncGetValueMethodName]) {
//        NSDictionary *dict = [defaultText jsonValueDecoded];
//        NSString *class = dict[@"className"];
//        NSString *method = dict[@"methodName"];
//        NSDictionary *param = dict[@"parameter"];
//        if ([method isEqualToString:@"getData"]) {
//            NSString *key = param[@"key"];
//            json = [self newsContentForKey:key];
//        }
//    }
//    completionHandler(json);
    completionHandler(@"");
}

#pragma mark - Getter and Setter
- (NSMutableDictionary *)selectorDict {
    if (_selectorDict == nil) {
        _selectorDict = [[NSMutableDictionary alloc] init];
    }
    return _selectorDict;
}

@end
