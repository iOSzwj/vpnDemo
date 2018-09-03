//
//  ViewController.m
//  vpnDemo
//
//  Created by 张文军 on 2018/8/28.
//  Copyright © 2018年 张文军. All rights reserved.
//

#import "ViewController.h"

#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()

@property(nonatomic,strong)NEVPNManager *vpnM;

@end

@implementation ViewController

#pragma mark - 控制器生命周期 ViewController Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];

    __weak typeof(self) _weakSelf = self;
    _vpnM = [NEVPNManager sharedManager];
    [_vpnM loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"vpnManager 加载失败 : %@",error.userInfo);
        }else{
            NSLog(@"%@",@"vpnManage 加载成功");
            // 配置相关参数
            [_weakSelf setVpnConfig];
        }
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSError *error = nil;
    [self.vpnM.connection startVPNTunnelAndReturnError:&error];
    if(error) {
        NSLog(@"Start error: %@", error.localizedDescription);
    }else{
        NSLog(@"Connection established!");
    }
}

#pragma mark - 私有的方法 private Methods

-(void)setVpnConfig{
    
    // 创建配置对象
    NEVPNProtocolIPSec *sec = [[NEVPNProtocolIPSec alloc] init];
    // 用户名
    sec.username = @"xxxx";
    // 服务器地址
    sec.serverAddress = @"222.184.112.38";
    
    // 密码，必须从keychain导出
    [self createKeychainValue:@"xxxx" forIdentifier:@"VPN_PASSWORD"];
    sec.passwordReference = [self searchKeychainCopyMatching:@"VPN_PASSWORD"];
    
    // 秘钥，必须从keychain导出
    [self createKeychainValue:@"xxxx" forIdentifier:@"VPN_shared_PASSWORD"];
    sec.sharedSecretReference = [self searchKeychainCopyMatching:@"VPN_shared_PASSWORD"];

    // 验证方式：共享秘钥
    sec.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
    // 不验证
//    sec.authenticationMethod = NEVPNIKEAuthenticationMethodNone;
    // 显示的名字
    sec.localIdentifier = @"小兔子vpn";
    // 不知道干啥的，想知道的自己百度
    sec.remoteIdentifier = @"小兔子vpn";
    sec.useExtendedAuthentication = YES;
    sec.disconnectOnSleep = false;
    
    self.vpnM.onDemandEnabled = NO;
    [self.vpnM setProtocolConfiguration:sec];
    self.vpnM.localizedDescription = @"小兔子vpn";
    self.vpnM.enabled = true;
    [self.vpnM saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"vpn 配置失败 : %@",error.userInfo);
        }else{
            NSLog(@"%@",@"vpn 配置成功");
            // 监听vpn状态变化
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];
        }
        
    }];
    
}

-(void)onVpnStateChange:(NSNotification *)Notification {
    
    NEVPNStatus state = self.vpnM.connection.status;
    
    switch (state) {
        case NEVPNStatusInvalid:
            NSLog(@"无效连接");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"未连接");
            break;
        case NEVPNStatusConnecting:
            NSLog(@"正在连接");
            break;
        case NEVPNStatusConnected:
            NSLog(@"已连接");
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"断开连接");
            break;
        default:
            break;
    }
}

#pragma mark - 生命周期 Life Circle



#pragma mark - 公开的方法 public Methods



#pragma mark - keychain 相关

- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    return (__bridge_transfer NSData *)result;
}

- (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
    // creat a new item
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    //OSStatus 就是一个返回状态的code 不同的类返回的结果不同
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

//服务器地址
static NSString * const serviceName = @"serviceName";

- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    //   keychain item creat
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    //   extern CFTypeRef kSecClassGenericPassword  一般密码
    //   extern CFTypeRef kSecClassInternetPassword 网络密码
    //   extern CFTypeRef kSecClassCertificate 证书
    //   extern CFTypeRef kSecClassKey 秘钥
    //   extern CFTypeRef kSecClassIdentity 带秘钥的证书
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    //ksecClass 主键
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    return searchDictionary;
}

#pragma mark - 数据源代理 datesource

#pragma mark - 触摸事件 touch event

#pragma mark - setter

#pragma mark - 懒加载 getter

-(NEVPNManager *)vpnM{
    if (_vpnM==nil) {
        _vpnM = [NEVPNManager sharedManager];
    }
    return _vpnM;
}

@end
