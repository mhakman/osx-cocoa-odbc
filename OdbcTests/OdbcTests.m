//
//  OdbcTests.m
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcTests.h"

#import <Odbc/Odbc.h>

@interface OdbcTests () {
    
@protected
    
    OdbcConnection * connection;
}

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
    
    //[self dropTestTable];
    
    [self->connection disconnect];
    
    [super tearDown];
}

- (void) testConnectionNew {
    
    OdbcConnection * newConnection = [OdbcConnection new];
    
    STAssertNotNil (newConnection,@"Cannot create connection");
}

- (void) testConnectionConnect {
    
    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" user : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testConnectionDisconnect {

    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" user : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testConnectionCommit {
    
    NSString * sql = @"insert into testtab values (10,'Testing commit',10)";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    [self->connection commit];
    
    [self disconnect];
    
    [self connect];
    
    sql = @"select * from testtab where id = 10";
    
    stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    bool found = [stmt fetch];
    
    STAssertTrue (found,@"Row not found");
    
    [stmt closeCursor];
    
    [self->connection commit];
    
    sql = @"delete from testtab where id = 10";
    
    [stmt execDirect : sql];
    
    [self->connection commit];
}

- (void) testConnectionRollback {
    
    NSString * sql = @"insert into testtab values (10,'Testing commit',10)";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    [self->connection rollback];
    
    [self disconnect];
    
    [self connect];
    
    sql = @"select * from testtab where id = 10";
    
    stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    bool found = [stmt fetch];
    
    STAssertFalse (found,@"Row found");
    
    [stmt closeCursor];    
}

- (void) testConnectionNewStatement {
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    STAssertNotNil (stmt,@"Stmt is nil");
}

- (void) testConnectionTablesCatalogSchemaTableTableTypes {
    
    OdbcStatement * stmt = [self->connection tablesCatalog : @"testdb"
                                                    schema : @"%"
                                                     table : @"testtab"
                                                tableTypes : @""];
    
    bool found = [stmt fetch];
    
    STAssertTrue (found,@"Table not found");
    
    NSString * catalog = [stmt getStringByName : @"TABLE_CAT"];
    
    STAssertEqualObjects (@"testdb",catalog,@"Catalog is wrong");
    
    NSString * schema = [stmt getStringByName : @"TABLE_SCHEM"];
    
    STAssertNil (schema,@"Schema is not nil");
    
    NSString * table = [stmt getStringByName : @"TABLE_NAME"];
    
    STAssertEqualObjects (@"testtab",table,@"Table is wrong");
    
    NSString * tableType = [stmt getStringByName : @"TABLE_TYPE"];
    
    STAssertEqualObjects (@"TABLE",tableType,@"Table type is wrong");
    
    found = [stmt fetch];
    
    STAssertFalse (found,@"Found more than 1 table");
    
    [stmt closeCursor];
    
    [self->connection commit];
}

- (void) testConnectionHdbc {
    
    if (! self->connection.hdbc) {
        
        STFail (@"HDBC is nil");
    }
}

- (void) testConnectionEnv {
    
    STAssertNotNil (self->connection.env,@"ENV is nil");
}

- (void) testConnectionConnected {
    
    [self disconnect];
    
    STAssertFalse (self->connection.connected,@"Connected is true");
    
    [self connect];
    
    STAssertTrue (self->connection.connected,@"Connected is false");
}

- (void) testConnectionTransactionIsolation {
    
    long curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"Wrong isolation level");
    
    self->connection.transactionIsolation = SQL_TXN_READ_UNCOMMITTED;
    
    long newTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (newTxnIsolation,SQL_TXN_READ_UNCOMMITTED,@"Wrong isolation level");
    
    self->connection.transactionIsolation = SQL_TXN_REPEATABLE_READ;
    
    curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"Wrong isolation level");
}

- (void) testConnectionAutocommit {
    
    STAssertFalse (self->connection.autocommit,@"");
    
    self->connection.autocommit = YES;
    
    STAssertTrue (self->connection.autocommit,@"");
    
    self->connection.autocommit = NO;
    
    STAssertFalse (self->connection.autocommit,@"");
}

@end
