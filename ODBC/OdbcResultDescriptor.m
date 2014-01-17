//
//  OdbcResultDescriptor.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcResultDescriptor.h"
#import "OdbcStatement.h"
#import "OdbcColumnDescriptor.h"
#import "OdbcException.h"

#import <iODBC/sql.h>
#import <iODBC/sqltypes.h>
#import <iODBC/sqlext.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface OdbcResultDescriptor ()

@property OdbcStatement * statement;
@property NSArray       * columnDescriptors;
@property int             numResultCols;
@property NSDictionary  * columnNameToNumberDict;

@end

@implementation OdbcResultDescriptor

@synthesize statement,columnDescriptors,columnNameToNumberDict;

+ (OdbcResultDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt {
    
    OdbcResultDescriptor * desc = [[OdbcResultDescriptor alloc] initWithStatement : stmt];
    
    return desc;
}

- (OdbcResultDescriptor *) initWithStatement : (OdbcStatement *) stmt {
    
    self = [super init];
    
    if (! self) return self;
    
    self.statement = stmt;
    
    [self fetchDescriptor];
    
    return self;
}

- (void) fetchDescriptor {
    
    self.numResultCols = [self fetchNumResultCols];
    
    self->columnDescriptors = [NSMutableArray new];
    
    self->columnNameToNumberDict = [NSMutableDictionary new];
    
    for (int icol = 1; icol <= self.numResultCols; icol++) {
        
        OdbcColumnDescriptor * colDesc =
        
        [OdbcColumnDescriptor descriptorWithStatement : self.statement columnNumber : icol];
        
        [self->columnDescriptors addObject : colDesc];
        
        [self->columnNameToNumberDict setObject : [NSNumber numberWithInt : icol]
                                         forKey : [colDesc.columnName uppercaseString]];
    }
}

- (int) fetchNumResultCols {
 
    SQLRETURN rc;
    
    SQLSMALLINT columnCount = 0;
    
    rc = SQLNumResultCols (self.statement.hstmt,&columnCount);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLNumResultCols");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLNumResultCols",SQL_HANDLE_STMT,self.statement.hstmt);
    }
    
    return columnCount;
}

- (OdbcColumnDescriptor *) columnDescriptorAtIndex : (int) index {
    
    if (index < 1 || index > self.numResultCols) {
        
        [NSException raise : NSRangeException format : @"index argument is out of range: %d",index];
    }
    
    return [self.columnDescriptors objectAtIndex : index - 1];
}

- (int) columnNumberFor : (NSString *) columnName {
    
    NSNumber * number = [self.columnNameToNumberDict valueForKey : [columnName uppercaseString]];
    
    if (! number) [NSException raise : NSInvalidArgumentException format : @"cannot find column named %@",columnName];
    
    return number.intValue;
}

@end
