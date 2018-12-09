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
window.syncGetValue = function (objectName, methodName, param) {\
    var object = {\
        'objectName':objectName,\
        'methodName':methodName,\
        'parameter':param\
    };\
    var str = window.prompt('syncGetValue', JSON.stringify(object));\
    var json = JSON.parse(str);\
    var date = new Date(json.date);\
    return json.return;\
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
    return window.syncGetValue('App', '%@', param);\
};\
";

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
    Protocol *exportProtocol = objc_getProtocol("JSExport");
    
    forEachProtocolImplementingProtocol([object class], exportProtocol, ^(Protocol *protocol) {
        NSMutableDictionary *renameDict = createRenameMap(protocol, YES);
        NSMutableDictionary *methodDict = [NSMutableDictionary dictionary];
        forEachMethodInProtocol(protocol, YES, YES, ^(SEL sel, const char *types) {
            NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:sel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            invocation.target = object;
            invocation.selector = sel;
            
            NSString *selectorName = NSStringFromSelector(sel);
            NSString *methodName = renameDict[selectorName];
            if (methodName == nil) {
                methodName = selectorToPropertyNameTemp(selectorName);
            }
            methodDict[methodName] = invocation;
            
            [script appendString:[self createScriptWithMethod:methodSignature method:methodName]];
        });
        self.selectorDict[@"App"] = methodDict;
    });
    
    if (script.length > 0) {
        [self addUserScript:script name:@"receiveMethod"];
    }
    self.object = object;
}

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

#pragma mark - Private Method
void forEachProtocolImplementingProtocol(Class cls, Protocol *target, void (^callback)(Protocol *))
{
//    ASSERT(cls);
//    ASSERT(target);
    
//    Vector<Protocol *> worklist;
//    HashSet<void*> visited;
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

bool protocolImplementsProtocol(Protocol *candidate, Protocol *target)
{
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

static NSMutableDictionary *createRenameMap(Protocol *protocol, BOOL isInstanceMethod)
{
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

void forEachMethodInProtocol(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, void (^callback)(SEL, const char*))
{
    unsigned count;
    struct objc_method_description* methods = protocol_copyMethodDescriptionList(protocol, isRequiredMethod, isInstanceMethod, &count);
    for (unsigned i = 0; i < count; ++i)
        callback(methods[i].name, methods[i].types);
    free(methods);
}

NSString *selectorToPropertyName(const char* start)
{
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

NSString *selectorToPropertyNameTemp(NSString *selector) {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSArray *arrry = [selector componentsSeparatedByString:@":"];
    [result appendString:arrry.firstObject];
    for (int i = 1; i < arrry.count; i++) {
        NSString *string = [arrry[i] capitalizedString];
        [result appendString:string];
    }
    return result;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *method = message.body[@"methodName"];
    NSArray *params = message.body[@"parameter"];
    NSInvocation *invocation = self.selectorDict[@"App"][method];
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
    NSData *data = [defaultText dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSString *method = dict[@"methodName"];
    NSArray *params = dict[@"parameter"];
    NSInvocation *invocation = self.selectorDict[@"App"][method];
    [params enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        [invocation setArgument:&arg atIndex:idx+2];
    }];
    [invocation invoke];
    
    NSString *returnJson = nil;
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
    const char *returnType = invocation.methodSignature.methodReturnType;
    if (*returnType == _C_ID) {
        id returnValue = nil;
        [invocation getReturnValue:&returnValue];
        returnDict[@"return"] = returnValue;
    }
    
    returnDict[@"dict"] = @{@"number":@(123), @"bool":@(YES), @"string":@"text"};
    
    NSDate *date = [NSDate date];
    returnDict[@"date"] = date.description;
    returnDict[@"number"] = @(YES);
    
    JSContext *context = [[JSContext alloc] init];
    JSValue *value = [JSValue valueWithObject:date inContext:context];
    NSArray *array = [NSArray arrayWithObjects:@(1), @"2", @(3.14), @(NO), nil];
    returnDict[@"date"] = [value toString];
    returnDict[@"array"] = array;
    //returnJson = @"{\"date\":\"2018-12-09T17:40:00Z\"}";
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
    returnJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    completionHandler(returnJson);
}

#pragma mark - Getter and Setter
- (NSMutableDictionary *)selectorDict {
    if (_selectorDict == nil) {
        _selectorDict = [[NSMutableDictionary alloc] init];
    }
    return _selectorDict;
}

@end
