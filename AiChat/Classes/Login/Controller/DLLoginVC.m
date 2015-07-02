//
//  ZHBLoginVC.m
//  AiChat
//
//  Created by 庄彪 on 15/7/1.
//  Copyright (c) 2015年 XMPP. All rights reserved.
//

#import "DLLoginVC.h"
#import "MBProgressHUD+ZHB.h"
#import "ZHBXMPPTool.h"
#import "ZHBUserInfo.h"
#import "ZHBControllerTool.h"
#import <ReactiveCocoa.h>

@interface DLLoginVC ()

@property (weak, nonatomic) IBOutlet UITextField *userNameTxtf;

@property (weak, nonatomic) IBOutlet UITextField *passwordTxtf;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation DLLoginVC

#pragma mark -
#pragma mark Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RACSignal *validUsernameSignal = [self.userNameTxtf.rac_textSignal map:^id(NSString * name) {
        return @([self isValidUserName:name]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTxtf.rac_textSignal map:^id(NSString *pwd) {
        return @([self isValidPassword:pwd]);
    }];
    
    RAC(self.userNameTxtf, backgroundColor) = [validUsernameSignal map:^id(NSNumber *valid) {
        return [valid boolValue] ? [UIColor clearColor] : [UIColor redColor];
    }];
    
    RAC(self.passwordTxtf, backgroundColor) = [validPasswordSignal map:^id(NSNumber *valid) {
        return [valid boolValue] ? [UIColor clearColor] : [UIColor redColor];
    }];
    
    [[RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal] reduce:^id(NSNumber *userNameValid, NSNumber *passwordValid) {
        return @([userNameValid boolValue] && [passwordValid boolValue]);
    }] subscribeNext:^(NSNumber *loginValid) {
        self.loginBtn.enabled = [loginValid boolValue];
    }];
    
    [[[[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        [MBProgressHUD showMessage:@"登录中..."];
    }] flattenMap:^RACStream *(id value) {
        return [self loginSignal];
    }] subscribeNext:^(NSNumber *type) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
            switch ([type integerValue]) {
                case XMPPStatusTypeLoginSuccess:
                    //                [ZHBControllerTool showStoryboardWithLogonState:YES];
                    break;
                case XMPPStatusTypeLoginFailure:
                    [MBProgressHUD showError:@"用户名或者密码不正确"];
                    break;
                case XMPPStatusTypeNetErr:
                    [MBProgressHUD showError:@"网络不给力"];
                    break;
                default:
                    break;
            }
        });
    }];
}

#pragma mark -
#pragma mark Private Methods

- (BOOL)isValidUserName:(NSString *)name {
    return name.length >= 4;
}

- (BOOL)isValidPassword:(NSString *)pwd {
    return pwd.length >= 4;
}

- (RACSignal *)loginSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        ZHBUserInfo *user = [ZHBUserInfo sharedUserInfo];
        user.name = self.userNameTxtf.text;
        user.password = self.passwordTxtf.text;
        [[ZHBXMPPTool sharedXMPPTool] userLogin:^(XMPPStatusType type) {
            [subscriber sendNext:@(type)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

@end