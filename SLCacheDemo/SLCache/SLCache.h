//
//  SLCache.h
//  SLCacheManager
//
//  Created by songlong on 2016/10/8.
//  Copyright © 2016年 com.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

#pragma mark --- Category

@interface NSString (ToNSDate)

- (nullable NSDate *)stringToDate;

@end

@interface NSDate (ToNSString)

- (nullable NSString *)dateToString;

@end

#pragma mark --- SLCacheItem

@interface SLCacheItem : NSObject

//存储的数据的id
@property (nonatomic, strong, nullable) NSString *itemId;
//存储数据的内容
@property (nonatomic, strong, nullable) id  itemContent;
//存储数据创建的时间
@property (nonatomic, strong, nullable) NSDate *itemCreateTime;
//存储数据的时间戳－－－》有效期
@property (nonatomic, assign) NSInteger cacheTime;
//存储数据的校验和－－－》用于传给服务器 判断数据是否发生变化 类似于http 304
@property (nonatomic, strong, nullable) NSString *checksum;
//存储数据的类型
@property (nonatomic, strong, nullable) NSString *type;

//存储数据是否过期
-(BOOL)isInExpirationdate;

@end



#pragma mark --- SLCache

typedef   NSData * _Nullable  (^SLHandleData)( NSData * _Nullable);

@interface SLCache : NSObject

//暴露给外部 执行sql语句的接口
@property (nonatomic, strong, nonnull) FMDatabaseQueue *dataBaseQueue;
//加密block
@property (nonatomic, copy, nullable) SLHandleData encryptionBlock;
//解密block
@property (nonatomic, copy, nullable) SLHandleData decryptionBlock;

//单例
+ (nullable instancetype)shareInstance;

//配置路径
+ (nullable instancetype)initialCacheWithPath:(nullable NSString *)path;

//创建表
- (void)createTable:(nonnull NSString *)tableName;

//清空表中的数据
- (void)cleanTable:(nonnull NSString *)tableName;

//插入、修改数据，如果object为nil 则视为删除数据  object为NSNumber、NSString、NSArray、NSDictionary、NSDate、NSData
- (void)setObject:(nonnull id)object intoTable:(nonnull NSString *)tableName byId:(nonnull NSString *)objectId;

//插入、修改数据，如果object为nil 则视为删除数据
- (void)setObject:(nonnull id)object intoTable:(nonnull NSString *)tableName byId:(nonnull NSString *)objectId cacheTime:(NSInteger)cacheTime checkSum:(nullable NSString *)checksum;

//获取数据
- (nullable SLCacheItem *)getObjectFormTable:(nonnull NSString *)tableName byObjectId:(nonnull NSString *)objectId;

//获取表中的所有数据
- (nullable NSArray <__kindof SLCacheItem *>  *)getAllObjectFromTable:(nonnull NSString *)tableName;

@end
