//
//  OdbcTests.m
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "ConnectionTests.h"

#import <Odbc/Odbc.h>

@interface ConnectionTests ()
    
@end

@implementation ConnectionTests

- (void) setUp {
    
    [super setUp];    
}

- (void) tearDown {
    
    [super tearDown];    
}

- (void) testNew {
    
    OdbcConnection * newConnection = [OdbcConnection new];
    
    STAssertNotNil (newConnection,@"Cannot create connection");
}

- (void) testConnect {
    
    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" user : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testDisconnect {

    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" user : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testCommit {
    
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

- (void) testRollback {
    
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

- (void) testNewStatement {
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    STAssertNotNil (stmt,@"Stmt is nil");
}

- (void) testTablesCatalogSchemaTableTableTypes {
    
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

- (void) testHdbc {
    
    if (! self->connection.hdbc) {
        
        STFail (@"HDBC is nil");
    }
}

- (void) testEnv {
    
    STAssertNotNil (self->connection.env,@"ENV is nil");
}

- (void) testConnected {
    
    [self disconnect];
    
    STAssertFalse (self->connection.connected,@"Connected is true");
    
    [self connect];
    
    STAssertTrue (self->connection.connected,@"Connected is false");
}

- (void) testTransactionIsolation {
    
    long curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"Wrong isolation level");
    
    self->connection.transactionIsolation = SQL_TXN_READ_UNCOMMITTED;
    
    long newTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (newTxnIsolation,SQL_TXN_READ_UNCOMMITTED,@"Wrong isolation level");
    
    self->connection.transactionIsolation = SQL_TXN_REPEATABLE_READ;
    
    curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"Wrong isolation level");
}

- (void) testAutocommit {
    
    STAssertFalse (self->connection.autocommit,@"");
    
    self->connection.autocommit = YES;
    
    STAssertTrue (self->connection.autocommit,@"");
    
    self->connection.autocommit = NO;
    
    STAssertFalse (self->connection.autocommit,@"");
}

@end
