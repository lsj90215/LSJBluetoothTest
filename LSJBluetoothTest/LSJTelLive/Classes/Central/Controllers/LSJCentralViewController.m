//
//  LSJCentralViewController.m
//  LSJBlue
//
//  Created by 李思俊 on 16/10/16.
//  Copyright © 2016年 lsj. All rights reserved.
//
#import "LSJCentralViewController.h"
#import "LSJLabel.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define LSJ_WIDTH [UIScreen mainScreen].bounds.size.height/4

@interface LSJCentralViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

/* -----------  发现/扫描 和 连接蓝牙外设  -----------*/
@property (nonatomic, strong) CBCentralManager *centralManager;
/* -----------  蓝牙外设端  -----------*/
@property (nonatomic, strong) CBPeripheral *peripheral;


//扫描广播按钮
@property (nonatomic, strong)UIButton *peripheralBtn;
//接收广播按钮
@property (nonatomic, strong)UIButton *centralBtn;
//发送广播提示
@property (nonatomic, strong)LSJLabel *peripheralLabel;
//接收广播提示
@property (nonatomic, strong)LSJLabel *centralLabel;
//删除信息按钮
@property (nonatomic, strong)UIButton *deleteBtn;
//改变目标颜色按钮
@property (nonatomic, strong) UIButton *changePeripheralColor;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) CBService *service;
@end

@implementation LSJCentralViewController

#pragma mark - 点击扫描广播
-(void)clickPeripheral:(UIButton *)sender{
    /* ----------- 1. 返回一个新的CBCentralManager实例, 还会触发相应的代理方法  -----------*/
    
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    
}

#pragma mark - 点击备用按键
-(void)clickCentral:(UIButton *)sender{
    
}

#pragma mark - 点击删除信息
-(void)clickDeleteBtn:(UIButton *)sender{
    self.centralLabel.text = nil;
    self.peripheralLabel.text = nil;
}

#pragma mark - 点击改变颜色 - 修改Peripheral端的颜色
-(void)clickChangeColorBtn:(UIButton *)sender{
    
    if (sender.tag == 1) {
        sender.tag = 2;
        /* -----------  修改字段  -----------*/
        self.data = [@"继续啊   开始!!" dataUsingEncoding:NSUTF8StringEncoding];
    }else{
        sender.tag = 1;
        /* -----------  修改字段  -----------*/
        self.data = [@"放马过来吧, 操场见呀!" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    /* -----------  更改写入信息, 然后调用外设的代理方法 -----------*/
    [self peripheral:self.peripheral didDiscoverCharacteristicsForService:self.service error:nil];
    
}

#pragma mark - CBCentralManagerDelegate
//状态更新后触发
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    LSJLog(@"蓝牙状态检测");
    /* -----------  2.确保BLE是可用的 (硬件支持/开启)  -----------*/
    //获取当前蓝牙设备的状态 (是否开启)
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralLabel newTextWithNewText: @"蓝牙设备正常工作"];
    }else if(central.state == CBCentralManagerStateUnsupported ){
        [self.centralLabel newTextWithNewText: @"不支持BLE"];
        return;
    }
    
    /* -----------  3. 扫描附近的蓝牙设备(找到需要的外设)  -----------*/
    //CBUUID表示唯一标识UUID(蓝牙外设提供的参数)
    CBUUID *servicesUUID = [CBUUID UUIDWithString:PeripheralServiceUUID];
    //service参数为nil时, 表示扫描所有的蓝牙外设, 指定只扫描匹配UUID的外设
    [central scanForPeripheralsWithServices:@[servicesUUID] options:nil];
    
    //如果扫描到了外部设备, 会触发代理方法didDiscoverPeripheral
    
}

//扫描到外部设备后触发的代理方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    [self.centralLabel newTextWithNewText: @"扫描到外部设备"];
    
    /* -----------  4.链接到外部设备上(连上才能传递数据)  -----------*/
    //CBperipheral 表示外部设备(蓝牙硬件)
    //信号强度
    [self.centralLabel newTextWithNewText: [NSString stringWithFormat:@"信号强度:%@, 外设:",RSSI]];
    //必须强引用
    self.peripheral = peripheral;
    //链接外部设备, option可以在链接或者断开链接时让系统Alert提示
    //连接外部设备, 连接上会触发didConnectPeripheral代理方法
    [central connectPeripheral:peripheral options:nil];
    
    //停止扫描
    [central stopScan];
}

