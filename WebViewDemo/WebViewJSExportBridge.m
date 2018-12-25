//
//  WebViewJSExportBridge.m
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WebViewJSExportBridge.h"
#import "WebViewJSExportBridgeProxy.h"
#import "WKWebView+JSExport.h"
#import <objc/runtime.h>

#define kMessageHandlerName @"WVJSEB_messageHandler"
#define kSyncGetValueMethodName @"WVJSEB_syncGetValue"

#define kCommonScript @"\
window.WVJSEB_postMessage = function (object,method,param) {\
    var message = {\
        'object':object,\
        'method':method,\
        'param':param\
    };\
    window.webkit.messageHandlers."kMessageHandlerName@".postMessage(message);\
};\
window.WVJSEB_syncGetValue = function (object,method,param) {\
    var message = {\
        'object':object,\
        'method':method,\
        'param':param\
    };\
    var str = window.prompt('"kSyncGetValueMethodName@"', JSON.stringify(message));\
    var json = JSON.parse(str);\
    if (json) {\
        return json.return;\
    } else {\
        return null;\
    }\
};\
"

static NSString *const kDefineObjectScript = @"\
window.%@ = window.%@ || {};\
";

static NSString *const kReturnVoidTemplateScript = @"\
window.%@.%@ = function(%@) {\
    var param = [%@];\
    window.WVJSEB_postMessage('%@','%@',param);\
};\
";

static NSString *const kReturnValueTemplateScript = @"\
window.%@.%@ = function(%@) {\
    var param = [%@];\
    return window.WVJSEB_syncGetValue('%@', '%@', param);\
};\
";

static WebViewJSExportBridge *bridge = nil;

#pragma mark - WebViewJSExportBridge
@interface WebViewJSExportBridge () <WKScriptMessageHandler, WKUIDelegate>

@property (nonatomic, strong) NSMutableDictionary *objectDict;
@property (nonatomic, strong) NSMutableDictionary *methodDict;
@property (nonatomic, weak) WebViewType webView;

@end

@implementation WebViewJSExportBridge

+ (instancetype)bridgeWithWebView:(WebViewType)webView {
    return [[self alloc] initWithWebView:webView];
}

- (instancetype)initWithWebView:(WebViewType)webView {
    self = [super init];
    if (self) {
        _webView = webView;
        if ([webView isKindOfClass:[WKWebView class]]) {
            
        }
    }
    return self;
}

- (void)dealloc {
    [self removeAllJSExportObject];
}

#pragma mark - Public Method
- (void)bindJSExportObject:(NSString *)name object:(NSObject<JSExport> *)object {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    if (self.methodDict.count == 0) {
        [self addWKWebViewMessageHandler];
    }
    
    NSMutableString *script = [NSMutableString stringWithFormat:kDefineObjectScript, name, name];
    Protocol *exportProtocol = objc_getProtocol("JSExport");
    
    forEachProtocolImplementingProtocol([object class], exportProtocol, ^(Protocol *protocol) {
        NSMutableDictionary *renameDict = createRenameMap(protocol, YES);
        NSMapTable *objectTable = self.objectDict[name];
        if (objectTable == nil) {
            objectTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
            self.objectDict[name] = objectTable;
        }
        NSMutableDictionary *methodDict = self.methodDict[name];
        if (methodDict == nil) {
            methodDict = [[NSMutableDictionary alloc] init];
            self.methodDict[name] = methodDict;
        }
        forEachMethodInProtocol(protocol, YES, YES, ^(SEL sel, const char *types) {
            NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:sel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            invocation.target = object;
            invocation.selector = sel;
            
            NSString *selectorName = NSStringFromSelector(sel);
            NSString *methodName = renameDict[selectorName];
            if (methodName == nil) {
                methodName = selectorToPropertyName(sel_getName(sel));
            }
            methodDict[methodName] = invocation;
            [objectTable setObject:object forKey:methodName];
            
            [script appendString:[self createScriptWithSignature:methodSignature objectName:name methodName:methodName]];
        });
    });
    
    if (script.length > 0) {
        [self addUserScript:script];
    }
    
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"bindJSExportObject函数 %f ms", linkTime *1000.0);
}

- (void)removeJSExportObject:(NSString *)name {
    [self.objectDict removeObjectForKey:name];
    [self.methodDict removeObjectForKey:name];
    if (self.methodDict.count == 0) {
        [self removeAllJSExportObject];
    }
}

- (void)removeAllJSExportObject {
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView *wkWebView = self.webView;
        [wkWebView.configuration.userContentController removeScriptMessageHandlerForName:kMessageHandlerName];
        [wkWebView.configuration.userContentController removeAllUserScripts];
        [self.objectDict removeAllObjects];
        [self.methodDict removeAllObjects];
    }
}

- (void)addUserScript:(NSString *)source {
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    WKWebView *wkWebView = self.webView;
    WKWebViewConfiguration *config = wkWebView.configuration;
    [config.userContentController addUserScript:script];
}

+ (instancetype)currentBridge {
    return bridge;
}

- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView *wkWebView = self.webView;
        [wkWebView evaluateJavaScript:script completionHandler:completionHandler];
    } else {
        completionHandler(nil, nil);
    }
}

#pragma mark - Private Method
- (NSString *)createScriptWithSignature:(NSMethodSignature *)methodSignature objectName:(NSString *)objectName methodName:(NSString *)methodName {
    NSMutableString *args = [NSMutableString string];
    for (int i = 2; i < methodSignature.numberOfArguments; i++) {
        NSString *arg = [NSString stringWithFormat:@"arg%d,", i-2];
        [args appendString:arg];
    }
    
    if (methodSignature.numberOfArguments > 2) {
        [args deleteCharactersInRange:NSMakeRange(args.length-1, 1)];
    }
    
    NSString *template = nil;
    if (*methodSignature.methodReturnType == _C_VOID) {
        template = kReturnVoidTemplateScript;
    } else {
        template = kReturnValueTemplateScript;
    }
    NSString *script = [NSString stringWithFormat:template, objectName, methodName, args, args, objectName, methodName];
    return script;
}

void forEachProtocolImplementingProtocol(Class cls, Protocol *target, void (^callback)(Protocol *)) {
    NSMutableArray<Protocol *> *worklist = [NSMutableArray array];
    NSMutableSet<Protocol *> *visited = [NSMutableSet set];

    // Initially fill the worklist with the Class's protocols.
    unsigned protocolsCount;
    __unsafe_unretained Protocol ** protocols = class_copyProtocolList(cls, &protocolsCount);
    NSArray *array = [NSArray arrayWithObjects:protocols count:protocolsCount];
    [worklist addObjectsFromArray:array];
    free(protocols);
    
    while (worklist.count != 0) {
        Protocol *protocol = worklist.lastObject;
        [worklist removeLastObject];
        
        // Are we encountering this Protocol for the first time?
        if ([visited containsObject:protocol])
            continue;
        
        [visited addObject:protocol];
        // If it implements the protocol, make the callback.
        if (protocolImplementsProtocol(protocol, target))
            callback(protocol);
        
        // Add incorporated protocols to the worklist.
        protocols = protocol_copyProtocolList(protocol, &protocolsCount);
        NSArray *array = [NSArray arrayWithObjects:protocols count:protocolsCount];
        [worklist addObjectsFromArray:array];
        free(protocols);
    }
}

bool protocolImplementsProtocol(Protocol *candidate, Protocol *target) {
    unsigned protocolProtocolsCount;
    __unsafe_unretained Protocol ** protocolProtocols = protocol_copyProtocolList(candidate, &protocolProtocolsCount);
    for (unsigned i = 0; i < protocolProtocolsCount; ++i) {
        if (protocol_isEqual(protocolProtocols[i], target)) {
            free(protocolProtocols);
            return true;
        }
    }
    free(protocolProtocols);
    return false;
}

NSMutableDictionary *createRenameMap(Protocol *protocol, BOOL isInstanceMethod) {
    NSMutableDictionary *renameMap = [[NSMutableDictionary alloc] init];
    
    forEachMethodInProtocol(protocol, NO, isInstanceMethod, ^(SEL sel, const char *types){
        NSString *rename = @(sel_getName(sel));
        NSRange range = [rename rangeOfString:@"__JS_EXPORT_AS__"];
        if (range.location == NSNotFound)
            return;
        NSString *selector = [rename substringToIndex:range.location];
        NSUInteger begin = range.location + range.length;
        NSUInteger length = [rename length] - begin - 1;
        NSString *name = [rename substringWithRange:(NSRange){ begin, length }];
        renameMap[selector] = name;
    });
    
    return renameMap;
}

void forEachMethodInProtocol(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, void (^callback)(SEL, const char*)) {
    unsigned count;
    struct objc_method_description* methods = protocol_copyMethodDescriptionList(protocol, isRequiredMethod, isInstanceMethod, &count);
    for (unsigned i = 0; i < count; ++i)
        callback(methods[i].name, methods[i].types);
    free(methods);
}

NSString *selectorToPropertyName(const char* start) {
    NSString *result = nil;
    // Use 'index' to check for colons, if there are none, this is easy!
    const char* firstColon = index(start, ':');
    if (!firstColon)
        return [NSString stringWithUTF8String:start];
    
    // 'header' is the length of string up to the first colon.
    size_t header = firstColon - start;
    // The new string needs to be long enough to hold 'header', plus the remainder of the string, excluding
    // at least one ':', but including a '\0'. (This is conservative if there are more than one ':').
    char* buffer = (malloc(header + strlen(firstColon + 1) + 1));
    // Copy 'header' characters, set output to point to the end of this & input to point past the first ':'.
    memcpy(buffer, start, header);
    char* output = buffer + header;
    const char* input = start + header + 1;
    
    // On entry to the loop, we have already skipped over a ':' from the input.
    while (true) {
        char c;
        // Skip over any additional ':'s. We'll leave c holding the next character after the
        // last ':', and input pointing past c.
        while ((c = *(input++)) == ':');
        // Copy the character, converting to upper case if necessary.
        // If the character we copy is '\0', then we're done!
        if (!(*(output++) = toupper(c)))
            goto done;
        // Loop over characters other than ':'.
        while ((c = *(input++)) != ':') {
            // Copy the character.
            // If the character we copy is '\0', then we're done!
            if (!(*(output++) = c))
                goto done;
        }
        // If we get here, we've consumed a ':' - wash, rinse, repeat.
    }
done:
    result = [NSString stringWithUTF8String:buffer];
    free(buffer);
    return result;
}

