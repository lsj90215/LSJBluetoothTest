//
//  LSJPeripheralViewController.m
//  LSJBlue
//
//  Created by 李思俊 on 16/10/16.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "LSJPeripheralViewController.h"
#import "LSJLabel.h"
#import <CoreBluetooth/CoreBluetooth.h>


@interface LSJPeripheralViewController ()<CBPeripheralManagerDelegate>

/* -----------  CBPeriphercalManager 实现数据广播 (外设端功能实现)  -----------*/
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
/* -----------  CBCentral 表示中心设备  -----------*/
@property (nonatomic, strong )CBCentral *central;
@property (nonatomic ,strong)CBUUID *serviceUUID;
@property (nonatomic ,strong)CBUUID *readUUID;
@property (nonatomic ,strong)CBUUID *writeUUID;
@property (nonatomic ,strong)CBUUID *notifyUUID;

/* -----------  订阅特征  -----------*/
@property (nonatomic, strong)CBMutableCharacteristic *notifyChar;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger integer;

//发送广播按钮
@property (nonatomic, strong)UIButton *peripheralBtn;
@property (nonatomic, strong)UIButton *notifyBtn;
//发送广播提示
@property (nonatomic, strong)LSJLabel *peripheralLabel;
//删除信息按钮
@property (nonatomic, strong)UIButton *deleteBtn;

@end

@implementation LSJPeripheralViewController

#pragma mark - 点击发送广播
-(void)clickPeripheral:(UIButton *)sender{
    //实例化CBPeripheralManager
    //queue为nil时, 表示在主线程中执行
    //实例化后, 会触发相关的代理方法
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

#pragma mark - 点击修改订阅的值
-(void)clickChangeNotify:(UIButton *)sender{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
}

-(void)timerAction{
    NSString *string = [NSString stringWithFormat:@"订阅特征数据: %zd",self.integer];
    self.integer++;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    //每一秒都在修改订阅特征的值
    
    //    self.notifyChar.value = data; //错误
    // 更新订阅特征的值是使用的时 updateValue: forCharacteristic: onSubscribedCentrals:而不是直接去修改value的值
    // onSubscribedCentrals 设置需要通知的订阅的中心设备
    [self.peripheralManager updateValue:data forCharacteristic:self.notifyChar onSubscribedCentrals:@[self.central]];
}

#pragma mark - CBPeripheralManagerDelegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    [self.peripheralLabel newTextWithNewText:@"状态更新代理方法触发"];
    
    if (peripheral.state != CBCentralManagerStatePoweredOn) {
        [self.peripheralLabel newTextWithNewText:@"当前蓝牙不可用"];
        return;
    }
    /* -----------  广播数据 (让其他设备扫描并能接收数据)  -----------*/
    /* -----------  1, 创建相关的特征 (封装数据)  -----------*/
    self.readUUID = [CBUUID UUIDWithString:PeripheralCharacteristicReadUUID];
    
    NSData *data = [@"来啊互相伤害啊!" dataUsingEncoding:NSUTF8StringEncoding];
    //创建读特征
    CBMutableCharacteristic *readChar = [[CBMutableCharacteristic alloc]initWithType:self.readUUID properties:CBCharacteristicPropertyRead value:data permissions:CBAttributePermissionsReadable ];
    // 创建 写特征
    self.writeUUID = [CBUUID UUIDWithString:PeripheralCharacteristicWriteUUID];
    CBMutableCharacteristic *writeChar = [[CBMutableCharacteristic alloc] initWithType:self.writeUUID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    
    //  创建 订阅特征
    self.notifyUUID = [CBUUID UUIDWithString:PeripheralCharacteristicNotityUUID];
    self.notifyChar = [[CBMutableCharacteristic alloc] initWithType:self.notifyUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
    
    /* -----------  2, 创建相关的服务  -----------*/
    // CBMutableService 创建对应的服务
    // CBUUID 是指定 CBMutableService 的唯一标识
    self.serviceUUID = [CBUUID UUIDWithString:PeripheralServiceUUID];
    // Type 指定服务的唯一标识(UUID), primary表示是否为主要服务
    CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
    // 向服务添加特征
    service.characteristics = @[readChar, writeChar, self.notifyChar];
    
    /*================= 3. 将服务添加到CBPeripheralManager =================*/
    // 添加服务后, 会回调相关代理方法
    [self.peripheralManager addService:service];
}

//peripheralManager 添加了服务之后触发
-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    [self.peripheralLabel newTextWithNewText:@"添加服务成功"];
    
    /* -----------  4, 让CBperipheralManager 进行数据广播 (数据通过特征包装, 特征通过服务包装)  -----------*/
    [self.peripheralManager startAdvertising:@{
                                               CBAdvertisementDataServiceUUIDsKey : @[self.serviceUUID],
                                               //指定进行广播服务
                                               }];
    
    //开始广播后, 会回调相关代理方法
}

//CBPeripheralManager  开始广播时触发
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    [self.peripheralLabel newTextWithNewText:@"开始广播服务"] ;
    //当设备链接上外设时, 并没有相关代理方法
}

