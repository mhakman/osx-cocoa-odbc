//
//  OdbcStatement.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcStatement.h"
#import "OdbcConnection.h"
#import "OdbcResultDescriptor.h"
#import "OdbcColumnDescriptor.h"
#import "OdbcException.h"
#import "OdbcPrepareDescriptor.h"
#import "OdbcParameterDescriptor.h"

#import <sql.h>
#import <sqlext.h>
#import <sqltypes.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface OdbcStatement ()

@property SQLHANDLE               hstmt;
@property OdbcConnection        * connection;
@property BOOL                    wasNull;
@property OdbcResultDescriptor  * resultDescriptor;
@property OdbcPrepareDescriptor * prepareDescriptor;

@end

@implementation OdbcStatement

@synthesize hstmt,connection,wasNull,resultDescriptor,prepareDescriptor;

+ (OdbcStatement *) statementWithConnection : newConnection {
    
    OdbcStatement * statement = [[OdbcStatement alloc] initWithConnection : newConnection];
    
    return statement;
}


- (OdbcStatement *) initWithConnection : newConnection {
    
    self = [super init];
    
    if (self) {
        
        self.connection = newConnection;
        
        [self allocHandle];
    }
    
    return self;
}

- (void) allocHandle {
    
    SQLRETURN rc;
    
    rc = SQLAllocHandle(SQL_HANDLE_STMT,self.connection.hdbc,&self->hstmt);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLAllocHandle");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLAllocHandle",SQL_HANDLE_DBC,self.connection.hdbc);
    }
}

- (void) dealloc {
    
    SQLRETURN rc;
    
    if (! self.connection.connected) return;
    
    rc = SQLFreeHandle (SQL_HANDLE_STMT,self.hstmt);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLFreeHandle");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLFreeHandle",SQL_HANDLE_STMT,self.hstmt);
    }
}

- (OdbcResultDescriptor *) resultDescriptor {
    
    if (self->resultDescriptor) return self->resultDescriptor;
    
    self->resultDescriptor = [OdbcResultDescriptor descriptorWithStatement : self];
        
    return self->resultDescriptor;
}

- (NSString *) getStringByName :( NSString *)columnName {
    
    int colNumber = [self.resultDescriptor columnNumberFor : columnName];
    
    return [self getString : colNumber];
}

- (NSString *) getString : (int) colNumber {
    
    unsigned long columnSize = [self.resultDescriptor columnDescriptorAtIndex:colNumber].columnSize;
    
    char * targetValue = malloc (columnSize + 1);
    
    targetValue[0] = 0;
    
    [self getData : colNumber valueType : SQL_C_CHAR targetPtr : targetValue valueSize : columnSize + 1];
    
    if (targetValue[0] == 0) {
        
        free (targetValue);
        
        return nil;
    }
    
    NSString * stringValue = [NSString stringWithUTF8String : targetValue];
    
    free (targetValue);
    
    return stringValue;
}

- (long) getLongByName : (NSString *) columnName {
    
    int colNumber = [self.resultDescriptor columnNumberFor : columnName];
    
    return [self getLong : colNumber];
}

- (long) getLong : (int) colNumber {
    
    long targetValue = 0;
    
    [self getData : colNumber valueType : SQL_C_LONG targetPtr : &targetValue valueSize : sizeof(long)];
    
    return targetValue;
}

- (double) getDoubleByName : (NSString *) columnName {
    
    int colNumber = [self.resultDescriptor columnNumberFor : columnName];
    
    return [self getDouble : colNumber];
}

- (double) getDouble : (int) colNumber {
    
    double targetValue = 0;
    
    [self getData : colNumber valueType : SQL_C_DOUBLE targetPtr : &targetValue valueSize : sizeof(double)];
        
    return targetValue;
}

- (NSDate *) getDateByName : (NSString *) columnName {
    
    int colNumber = [self.resultDescriptor columnNumberFor : columnName];

    return [self getDate : colNumber];
}

