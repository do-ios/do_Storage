//
//  do_Storage_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Storage_App.h"
static do_Storage_App* instance;
@implementation do_Storage_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Storage_App alloc]init];
    return instance;
}
@end