//当中心端连接上蓝牙外设时触发
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.centralLabel newTextWithNewText:@"链接外部设备成功"];
    
    /* -----------  5. 获取数据(蓝牙外设段发送数据, 中心端去获取)  -----------*/
    self.peripheral.delegate = self;
    
    /* -----------  5.1 读取外设段的服务  -----------*/
    //CBService表示服务
    //直接获取是得不到东西, 需要经过处理, services才能对应的属性值
    
    CBUUID *uuid = [CBUUID UUIDWithString:PeripheralServiceUUID];
    //需要经过discaver操作才能得到服务
    [peripheral discoverServices:@[uuid]];
    
    //如果发现了服务, 会触发peripheral的代理方法
    
}

#pragma mark - CBPeripheralDelegate

//外设段发现了服务时触发
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    //需要经过discover, 才能得到services
    NSArray <CBService *> *services = peripheral.services;
    NSLog(@"%@",services);
    
    CBService *service = services.lastObject;
    self.service = service;
    /* -----------  5.2 读取服务中的特征, 也需要经过discover  -----------*/
    CBUUID *readUUID = [CBUUID UUIDWithString:PeripheralCharacteristicReadUUID];
    CBUUID *writeUUID = [CBUUID UUIDWithString:PeripheralCharacteristicWriteUUID];
    CBUUID *notifyUUID = [CBUUID UUIDWithString:PeripheralCharacteristicNotityUUID];
    [peripheral discoverCharacteristics:@[readUUID,writeUUID,notifyUUID] forService:service];
    
}

//外设端从服务中发现了特性时触发
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    NSArray <CBCharacteristic *> *charactreisticArray = service.characteristics;
    
    for (CBCharacteristic *characteristic in charactreisticArray) {
        //读特征的处理
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PeripheralCharacteristicReadUUID]]) {
            [self.peripheralLabel newTextWithNewText: @"处理读特征"];
            /* -----------  5.3 读取特征中的数据, 需要经过读取操作才能得到数据  -----------*/
            [peripheral readValueForCharacteristic:characteristic];
        }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PeripheralCharacteristicWriteUUID]]){
             [self.peripheralLabel newTextWithNewText: @"处理写特征"];
            
//            self.data = [@"放马过来吧, 操场见呀!" dataUsingEncoding:NSUTF8StringEncoding];
            
            // 向写特征写入数据, 发回蓝牙外设端
            // CBCharacteristicWriteWithResponse 蓝牙外设会有回调, 让你知道数据的写入是否成功,  peripheral:didWriteValueForCharacteristic:error:
            [peripheral writeValue:self.data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PeripheralCharacteristicNotityUUID]]){
              [self.peripheralLabel newTextWithNewText: @"处理了订阅特征"];
            
            // 是否启用, 订阅特征的值改变时会触发代理
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

//从外设读取到特征的值后触发
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    /* -----------  5.4 拿到特征的值  -----------*/
    
    NSData *value = characteristic.value;
    NSString *valueString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    NSLog(@"%@", valueString);
}

//写特征的数据写入的结果回调
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"数据写入失败: %@", error);
         [self.peripheralLabel newTextWithNewText: @"数据写入失败"];
    } else {
        NSLog(@"数据写入成功");
         [self.peripheralLabel newTextWithNewText: @"数据写入成功"];
    }
}

// 订阅特征的值改变时触发的回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"订阅特征的值改变了 : %@", characteristic);
    [self.peripheralLabel newTextWithNewText:@"订阅特征的值改变了"];
}

#pragma mark - 控件懒加载区

