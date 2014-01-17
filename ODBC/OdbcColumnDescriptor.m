//
//  OdbcColumnDescriptor.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcColumnDescriptor.h"
#import "OdbcStatement.h"
#import "OdbcException.h"

#import <iODBC/sql.h>
#import <iODBC/sqltypes.h>
#import <IODBC/sqlext.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface OdbcColumnDescriptor ()

@property OdbcStatement * statement;
@property int             columnNumber;
@property NSString      * columnName;
@property short           dataType;
@property unsigned long   columnSize;
@property short           decimalDigits;
@property BOOL            nullable;

@end

@implementation OdbcColumnDescriptor

@synthesize statement,columnNumber,columnName,dataType,columnSize,decimalDigits,nullable;

+ (OdbcColumnDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt columnNumber : (int) colNo {
    
    OdbcColumnDescriptor * desc = [[OdbcColumnDescriptor alloc] initWithStatement : stmt columnNumber : colNo];
    
    return desc;
}

- (OdbcColumnDescriptor *) initWithStatement : (OdbcStatement *) stmt columnNumber : (int) colNo {
    
    self = [super init];
    
    if (! self) return self;
    
    self.statement = stmt;
    
    self.columnNumber = colNo;
    
    [self fetchDescriptor];
    
    return self;
}

- (void) fetchDescriptor {
    
    SQLRETURN rc;
    
    SQLCHAR colName [128];
    
    SQLSMALLINT nameLength = 0;
        
    SQLSMALLINT nullsPermitted = 0;
        
    rc = SQLDescribeCol (self.statement.hstmt,
                         self->columnNumber,
                         colName,
                         sizeof (colName),
                         &nameLength,
                         &self->dataType,
                         &self->columnSize,
                         &self->decimalDigits,
                         &nullsPermitted);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLDescribeCol");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLDescribeCol",SQL_HANDLE_STMT,self.statement.hstmt);
    }
    
    self.columnName = [NSString stringWithUTF8String : (char *)colName];
    
    self.nullable = (nullsPermitted == 0 ? NO : YES);
}

@end
