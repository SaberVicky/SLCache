//
//  SLCache.m
//  SLCacheManager
//
//  Created by songlong on 2016/10/8.
//  Copyright © 2016年 com.Saber. All rights reserved.
//

#import "SLCache.h"

#pragma mark -- NSString and  NSDate transform

static NSString * const SLCACHE_DATE_FORMATTER = @"yyyy-MM-dd HH:mm:ss zzz";


@implementation  NSString (ToNSDate)

- (NSDate *)stringToDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:SLCACHE_DATE_FORMATTER];
    NSDate *date=[formatter dateFromString:self];
    return date;
}

@end



@implementation NSDate (ToNSString)

- (NSString *)dateToString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:SLCACHE_DATE_FORMATTER];
    
    NSString *string = [dateFormatter stringFromDate:self];
    
    return string;
}

@end

#pragma mark -- SLCache Const Variable

static NSString * const SLCACHE_CREATE_TABLE_SQL = @"create table if not exists %@ \
(id text not null, \
content text not null, \
createdTime text not null, \
timestamp text , \
type text not null, \
checksum text, \
primary key(id))" ;


static NSString * const SLCACHE_INSERT_SQL = @"insert into %@ values (?, ?, ?, ?, ?, ?)" ;

static NSString * const SLCACHE_UPDATE_SQL = @"replace into %@ (id, content, createdTime,timestamp,type,checksum) values (?, ?, ?, ?, ?, ?)" ;

static NSString * const SLCACHE_DELETE_SQL = @"delete from %@ where id = ?";

static NSString * const SLCACHE_QUERY_SQL = @"select * from %@ where id = ?";

static NSString * const SLCACHE_QUERY_ALL_SQL = @"select  * from %@";

static NSString * const SLCACHE_CLEAN_TABLE_SQL = @"delete from %@";

//aes加密 秘钥
static NSString * const SLCACHE_AES_CODE  = @"";


@implementation SLCacheItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.itemId = nil;
        self.itemContent = nil;
        self.itemCreateTime = nil;
        self.cacheTime = 0;
        self.checksum = nil;
    }
    return self;
}

- (BOOL)isInExpirationdate {
    BOOL flag = NO;
    if(self.cacheTime>0)
    {
        NSDate *date = [NSDate date];
        NSTimeZone *zone = [NSTimeZone defaultTimeZone];
        NSInteger interval = [zone secondsFromGMTForDate:date];
        NSDate *localeDate = [[NSDate date] dateByAddingTimeInterval:interval];
        NSTimeInterval timeInterval2 = [localeDate timeIntervalSince1970];
        if(timeInterval2 < self.cacheTime) {
            flag = YES;
        }
    }
    
    return flag;
}

@end


#pragma mark --- SLCache

@interface SLCache()

@property (nonatomic, copy, nonnull) NSString *path;

@end

@implementation SLCache

+ (instancetype)initialCacheWithPath:(NSString *)path {
    SLCache *cache = [SLCache shareInstance];
    if (!cache.path) {
        cache.path = path;
        cache.dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    }
    return cache;
}

+ (instancetype)shareInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.encryptionBlock = nil;
        self.decryptionBlock = nil;
    }
    return self;
}

- (void)createTable:(NSString *)tableName {
    [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
        [db executeStatements:[NSString stringWithFormat:SLCACHE_CREATE_TABLE_SQL, tableName]];
    }];
}

- (void)cleanTable:(NSString *)tableName {
    [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
        [db executeStatements:[NSString stringWithFormat:SLCACHE_CLEAN_TABLE_SQL, tableName]];
    }];
}

- (void)setObject:(id)object intoTable:(NSString *)tableName byId:(NSString *)objectId {
    [self setObject:object intoTable:tableName byId:objectId cacheTime:0 checkSum:nil];
}