#pragma mark - 写特征相关的代理

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests{
    [self.peripheralLabel newTextWithNewText:@"收到写特征"] ;
    
    for (CBATTRequest *request in requests) {
        NSData *data = request.value;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self.peripheralLabel newTextWithNewText: str];
        
        /* -----------  根据central返回来的字段进行操作,刷新UI等等  -----------*/
        if ([str isEqualToString:@"继续啊   开始!!"]) {
            self.view.backgroundColor = [UIColor redColor];
        }else if([str isEqualToString:@"放马过来吧, 操场见呀!"]){
            self.view.backgroundColor = [UIColor whiteColor];
        }
        // 将写入结果回调到中心端
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        
    }
}

#pragma mark - 订阅特征的相关代理
// 当有中心设备订阅特征的值时, 会触发该方法
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"有中心设备订阅了特征");
    [self.peripheralLabel newTextWithNewText:@"有中心设备订阅了特征"] ;
    // 订阅了订阅特征的中心设备
    self.central = central;
}

// 当有中心设备取消订阅特征的值时, 会触发该方法
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"有中心设备取消订阅了特征");
    [self.peripheralLabel newTextWithNewText:@"中心设备取消订阅了特征"] ;
}

#pragma mark - 点击删除信息
-(void)clickDeleteBtn:(UIButton *)sender{
    self.peripheralLabel.text = nil;
    
    
}

#pragma mark - 控件懒加载区
-(UIButton *)notifyBtn{
    if (_notifyBtn == nil) {
        UIButton *centralBtn = [[UIButton alloc]init];
        [centralBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [centralBtn setTitle:@"修改订阅" forState:UIControlStateNormal];
        [centralBtn addTarget:self action:@selector(clickChangeNotify:) forControlEvents:UIControlEventTouchUpInside];
        centralBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        centralBtn.backgroundColor = LSJMainColor;
        [centralBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        _notifyBtn = centralBtn;
    }
    return _notifyBtn;
}

-(LSJLabel *)peripheralLabel{
    if (_peripheralLabel == nil) {
        LSJLabel *label = [[LSJLabel alloc]init];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:16];
        label.backgroundColor = [UIColor lightGrayColor];
        label.numberOfLines = 0;
        _peripheralLabel = label;
    }
    return _peripheralLabel;
}

-(UIButton *)peripheralBtn{
    if (_peripheralBtn == nil) {
        UIButton *peripheralBtn = [[UIButton alloc]init];
        [peripheralBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [peripheralBtn setTitle:@"发送广播" forState:UIControlStateNormal];
        [peripheralBtn addTarget:self action:@selector(clickPeripheral:) forControlEvents:UIControlEventTouchUpInside];
        peripheralBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        peripheralBtn.backgroundColor = LSJMainColor;
        [peripheralBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        _peripheralBtn = peripheralBtn;
    }
    return _peripheralBtn;
}

-(UIButton *)deleteBtn{
    if (_deleteBtn == nil) {
        UIButton *deleteBtn = [[UIButton alloc]init];
        [deleteBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [deleteBtn setTitle:@"清除信息" forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(clickDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        deleteBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        deleteBtn.backgroundColor = LSJMainColor;
        [deleteBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [deleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        _deleteBtn = deleteBtn;
    }
    return _deleteBtn;
}

#pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - 创建UI
-(void)setupUI{
    //view背景颜色
    self.view.backgroundColor = [UIColor whiteColor];
    
    //添加子控件
    [self.view addSubview:self.peripheralBtn];
    
    UILabel *peripheral = [[UILabel alloc]init];
    peripheral.textColor = [UIColor blackColor];
    peripheral.textAlignment = NSTextAlignmentLeft;
    peripheral.font = [UIFont systemFontOfSize:16];
    peripheral.backgroundColor = [UIColor whiteColor];
    peripheral.text = @"发送广播:";
    
//    if (self.peripheralLabel.text == nil) {
//        self.deleteBtn.userInteractionEnabled = NO;
//    }
    
    [self.view addSubview:self.deleteBtn];
    [self.view addSubview:peripheral];
    [self.view addSubview:self.peripheralLabel];
    [self.view addSubview:self.notifyBtn];
    
    //设置子控件约束
    [self.peripheralBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
        make.left.equalTo(self.view).offset(20);
        
    }];
    
    [self.notifyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.peripheralBtn.mas_top);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [peripheral mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.peripheralBtn.mas_bottom).offset(10);
        make.left.equalTo(self.peripheralBtn.mas_left);
    }];
    
    [self.peripheralLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peripheral.mas_bottom).offset(10);
        make.left.equalTo(self.peripheralBtn.mas_left);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.deleteBtn.mas_top).offset(-10);
    }];
    
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peripheral.mas_bottom).offset(150);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    
}



@end