- (id)getReturnFromInvocation:(NSInvocation *)invocation {
    NSMethodSignature *methodSignature = invocation.methodSignature;
    NSUInteger length = [methodSignature methodReturnLength];
    if (length == 0) return nil;
    
    char *type = (char *)[methodSignature methodReturnType];
    while (*type == 'r' || // const
           *type == 'n' || // in
           *type == 'N' || // inout
           *type == 'o' || // out
           *type == 'O' || // bycopy
           *type == 'R' || // byref
           *type == 'V') { // oneway
        type++; // cutoff useless prefix
    }
    
#define return_with_number(_type_) \
do { \
_type_ ret; \
[invocation getReturnValue:&ret]; \
return @(ret); \
} while (0)
    
    switch (*type) {
        case 'v': return nil; // void
        case 'B': return_with_number(bool);
        case 'c': return_with_number(char);
        case 'C': return_with_number(unsigned char);
        case 's': return_with_number(short);
        case 'S': return_with_number(unsigned short);
        case 'i': return_with_number(int);
        case 'I': return_with_number(unsigned int);
        case 'l': return_with_number(int);
        case 'L': return_with_number(unsigned int);
        case 'q': return_with_number(long long);
        case 'Q': return_with_number(unsigned long long);
        case 'f': return_with_number(float);
        case 'd': return_with_number(double);
        case '*': return_with_number(const char *);
        case 'D': { // long double
            long double ret;
            [invocation getReturnValue:&ret];
            return [NSNumber numberWithDouble:ret];
        };
            
        case '@': { // id
            __autoreleasing id ret = nil;
            [invocation getReturnValue:&ret];
            return ret;
        };
            
        case '#': { // Class
            __autoreleasing Class ret = nil;
            [invocation getReturnValue:&ret];
            return ret;
        };
            
        default: { // struct / union / SEL / void* / unknown
            const char *objCType = [methodSignature methodReturnType];
            char *buf = calloc(1, length);
            if (!buf) return nil;
            [invocation getReturnValue:buf];
            __autoreleasing NSValue *value = [NSValue valueWithBytes:buf objCType:objCType];
            free(buf);
            return value;
        };
    }
#undef return_with_number
}

- (void)addWKWebViewMessageHandler {
    [self addUserScript:kCommonScript];
    
    WKWebView *wkWebView = self.webView;
    wkWebView.JSExportBridge = self;
    [wkWebView.configuration.userContentController addScriptMessageHandler:(id<WKScriptMessageHandler>)[WebViewJSExportBridgeProxy proxyWithTarget:self] name:kMessageHandlerName];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    bridge = self;
    NSString *object = message.body[@"object"];
    NSString *method = message.body[@"method"];
    NSArray *params = message.body[@"param"];
    NSInvocation *invocation = self.methodDict[object][method];
    NSObject *target = [self.objectDict[object] objectForKey:method];
    // 因为NSInvocation的target是assign的，如果target被销毁，调用时会崩溃
    invocation.target = target;
    [params enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        [invocation setArgument:&arg atIndex:idx+2];
    }];
    [invocation invoke];
    bridge = nil;
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    WKWebView *wkWebView = self.webView;
    if (![prompt isEqualToString:kSyncGetValueMethodName] &&
        [wkWebView.UIDelegate respondsToSelector:_cmd]) {
        [wkWebView.UIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
        return;
    }
    bridge = self;
    NSData *data = [defaultText dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSString *object = dict[@"object"];
    NSString *method = dict[@"method"];
    NSArray *params = dict[@"param"];
    NSInvocation *invocation = self.methodDict[object][method];
    NSObject *target = [self.objectDict[object] objectForKey:method];
    // 因为NSInvocation的target是assign的，如果target被销毁，调用时会崩溃
    invocation.target = target;
    [params enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        [invocation setArgument:&arg atIndex:idx+2];
    }];
    [invocation invoke];
    
    NSString *returnJson = nil;
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
    returnDict[@"return"] = [self getReturnFromInvocation:invocation];
    if ([NSJSONSerialization isValidJSONObject:returnDict]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
        returnJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    completionHandler(returnJson);
    bridge = nil;
}

#pragma mark - Getter and Setter
- (NSMutableDictionary *)methodDict {
    if (_methodDict == nil) {
        _methodDict = [[NSMutableDictionary alloc] init];
    }
    return _methodDict;
}

- (NSMutableDictionary *)objectDict {
    if (_objectDict == nil) {
        _objectDict = [[NSMutableDictionary alloc] init];
    }
    return _objectDict;
}

@end