- (void)setObject:(id)object intoTable:(NSString *)tableName byId:(NSString *)objectId cacheTime:(NSInteger)cacheTime checkSum:(NSString *)checksum {
    
    if (cacheTime != 0) {
        NSDate *date=[NSDate date];
        NSTimeZone *zone = [NSTimeZone defaultTimeZone];
        NSInteger interval = [zone secondsFromGMTForDate:date];
        NSDate *localeDate = [[NSDate date] dateByAddingTimeInterval:interval];
        NSTimeInterval timeInterval2 = [localeDate timeIntervalSince1970];
        cacheTime += timeInterval2;
    }
    
    if (!object) {
        [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:SLCACHE_DELETE_SQL, tableName, objectId];
        }];
    } else {
        NSString *type =nil;
        
        if([object isKindOfClass:[NSString class]])
            type=NSStringFromClass([NSString class]);
        
        if([object isKindOfClass:[NSNumber class]])
        {
            type=NSStringFromClass([NSNumber class]);
            
            NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle=NSNumberFormatterDecimalStyle;
            object=[formatter stringFromNumber:object];
        }
        
        if([object isKindOfClass:[NSDate class]])
        {
            type=NSStringFromClass([NSDate class]);
            object=[NSString stringWithFormat:@"%@",object];
        }
        
        if([object isKindOfClass:[NSData class]])
        {
            type=NSStringFromClass([NSData class]);
            object=[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        }
        
        if([object isKindOfClass:[NSArray class]])
        {
            type =NSStringFromClass([NSArray class]);
            object=[NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
            object=[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        }
        
        if([object isKindOfClass:[NSDictionary class]])
        {
            type =NSStringFromClass([NSDictionary class]);
            object=[NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
            object=[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        }
        
        
        if(self.encryptionBlock)
        {
            object=[object dataUsingEncoding:NSUTF8StringEncoding];
            object=self.encryptionBlock(object);
            object=[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        }
        
        
        if(![self getObjectFormTable:tableName byObjectId:objectId])
        {
            [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:[NSString stringWithFormat:SLCACHE_INSERT_SQL,tableName],objectId,object,[[NSDate date] dateToString],[[NSNumber numberWithInteger:cacheTime] stringValue],type,checksum];
            }];
        }else
        {
            [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:[NSString stringWithFormat:SLCACHE_UPDATE_SQL,tableName],objectId,object,[[NSDate date] dateToString],[[NSNumber numberWithInteger:cacheTime] stringValue],type,checksum];
            }];
        }
    }
}

- (SLCacheItem *)getObjectFormTable:(NSString *)tableName byObjectId:(NSString *)objectId {
    __block SLCacheItem *item = nil;
    __block FMResultSet *result = nil;
    [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeQuery:[NSString stringWithFormat:SLCACHE_QUERY_SQL, tableName], objectId];
        if ([result next]) {
            item = [self cacheItemFromFMResultSet:result];
        }
        
        [result close];
    }];
    
    return item;
}

- (NSArray<SLCacheItem *> *)getAllObjectFromTable:(NSString *)tableName {
    NSMutableArray *array = [NSMutableArray array];
    __block FMResultSet *result = nil;
    [self.dataBaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeQuery:[NSString stringWithFormat:SLCACHE_QUERY_ALL_SQL,tableName]];
        while ([result next]) {
            [array addObject:[self cacheItemFromFMResultSet:result]];
        }
        
        [result close];
    }];
    
    if(array.count==0)
        array = nil;
    
    return array;
}

- (SLCacheItem *)cacheItemFromFMResultSet:(FMResultSet *)result {
    SLCacheItem *item = [[SLCacheItem alloc] init];
    item.itemId = [result stringForColumn:@"id"];
    item.itemContent = [result stringForColumn:@"content"];
    item.itemCreateTime = [[result stringForColumn:@"createdTime"] stringToDate];
    item.cacheTime = [[result stringForColumn:@"timestamp"] integerValue];
    item.checksum = [result stringForColumn:@"checksum"];
    item.type = [result stringForColumn:@"type"];
    
    if(self.decryptionBlock)
    {
        item.itemContent=[item.itemContent dataUsingEncoding:NSUTF8StringEncoding];
        item.itemContent=self.decryptionBlock(item.itemContent);
        item.itemContent=[[NSString alloc] initWithData:item.itemContent encoding:NSUTF8StringEncoding];
    }
    
    
    
    if([item.type isEqualToString:NSStringFromClass([NSNumber class])])
    {
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle=NSNumberFormatterDecimalStyle;
        item.itemContent=[formatter numberFromString:item.itemContent];
    }
    
    if([item.type isEqualToString:NSStringFromClass([NSDate class])])
    {
        item.itemContent=[item.itemContent stringToDate];
    }
    
    if([item.type isEqualToString:NSStringFromClass([NSData class])])
    {
        item.itemContent=[item.itemContent dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if([item.type isEqualToString:NSStringFromClass([NSArray class])]||
       [item.type isEqualToString:NSStringFromClass([NSDictionary class])])
    {
        item.itemContent=[item.itemContent dataUsingEncoding:NSUTF8StringEncoding];
        item.itemContent=[NSJSONSerialization JSONObjectWithData:item.itemContent options:NSJSONReadingAllowFragments error:nil];
    }
    return item;

}

@end