-(NSData *)data{
    if (_data == nil) {
        _data = [@"放马过来吧, 操场见呀!" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return _data;
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


-(LSJLabel *)centralLabel{
    
    if (_centralLabel == nil) {
        LSJLabel *label = [[LSJLabel alloc]init];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:16];
        label.backgroundColor = [UIColor lightGrayColor];
        label.numberOfLines = 0;
        _centralLabel = label;
    }
    return _centralLabel;
}

-(UIButton *)changePeripheralColor{
    if (_changePeripheralColor == nil) {
        UIButton *peripheralBtn = [[UIButton alloc]init];
        [peripheralBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [peripheralBtn setTitle:@"改变Peripheral的颜色" forState:UIControlStateNormal];
        [peripheralBtn addTarget:self action:@selector(clickChangeColorBtn:) forControlEvents:UIControlEventTouchUpInside];
        peripheralBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        peripheralBtn.backgroundColor = LSJMainColor;
        [peripheralBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        peripheralBtn.tag = 1;
        _changePeripheralColor = peripheralBtn;
    }
    return _changePeripheralColor;
}

-(UIButton *)peripheralBtn{
    if (_peripheralBtn == nil) {
        UIButton *peripheralBtn = [[UIButton alloc]init];
        [peripheralBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [peripheralBtn setTitle:@"扫描广播" forState:UIControlStateNormal];
        [peripheralBtn addTarget:self action:@selector(clickPeripheral:) forControlEvents:UIControlEventTouchUpInside];
        peripheralBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        peripheralBtn.backgroundColor = LSJMainColor;
        [peripheralBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        _peripheralBtn = peripheralBtn;
    }
    return _peripheralBtn;
}

-(UIButton *)centralBtn{
    if (_centralBtn == nil) {
        UIButton *centralBtn = [[UIButton alloc]init];
        [centralBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [centralBtn setTitle:@"备用按键" forState:UIControlStateNormal];
        [centralBtn addTarget:self action:@selector(clickCentral:) forControlEvents:UIControlEventTouchUpInside];
        centralBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        centralBtn.backgroundColor = LSJMainColor;
        [centralBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        _centralBtn = centralBtn;
    }
    return _centralBtn;
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
    [self.view addSubview:self.centralBtn];
    [self.view addSubview:self.peripheralBtn];
    
    UILabel *peripheral = [[UILabel alloc]init];
    peripheral.textColor = [UIColor blackColor];
    peripheral.textAlignment = NSTextAlignmentLeft;
    peripheral.font = [UIFont systemFontOfSize:16];
    peripheral.backgroundColor = [UIColor whiteColor];
    peripheral.text = @"扫描广播:";
    
    UILabel *central = [[UILabel alloc]init];
    central.textColor = [UIColor blackColor];
    central.textAlignment = NSTextAlignmentLeft;
    central.font = [UIFont systemFontOfSize:16];
    central.backgroundColor = [UIColor whiteColor];
    central.text = @"接收广播:";
    
//    if (self.peripheralLabel.text == nil && self.centralLabel.text == nil) {
//        self.deleteBtn.userInteractionEnabled = NO;
//    }
    
    [self.view addSubview:self.deleteBtn];
    [self.view addSubview:peripheral];
    [self.view addSubview:central];
    [self.view addSubview:self.peripheralLabel];
    [self.view addSubview:self.centralLabel];
    [self.view addSubview:self.changePeripheralColor];
    
    //设置子控件约束
    [self.peripheralBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view).offset(20);
        
    }];
    
    [self.centralBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.peripheralBtn.mas_top);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [peripheral mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.centralBtn.mas_bottom).offset(10);
        make.left.equalTo(self.peripheralBtn.mas_left);
    }];
    
    [central mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peripheral.mas_bottom).offset(LSJ_WIDTH);
        make.left.equalTo(self.peripheralBtn.mas_left);
    }];
    
    [self.peripheralLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peripheral.mas_bottom).offset(10);
        make.left.equalTo(self.peripheralBtn.mas_left);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(central.mas_top).offset(-10);
    }];
    
    [self.centralLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(central.mas_bottom).offset(10);
        make.left.equalTo(self.peripheralBtn.mas_left);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.deleteBtn.mas_top).offset(-10);
    }];
    
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(central.mas_bottom).offset(LSJ_WIDTH);
        make.right.equalTo(self.centralBtn);
    }];
    
    [self.changePeripheralColor mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(central.mas_bottom).offset(LSJ_WIDTH);
        make.left.equalTo(self.peripheralBtn);
    }];
    
    
}



@end
