//
//  ViewController.m
//  WKWebView与JS
//
//  Created by ZhangXu on 16/3/23.
//  Copyright © 2016年 zhangXu. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
@interface ViewController ()<WKScriptMessageHandler,WKNavigationDelegate,WKUIDelegate>

@property(nonatomic ,strong)WKWebView *webView;
@property(nonatomic ,strong)UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets  =NO;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    
    //设置偏好
    config.preferences = [[WKPreferences alloc]init];
    //默认为0
    config.preferences.minimumFontSize = 10;
    
    //默认为YES
    config.preferences.javaScriptEnabled = YES;
    
    //在iOS上默认为NO,表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    //web内容处理池
    config.processPool = [[WKProcessPool alloc]init];
    
    //通过JS与webView内容交互
    config.userContentController = [[WKUserContentController alloc]init];
    
    //注入JS对象名称AppModel,当JS通过APPModell来调用时
    //我们可以在WKScriptMessageHandler代理中接收到
    [config.userContentController addScriptMessageHandler:self name:@"AppModel"];
    
    self.webView = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:config];
    
    NSURL *url = [[NSBundle mainBundle]URLForResource:@"text" withExtension:@"html"];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.view addSubview:self.webView];
    
    
    //导航代理
    self.webView.navigationDelegate = self;
    
    //与webView UI交互代理
    self.webView.UIDelegate = self;
    
    // 添加KVO监听
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    //添加进度条
    self.progressView = [[UIProgressView alloc]init];
    self.progressView.frame = self.view.bounds;
    [self.view addSubview:self.progressView];
    self.progressView.backgroundColor = [UIColor redColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"back" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"next" style:UIBarButtonItemStylePlain target:self action:@selector(goNext)];

    // Do any additional setup after loading the view, typically from a nib.
}

-(void)goback{
    
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

-(void)goNext{
    if ([self.webView canGoForward]) {
        [self.webView canGoForward];
    }
}

#pragma mark WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    if ([message.name isEqualToString:@"AppModel"]) {
        //打印所传过来的参数,只支持NSNumber NSString NSDate NSArray NSDictionary NSNUll类型
        NSLog(@"%@",message.body);
    }

}

#pragma mark KVO实现
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading");
    }else if ([keyPath isEqualToString:@"title"]){
        
        self.title = self.webView.title;
    }else if ([keyPath isEqualToString:@"estimatedProgress"]){
        NSLog(@"progress: %f", self.webView.estimatedProgress);
        self.progressView.progress = self.webView.estimatedProgress;
    }
    
    //加载完成
    if (!self.webView.loading) {
        //手动调用JS代码
        //每次页面完成都弹出来,大家可以在测试时再打开
        NSString *JS = @"callJsAlert()";
        [self.webView evaluateJavaScript:JS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            NSLog(@"response :%@ error : %@",response,error);
            NSLog(@"call js alert by native");
        }];
        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0;
        }];
    }
    
}

#pragma mark  wknavigationdelegate
// 请求开始前，会先调用此代理方法
// 与UIWebView的
// - (BOOL)webView:(UIWebView *)webView
// shouldStartLoadWithRequest:(NSURLRequest *)request
// navigationType:(UIWebViewNavigationType)navigationType;
// 类型，在请求先判断能不能跳转（请求）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && ![hostname containsString:@".hao123.com"]) {
        //对于跨域,需要手动跳转
        [[UIApplication sharedApplication]openURL:navigationAction.request.URL];
        
        //不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        self.progressView.alpha = 1.0;
        decisionHandler(WKNavigationActionPolicyAllow);
        
    }
    NSLog(@"%s",__FUNCTION__);
    
    
}
// 在响应完成时，会回调此方法
// 如果设置为不允许响应，web内容就不会传过来

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    decisionHandler(WKNavigationResponsePolicyAllow);
    NSLog(@"%s",__FUNCTION__);
}

// 开始导航跳转时会回调
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"%s",__FUNCTION__);
}


// 接收到重定向时会回调
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"%s",__FUNCTION__);
}


// 导航失败时会回调
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
    
    NSLog(@"%s",__FUNCTION__);
    
}

// 页面内容到达main frame时回调
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
    NSLog(@"%s",__FUNCTION__);
}

// 导航完成时，会回调（也就是页面载入完成了）

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"%s",__FUNCTION__);
    
}

// 导航失败时会回调

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"%s",__FUNCTION__);
    
}

// 对于HTTPS的都会触发此代理，如果不要求验证，传默认就行
// 如果需要证书验证，与使用AFN进行HTTPS证书验证是一样的

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
     NSLog(@"%s", __FUNCTION__);
}

// 9.0才能使用，web内容处理中断时会触发
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark WKUIDelegate

-(void)webViewDidClose:(WKWebView *)webView{
    
    NSLog(@"%s",__FUNCTION__);
}

// 在JS端调用alert函数时，会触发此代理方法。
// JS端调用alert时所传的数据可以通过message拿到
// 在原生得到结果后，需要回调JS，是通过completionHandler回调

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    NSLog(@"%s",__FUNCTION__);
    UIAlertController *alert  =[UIAlertController alertControllerWithTitle:@"提示" message:@"JS调用alert" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@",message);
    
    
}

// JS端调用confirm函数时，会触发此方法
// 通过message可以拿到JS端所传的数据
// 在iOS端显示原生alert得到YES/NO后
// 通过completionHandler回调给JS端

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
      NSLog(@"%s", __FUNCTION__);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认" message:@"JS调用confirm" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        completionHandler(YES);
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    
    [self presentViewController:alert animated:YES completion:^{
        
    }];
    NSLog(@"%@",message);
    
}


// JS端调用prompt函数时，会触发此方法
// 要求输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    NSLog(@"%s", __FUNCTION__);
    
    NSLog(@"%@", prompt);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"文字输入" message:@"JS调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
    
}









- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
