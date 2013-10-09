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
    
    STAssertNotNil (newConnection,@"");
}

- (void) testConnect {
    
    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" username : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testDisconnect {

    OdbcConnection * newConnection = [OdbcConnection new];
    
    [newConnection connect : @"testdb" username : @"root" password : nil];
    
    [newConnection disconnect];
}

- (void) testCommit {
    
    NSString * sql = @"insert into testtab values (10,'Testing commit',10,'2010-10-10','10:10:10','2010-10-10 10:10:10')";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    [self->connection commit];
    
    [self disconnect];
    
    [self connect];
    
    sql = @"select * from testtab where id = 10";
    
    stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    bool found = [stmt fetch];
    
    STAssertTrue (found,@"");
    
    [stmt closeCursor];
    
    [self->connection commit];
    
    sql = @"delete from testtab where id = 10";
    
    [stmt execDirect : sql];
    
    [self->connection commit];
}

- (void) testRollback {
    
    NSString * sql = @"insert into testtab values (10,'Testing commit',10,'2010-10-10','10:10:10','2010-10-10 10:10:10')";
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    [self->connection rollback];
    
    [self disconnect];
    
    [self connect];
    
    sql = @"select * from testtab where id = 10";
    
    stmt = [self->connection newStatement];
    
    [stmt execDirect : sql];
    
    bool found = [stmt fetch];
    
    STAssertFalse (found,@"");
    
    [stmt closeCursor];    
}

- (void) testNewStatement {
    
    OdbcStatement * stmt = [self->connection newStatement];
    
    STAssertNotNil (stmt,@"");
}

- (void) testTablesCatalogSchemaTableTableTypes {
    
    OdbcStatement * stmt = [self->connection tablesCatalog : @"testdb"
                                                    schema : @"%"
                                                     table : @"testtab"
                                                tableTypes : @""];
    
    bool found = [stmt fetch];
    
    STAssertTrue (found,@"");
    
    NSString * catalog = [stmt getStringByName : @"TABLE_CAT"];
    
    STAssertEqualObjects (@"testdb",catalog,@"");
    
    NSString * schema = [stmt getStringByName : @"TABLE_SCHEM"];
    
    STAssertNil (schema,@"");
    
    NSString * table = [stmt getStringByName : @"TABLE_NAME"];
    
    STAssertEqualObjects (@"testtab",table,@"");
    
    NSString * tableType = [stmt getStringByName : @"TABLE_TYPE"];
    
    STAssertEqualObjects (@"TABLE",tableType,@"");
    
    found = [stmt fetch];
    
    STAssertFalse (found,@"");
    
    [stmt closeCursor];
    
    [self->connection commit];
}

- (void) testHdbc {
    
    if (! self->connection.hdbc) {
        
        STFail (@"HDBC is nil");
    }
}

- (void) testEnv {
    
    STAssertNotNil (self->connection.env,@"");
}

- (void) testConnected {
    
    [self disconnect];
    
    STAssertFalse (self->connection.connected,@"");
    
    [self connect];
    
    STAssertTrue (self->connection.connected,@"");
}

- (void) testTransactionIsolation {
    
    long curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"");
    
    self->connection.transactionIsolation = SQL_TXN_READ_UNCOMMITTED;
    
    long newTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (newTxnIsolation,SQL_TXN_READ_UNCOMMITTED,@"");
    
    self->connection.transactionIsolation = SQL_TXN_REPEATABLE_READ;
    
    curTxnIsolation = self->connection.transactionIsolation;
    
    STAssertEquals (curTxnIsolation,SQL_TXN_REPEATABLE_READ,@"");
}

- (void) testAutocommit {
    
    STAssertFalse (self->connection.autocommit,@"");
    
    self->connection.autocommit = YES;
    
    STAssertTrue (self->connection.autocommit,@"");
    
    self->connection.autocommit = NO;
    
    STAssertFalse (self->connection.autocommit,@"");
}

- (void) testDataSource {
    
    STAssertEqualObjects (self->connection.dataSource,@"testdb",@"");
}

- (void) testUsername {
    
    STAssertEqualObjects(self->connection.username,@"root",@"");
}

- (void) testCatalogs {
    
    NSArray * catalogs = self->connection.catalogs;
    
    STAssertTrue ([catalogs count] > 0,@"");
    
    long index = [catalogs indexOfObject : @"testdb"];
    
    STAssertTrue (index >= 0,@"");
    
    NSString * catalog = [catalogs objectAtIndex : index];
    
    STAssertEqualObjects (catalog,@"testdb",@"");
}

- (void) testScemas {
    
    NSArray * schemas = self->connection.schemas;
    
    long count = [schemas count];
    
    STAssertTrue (count > 0,@"");
}

- (void) testTableTypes {
    
    NSArray * tableTypes = self->connection.tableTypes;
    
    long index = [tableTypes indexOfObject : @"TABLE"];
    
    STAssertTrue (index >= 0,@"");
}

- (void) testCurrentCatalog {
    
    NSString * catalog = self->connection.currentCatalog;
    
    if (catalog.length > 0) {
        
        STAssertEqualObjects (catalog,@"testdb",@"");
    }
}

- (void) testCurrentUser {
    
    NSString * user = self->connection.currentUser;
    
    STAssertEqualObjects (user,@"root",@"");
}

- (void) testSchemaTerm {
    
    NSString * term = self->connection.schemaTerm;
    
    STAssertNotNil (term,@"");
}

- (void) testCurrentSchema {
    
    NSString * schema = self->connection.currentSchema;
    
    if (schema.length > 0) {
        
        STAssertEqualObjects (schema,self->connection.currentUser,@"");
    }
}

- (void) testExecDirect {
    
    OdbcStatement * stmt = [self->connection execDirect : @"select * from testtab"];
    
    bool found = [stmt fetch];
    
    STAssertTrue (found,@"");
    
    [stmt closeCursor];
}

@end
