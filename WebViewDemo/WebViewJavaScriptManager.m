//
//  WebViewJavaScriptManager.m
//  WebViewDemo
//
//  Created by liuhuan on 2018/12/20.
//  Copyright (c) 2018年 Sogou. All rights reserved.
//

#import "WebViewJavaScriptManager.h"
#import "WebViewJSExportBridge.h"

@protocol WebViewTaskJavaScriptExport <JSExport>

@required
// 测试无参数
- (void)testMethod;
// 测试整型参数
- (void)testChar:(char)number;
- (void)testShort:(short)number;
- (void)testInt:(int)number;
- (void)testLong:(long)number;
// 测试浮点型参数
- (void)testFloat:(float)number;
- (void)testDouble:(double)number;
// 测试布尔型参数
- (void)testBOOL:(BOOL)number;
// 测试C字符串参数
- (void)testCString:(const char *)string;
// 测试对象型参数
- (void)testNumber:(NSNumber *)number;
- (void)testString:(NSString *)string;
- (void)testArray:(NSArray *)array;
- (void)testDict:(NSDictionary *)dict;
- (void)testDate:(NSDate *)date;
// 测试布尔型返回值
- (BOOL)returnBOOL;
// 测试整型返回值
- (char)returnChar;
- (short)returnShort;
- (int)returnInt;
- (long)returnLong;
// 测试浮点型返回值
- (float)returnFloat;
- (double)returnDouble;
// 测试C字符串返回值
- (const char *)returnCString;
// 测试对象型返回值
- (NSNumber *)returnNumber;
- (NSString *)returnString;
- (NSArray *)returnArray;
- (NSDictionary *)returnDict;
- (NSDate *)returnDate;
// 测试多参数
- (void)testParam1:(NSString *)param1 param2:(NSString *)param2;
// 测试多参数重命名
JSExportAs(testRename,
- (void)testRenameParam1:(NSString *)param1 param2:(NSString *)param2
);
// 测试回调
- (void)testCallback:(NSString *)callback;

@end

@interface WebViewJavaScriptManager () <WebViewTaskJavaScriptExport>

@end

@implementation WebViewJavaScriptManager

#pragma mark - WebViewTaskJavaScriptExport

#pragma mark - 测试无参数
- (void)testMethod {
    NSLog(@"测试无参数");
    if ([self.delegate respondsToSelector:@selector(testDelegateMethod)]) {
        [self.delegate testDelegateMethod];
    }
}

#pragma mark - 测试整型参数
- (void)testChar:(char)number {
    NSLog(@"测试整型参数 char: %c", number);
}

- (void)testShort:(short)number {
    NSLog(@"测试整型参数 short: %d", number);
}

- (void)testInt:(int)number {
    NSLog(@"测试整型参数 int: %d", number);
}

- (void)testLong:(long)number {
    NSLog(@"测试整型参数 long: %ld", number);
}

#pragma mark - 测试浮点型参数
- (void)testFloat:(float)number {
    NSLog(@"测试浮点型参数 float: %f", number);
}

- (void)testDouble:(double)number {
    NSLog(@"测试浮点型参数 double: %lf", number);
}

#pragma mark - 测试布尔型参数
- (void)testBOOL:(BOOL)number {
    NSLog(@"测试布尔型参数 BOOL: %@", number ? @"YES" : @"NO");
}

#pragma mark - 测试C字符串参数
- (void)testCString:(const char *)string {
    NSLog(@"测试C字符串参数 CString: %s", string);
}

#pragma mark - 测试对象型参数
- (void)testNumber:(NSNumber *)number {
    NSLog(@"测试对象型参数 NSNumber: %@", number);
}

- (void)testString:(NSString *)string {
    NSLog(@"测试对象型参数 NSString: %@", string);
}

- (void)testArray:(NSArray *)array {
    NSLog(@"测试对象型参数 NSArray: %@", array);
}

- (void)testDict:(NSDictionary *)dict {
    NSLog(@"测试对象型参数 NSDictionary: %@", dict);
}

- (void)testDate:(NSDate *)date {
    NSLog(@"测试对象型参数 NSDate: %@", date);
}

#pragma mark - 测试布尔型返回值
- (BOOL)returnBOOL {
    return YES;
}

#pragma mark - 测试整型返回值
- (char)returnChar {
    return 'a';
}

- (short)returnShort {
    return SHRT_MAX;
}

- (int)returnInt {
    return INT_MAX;
}

- (long)returnLong {
    return LONG_MAX;
}

#pragma mark - 测试浮点型返回值
- (float)returnFloat {
    return FLT_MAX;
}

- (double)returnDouble {
    return DBL_MAX;
}

#pragma mark - 测试C字符串返回值
- (const char *)returnCString {
    return "testCString";
}

#pragma mark - 测试对象型返回值
- (NSNumber *)returnNumber {
    return @(100);
}

- (NSString *)returnString {
    return @"testString";
}
- (NSArray *)returnArray {
    return @[@"string", @(3.14), @(10), @(YES)];
}

- (NSDictionary *)returnDict {
    return @{@"number":@(123), @"bool":@(YES), @"string":@"text"};
}

- (NSDate *)returnDate {
    return [NSDate date];
}

#pragma mark - 测试多参数
- (void)testParam1:(NSString *)param1 param2:(NSString *)param2 {
    NSLog(@"测试多参数: %@", NSStringFromSelector(_cmd));
}

#pragma mark - 测试多参数重命名
- (void)testRenameParam1:(NSString *)param1 param2:(NSString *)param2 {
    NSLog(@"测试多参数重命名: %@", NSStringFromSelector(_cmd));
}

#pragma mark - 测试回调
- (void)testCallback:(NSString *)callback {
    WebViewJSExportBridge *bridge = [WebViewJSExportBridge currentBridge];
    NSString *javascript = [NSString stringWithFormat:@"%@(false)", callback];
    [bridge evaluateJavaScript:javascript completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
        NSLog(@"返回结果: %@", result);
    }];
}

@end
