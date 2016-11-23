//
//  BluetoothUUIDDefine.h
//  09-蓝牙
//
//  Created by Zed on 9/11/2015.
//  Copyright © 2015 itcast. All rights reserved.
//
//  通讯协议

#ifndef BluetoothUUIDDefine_h
#define BluetoothUUIDDefine_h

/**
 *  通过Terminal 的 uuidgen 命令来生成UUID
 */

#define PeripheralServiceUUID       @"36DF9D78-FCF4-45DF-BE19-B5258FA4E0EA" // 服务

#define PeripheralCharacteristicReadUUID       @"A248D8FB-7D99-4CCC-B0E0-6B678BF04738"  // 读特征, 结果是NSString的数据

#define PeripheralCharacteristicWriteUUID       @"37665029-D259-4E74-B539-A7BCA48A581C" // 写特征

// 订阅特征
#define PeripheralCharacteristicNotityUUID      @"FE868605-23BF-4F68-BE5E-BE88AFB1082A"


#endif /* BluetoothUUIDDefine_h */
