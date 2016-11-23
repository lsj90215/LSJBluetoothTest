//
//  LSJLabel.m
//  LSJBlue
//
//  Created by 李思俊 on 16/10/16.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "LSJLabel.h"

@implementation LSJLabel


-(void)newTextWithNewText:(NSString *)newText{
    if (self.text != nil) {
        self.text = [NSString stringWithFormat:@"%@\n%@",self.text,newText];
    }else{
        self.text = newText;
    }
}


@end