- (NSDate *) getDate : (int) colNumber {
    
    SQL_DATE_STRUCT targetValue;
    
    [self getData : colNumber valueType : SQL_C_TYPE_DATE targetPtr : &targetValue valueSize : sizeof(targetValue)];
    
    if (self->wasNull) return nil;
    
    NSDateComponents * dateComps = [NSDateComponents new];
    
    dateComps.year = targetValue.year;
    
    dateComps.month = targetValue.month;
    
    dateComps.day = targetValue.day;
        
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
    
    NSDate * date = [gregorian dateFromComponents: dateComps];
    
    return date;
}

- (void) getData : (int) columnNumber
       valueType : (short) valueType
       targetPtr : (void *) targetPtr
       valueSize : (SQLLEN) valueSize {
    
    SQLRETURN rc;
    
    long retLen = 0;
    
    self.wasNull = NO;
    
    rc = SQLGetData (self.hstmt,columnNumber,valueType,targetPtr,valueSize,&retLen);
    
    CHECK_ERROR ("SQLGetData",rc,SQL_HANDLE_STMT,self.hstmt);
    
    if (retLen == SQL_NULL_DATA || retLen == SQL_NO_TOTAL) self.wasNull = YES;
}

- (BOOL) fetch {
    
    SQLRETURN rc;
    
    rc = SQLFetch (self.hstmt);
    
    if (rc == SQL_NO_DATA) return NO;
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLFetch");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SqlFetch",SQL_HANDLE_STMT,self.hstmt);
    }
    
    return YES;
}

- (void) execDirect : (NSString *) sql {
    
    const char * sqlc = [sql UTF8String];
    
    SQLRETURN rc;
    
    rc = SQLExecDirect (self.hstmt,(SQLCHAR *)sqlc,(SQLINTEGER)strlen (sqlc));
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLExecDirect");
        
    } else if (rc != SQL_SUCCESS && rc != SQL_NO_DATA) {
        
        RAISE_ODBC_HANDLE ("SQLExecDirect",SQL_HANDLE_STMT,self.hstmt);
    }
    
    self.resultDescriptor = nil;
    
    self.prepareDescriptor = nil;
}

- (void) closeCursor {
    
    SQLRETURN rc;
    
    rc = SQLCloseCursor (self.hstmt);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLCloseCursor");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLCloseCursor",SQL_HANDLE_STMT,self.hstmt);
    }
}

- (OdbcPrepareDescriptor *) prepareDescriptor {
    
    if (self->prepareDescriptor) return self->prepareDescriptor;
    
    self->prepareDescriptor = [OdbcPrepareDescriptor descriptorWithStatement : self];
    
    return self->prepareDescriptor;
}

- (void) prepare : (NSString *) sql {
    
    short rc;
    
    const char * sqlc = sql.UTF8String;
    
    rc = SQLPrepare (self.hstmt,(SQLCHAR *)sqlc,SQL_NTS);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLPrepare");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLPrepare",SQL_HANDLE_STMT,self.hstmt);
    }
    
    self.prepareDescriptor = nil;
}

- (void) setLong : (int) parameterNumber value : (long) value {
    
    OdbcParameterDescriptor * desc = [self.prepareDescriptor parameterDescriptorAtIndex : parameterNumber];
    
    desc.longValue = value;
}

- (void) setString : (int) parameterNumber value : (NSString *) value {
    
    OdbcParameterDescriptor * desc = [self.prepareDescriptor parameterDescriptorAtIndex : parameterNumber];

    desc.stringValue = value;
}

- (void) setDouble : (int) parameterNumber value : (double) value {
    
    OdbcParameterDescriptor * desc = [self.prepareDescriptor parameterDescriptorAtIndex : parameterNumber];
    
    desc.doubleValue = value;
}

- (void) setDate : (int) parameterNumber value : (NSDate *) value{

    OdbcParameterDescriptor * desc = [self.prepareDescriptor parameterDescriptorAtIndex : parameterNumber];

    desc.dateValue = value;
}

- (void) execute {
    
    SQLRETURN rc;
    
    rc = SQLExecute (self.hstmt);
    
    if (rc == SQL_SUCCESS_WITH_INFO || rc == SQL_ERROR || rc == SQL_INVALID_HANDLE) {
        
        CHECK_ERROR ("SQLExecute",rc,SQL_HANDLE_STMT,self.hstmt);
    }
}

@end
