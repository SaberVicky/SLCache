//
//  AppDelegate.m
//  SLCacheDemo
//
//  Created by songlong on 2016/10/8.
//  Copyright © 2016年 com.Saber. All rights reserved.
//

#import "AppDelegate.h"
#import "SLCache.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"%@", path);
    [SLCache initialCacheWithPath:[NSString stringWithFormat:@"%@/cache.sqlite", path]];
    
    [[SLCache shareInstance] createTable:@"user"];
    
    //存储number
    NSNumber *number = [NSNumber numberWithInt:10];
    [[SLCache shareInstance] setObject:number intoTable:@"user" byId:@"userAge"];
    SLCacheItem *item1 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userAge"];
    NSLog(@"%@",item1.itemContent);
    
    //存储日期
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone defaultTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    NSDate *localeDate = [[NSDate date] dateByAddingTimeInterval:interval];
    [[SLCache shareInstance] setObject:localeDate intoTable:@"user" byId:@"userBirthday"];
    SLCacheItem *item2 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userBirthday"];
    NSLog(@"%@",item2.itemContent);
    
    
    //存储字符串
    NSString *name = @"Saber";
    [[SLCache shareInstance] setObject:name intoTable:@"user" byId:@"userName"];
    SLCacheItem *item3 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userName"];
    NSLog(@"%@",item3.itemContent);
    
    
    //存储数组
    NSArray *clothes = @[@"shoes",@"shirt"];
    [[SLCache shareInstance] setObject:clothes intoTable:@"user" byId:@"userClothes"];
    SLCacheItem *item4 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userClothes"];
    NSLog(@"%@",item4.itemContent);
    
    
    //存储辞典
    NSDictionary *dic = @{@"comic books":@"Dragon Ball"};
    [[SLCache shareInstance] setObject:dic intoTable:@"user" byId:@"userBooks"];
    SLCacheItem *item5 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userBooks"];
    NSLog(@"%@",item5.itemContent);
    
    //存储json 设置有效期
    NSArray *array=[NSArray arrayWithObject:dic];
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    
    [[SLCache shareInstance] setObject:json intoTable:@"user" byId:@"userResponse" cacheTime:15 checkSum:nil];
    
    SLCacheItem *item6 = [[SLCache shareInstance] getObjectFormTable:@"user" byObjectId:@"userResponse"];
    //判断是否过期
    if(!item6.isInExpirationdate)
    {
        NSLog(@"数据过期");
    }
    NSLog(@"%@",item6.itemContent);
    
    //清除user表
    //        [[SLCache shareInstance] cleanTable:@"user"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
