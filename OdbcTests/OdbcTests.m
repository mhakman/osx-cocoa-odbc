//
//  OdbcTests.m
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcTests.h"

#import <Odbc/Odbc.h>

NSString * DataSourceName;
NSString * Username;
NSString * Password;

@interface OdbcTests () 

@end

@implementation OdbcTests

+ (void) initialize {
    
    DataSourceName = @"db2testdb";
    
    Username = @"mhakman";
    
    Password = @"staryty1";
}

- (void) setUp {
    
    [super setUp];
    
    [self connect];
    
    [self createTestTable];
    
    [self insertTestRows];
}

- (void) connect {
    
    self->connection = [OdbcConnection new];
    
    [self->connection connect : DataSourceName username : Username password : Password];
    
    self->connection.transactionIsolation = SQL_TXN_SERIALIZABLE;
    
    self->statement = [self->connection newStatement];
}

- (void) disconnect {
    
    [self->connection disconnect];
}

- (void) insertTestRows {
    
    [self deleteTestRows];
    
    NSArray * sqls =
   
    @[@"insert into testtab values (1,'Name 1',1.1,date '2001-01-01',time '01:01:01',timestamp '2001-01-01 01:01:01')",
      @"insert into testtab values (2,'Name 2',2.2,date '2002-02-02',time '02:02:02',timestamp '2002-02-02 02:02:02')",
      @"insert into testtab values (3,'Name 3',3.3,date '2003-03-03',time '03:03:03',timestamp '2003-03-03 03:03:03')",
      @"insert into testtab values (4,'N4'    ,4.4,date '2004-04-04',time '04:04:04',timestamp '2004-04-04 04:04:04')"];
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    for (NSString * sql in sqls) {
    
        [stmt execDirect : sql];
    }
    
    [self->connection commit];
}

- (void) deleteTestRows {
        
    NSString * sql = @"delete from testtab";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    [self->connection commit];
}

- (void) createTestTable {
    
    [self dropTestTable];
    
    NSString * createSql = @"create table testtab ("
                            " id    bigint not null primary key,"
                            " name  varchar(128) not null unique,"
                            " price decimal(13,2),"
                            " date  date,"
                            " time  time,"
                            " ts timestamp"
                            ")";
    
    OdbcStatement * createStmt = [self->connection newStatement];
    
    [createStmt execDirect : createSql];
    
    [self->connection commit];
}

- (void) dropTestTable {
    
    NSString * dropSql = @"drop table testtab";
    
    OdbcStatement * dropStmt = [self->connection newStatement];
    
    bool tableExists = YES;
    
    @try {
        
        [dropStmt execDirect : dropSql];
        
    } @catch (OdbcException * exception) {
        
        tableExists = NO;
    }
    
    [self->connection commit];
}

- (void) tearDown {
    
    [self dropTestTable];
    
    [self->connection disconnect];
    
    [super tearDown];
}

@end
