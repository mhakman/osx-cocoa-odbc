//
//  OdbcTests.m
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcTests.h"

#import <Odbc/Odbc.h>

@interface OdbcTests () 

@end

@implementation OdbcTests

- (void) setUp {
    
    [super setUp];
    
    [self connect];
    
    [self createTestTable];
    
    [self insertTestRows];
}

- (void) connect {
    
    self->connection = [OdbcConnection new];
    
    [self->connection connect : @"testdb" user : @"root" password : nil];    
}

- (void) disconnect {
    
    [self->connection disconnect];
}

- (void) insertTestRows {
    
    [self deleteTestRows];
    
    NSString * sql = @"insert into testtab values (1,'Name 1',1.1),"
                      "                           (2,'Name 2',2.2),"
                      "                           (3,'Name 3',3.3)";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
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
                            " id    bigint not null unique primary key,"
                            " name  varchar(128) not null unique,"
                            " price decimal(13,2)"
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
