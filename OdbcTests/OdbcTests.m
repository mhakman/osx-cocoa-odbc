//
//  OdbcTests.m
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcTests.h"

#import <Odbc/Odbc.h>

#import <iODBC/sql.h>
#import <iODBC/sqltypes.h>
#import <iODBC/sqlext.h>

NSString * DataSourceName;
NSString * Username;
NSString * Password;

@interface OdbcTests () 

@end

@implementation OdbcTests

+ (void) initialize {
    
    if (! DataSourceName) {
        
        char dsn [256];
    
        printf ("Data Source Name:");
        
        fgets (dsn,sizeof(dsn),stdin);
        
        if (dsn[strlen(dsn) - 1] == '\n') dsn[strlen(dsn) - 1] = 0;
        
        DataSourceName = [NSString stringWithUTF8String : dsn];
        
        char username [256];
        
        printf ("Username:");
        
        fgets (username,sizeof(username),stdin);
        
        if (username[strlen(username) - 1] == '\n') username[strlen(username) - 1] = 0;
        
        Username = [NSString stringWithUTF8String : username];
        
        char password [256];
        
        printf ("Password:");
        
        fgets (password,sizeof(password),stdin);
        
        if (password[strlen(password) - 1] == '\n') password[strlen(password) - 1] = 0;
        
        Password = [NSString stringWithUTF8String : password];
        
        @try {
            
            OdbcConnection * conn = [OdbcConnection connectionWithDataSource : DataSourceName
                                                                    username : Username
                                                                    password : Password];
            
            [conn disconnect];
            
        } @catch (NSException * ex) {
                
            printf ("%s\n",ex.description.UTF8String);
            
            printf ("\nTests not run\n");
            
            exit (1);
        }
    }
        
    //DataSourceName = @"mimtest";
    
    //Username = @"testuser";
    
    //Password = @"test";
}

- (void) setUp {
    
    @try {
    
        [super setUp];
    
        [self connect];
    
        [self createTestTable];
    
        [self insertTestRows];
        
    } @catch (NSException * exception) {
        
        STFail (exception.description);
    }
}

- (void) connect {
    
    self->connection = [OdbcConnection new];
    
    [self->connection connect : DataSourceName username : Username password : Password];
    
    NSString * dbms = self->connection.dbmsName;
    
    if (! [dbms hasPrefix : @"SQLite"]) {
    
        self->connection.transactionIsolation = SQL_TXN_SERIALIZABLE;
    }
    
    self->statement = [self->connection newStatement];
}

- (void) disconnect {
    
    [self->connection disconnect];
}

- (void) insertTestRows {
    
    [self deleteTestRows];
    
    NSArray * sqls;
    
    NSString * dbms = self->connection.dbmsName;
    
    if ([[dbms lowercaseString] hasPrefix:@"oracle"]) {
        
        sqls =
        
        @[@"insert into testtab values (1,'Name 1',1.1,date '2001-01-01',to_date ('01:01:01','HH24:MI:SS'),timestamp '2001-01-01 01:01:01')",
          @"insert into testtab values (2,'Name 2',2.2,date '2002-02-02',to_date ('02:02:02','HH24:MI:SS'),timestamp '2002-02-02 02:02:02')",
          @"insert into testtab values (3,'Name 3',3.3,date '2003-03-03',to_date ('03:03:03','HH24:MI:SS'),timestamp '2003-03-03 03:03:03')",
          @"insert into testtab values (4,'N4'    ,4.4,date '2004-04-04',to_date ('04:04:04','HH24:MI:SS'),timestamp '2004-04-04 04:04:04')"];
        
    } else if ([dbms hasPrefix : @"SQLite"]) {
        
        sqls =
        
        @[@"insert into testtab values (1,'Name 1',1.1,'2001-01-01','01:01:01','2001-01-01 01:01:01')",
          @"insert into testtab values (2,'Name 2',2.2,'2002-02-02','02:02:02','2002-02-02 02:02:02')",
          @"insert into testtab values (3,'Name 3',3.3,'2003-03-03','03:03:03','2003-03-03 03:03:03')",
          @"insert into testtab values (4,'N4'    ,4.4,'2004-04-04','04:04:04','2004-04-04 04:04:04')"];

    } else {

        sqls = 
   
        @[@"insert into testtab values (1,'Name 1',1.1,date '2001-01-01',time '01:01:01',timestamp '2001-01-01 01:01:01')",
          @"insert into testtab values (2,'Name 2',2.2,date '2002-02-02',time '02:02:02',timestamp '2002-02-02 02:02:02')",
          @"insert into testtab values (3,'Name 3',3.3,date '2003-03-03',time '03:03:03',timestamp '2003-03-03 03:03:03')",
          @"insert into testtab values (4,'N4'    ,4.4,date '2004-04-04',time '04:04:04',timestamp '2004-04-04 04:04:04')"];
    }
    
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
    
    NSString * createSql;
    
    NSString * dbms = self->connection.dbmsName;
    
    if ([[dbms lowercaseString] hasPrefix : @"oracle"]) {
        
        createSql = @"create table testtab ("
                     " id    number(20)   not null primary key,"
                     " name  varchar(128) not null unique,"
                     " price number(13,2),"
                     " \"DATE\"  date,"
                     " \"TIME\"  timestamp,"
                     " ts timestamp"
                     ")";

    } else {
    
        createSql = @"create table testtab ("
                     " id    bigint not null primary key,"
                     " name  varchar(128) not null unique,"
                     " price decimal(13,2),"
                     " date  date,"
                     " time  time,"
                     " ts timestamp"
                     ")";
    }
    
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
    
    @try {
    
        if (self->connection.connected) {
        
            [self dropTestTable];
    
            [self->connection disconnect];
    
            [super tearDown];
        }
    
    } @catch (NSException * exception) {
        
        STFail (exception.description);
    }
}

@end
