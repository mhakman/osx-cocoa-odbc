//
//  StatementTests.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-01.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "StatementTests.h"

#import <Odbc/Odbc.h>

@implementation StatementTests

- (void) setUp {
    
    [super setUp];
}

- (void) tearDown {
    
    [super tearDown];
}

- (NSDate *) dateYear : (int) year month : (int) month day : (int) day {
    
    NSDateComponents * dateComps = [NSDateComponents new];
    
    dateComps.year = year;
    
    dateComps.month = month;
    
    dateComps.day = day;
    
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
    
    NSDate * date = [gregorian dateFromComponents: dateComps];
    
    return date;
}

- (void) testStatementWithConnection {
    
    OdbcStatement * stmt = [OdbcStatement statementWithConnection : self->connection];
        
    STAssertEqualObjects (stmt.connection,self->connection,@"");
}

- (void) testInitWithConnection {
    
    OdbcStatement * stmt = [[OdbcStatement alloc] initWithConnection : self->connection];

    STAssertEqualObjects (stmt.connection,self->connection,@"");
}

- (void) testExecDirect {
    
    [self->statement execDirect : @"select * from testtab"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
    }
    
    STAssertEquals (rowCount,3,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testFetch {

    [self->statement execDirect : @"select * from testtab"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
    }
    
    STAssertEquals (rowCount,3,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testCloseCursor {
    
    [self->statement execDirect : @"select * from testtab"];
    
    [self->statement closeCursor];

    [self->statement execDirect : @"select * from testtab"];

    [self->statement closeCursor];

    [self->connection commit];
}

- (void) testPrepare {
    
    [self->statement prepare : @"select * from testtab where id = ? and name = ? and price = ?"];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals(objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testExecute {
    
    [self->statement prepare : @"select * from testtab where id = ? and name = ? and price = ?"];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals(objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testGetData {
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        if (rowCount < 3) continue;
        
        long objId = [self->statement getLong : 1];
        
        STAssertEquals (objId,3L,@"");
        
        NSString * name = [self->statement getString : 2];
        
        STAssertEqualObjects (name,@"Name 3",@"");
        
        double price = [self->statement getDouble : 3];
        
        STAssertEquals (price,3.3,@"");
        
        NSDate * date1 = [self->statement getDate : 4];
        
        NSDate * date2 = [self dateYear : 2003 month : 3 day : 3];
        
        STAssertEquals (date1,date2,@"");
    }
    
    STAssertEquals(rowCount,3,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testGetDataByName {
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        if (rowCount < 3) continue;
        
        long objId = [self->statement getLongByName : @"id"];
        
        STAssertEquals (objId,3L,@"");
        
        NSString * name = [self->statement getStringByName : @"name"];
        
        STAssertEqualObjects (name,@"Name 3",@"");
        
        double price = [self->statement getDoubleByName : @"price"];
        
        STAssertEquals (price,3.3,@"");
        
        NSDate * date1 = [self->statement getDateByName : @"date"];
                
        NSDate * date2 = [self dateYear : 2003 month : 3 day : 3];

        STAssertEquals (date1,date2,@"");
    }
    
    STAssertEquals (rowCount,3,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testSetData {
    
    [self->statement prepare : @"select * from testtab where id = ? and name = ? and price = ? and date = ?"];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * date = [self dateYear : 2001 month : 1 day : 1];
    
    [self->statement setDate : 4 value : date];
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    date = [self dateYear : 2002 month : 2 day : 2];
    
    [self->statement setDate : 4 value : date];
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testHstmt {
    
    STAssertTrue (self->statement.hstmt != 0,@"");
}

- (void) testConnection {
    
    STAssertEqualObjects (self->statement.connection,self->connection,@"");
}

- (void) testWasNull {
    
    [self->statement execDirect : @"insert into testtab (id,name) values (10,'Name 10')"];
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        long objId = [self->statement getLongByName : @"id"];
        
        double price = [self->statement getDoubleByName : @"price"];
        
        bool wasNull = [self->statement wasNull];
        
        if (objId < 10) {
            
            STAssertFalse (wasNull,@"");
            
        } else {
            
            STAssertTrue (wasNull,@"");
            
            STAssertEquals (price,0.0,@"");
        }
    }
    
    STAssertEquals (rowCount,4,@"");
    
    [self->statement closeCursor];
    
    [self->connection rollback];
}

@end
