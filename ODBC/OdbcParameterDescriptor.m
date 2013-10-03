//
//  OdbcParameterDescriptor.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcParameterDescriptor.h"
#import "OdbcStatement.h"
#import "OdbcException.h"

#import <sql.h>
#import <sqlext.h>
#import <sqltypes.h>

@interface OdbcParameterDescriptor ()

@property OdbcStatement * statement;
@property int             parameterNumber;
@property short           dataType;
@property unsigned long   parameterSize;
@property short           decimalDigits;
@property bool            nullable;
@property short           valueType;
@property long            valueSize;
@property long            strLenOrInd;

@end

@implementation OdbcParameterDescriptor

@synthesize statement,parameterNumber,dataType,parameterSize,decimalDigits,nullable;

@synthesize valueType,valueSize,parameterValue,longValue,stringValue,doubleValue,strLenOrInd;

@synthesize dateValue, objectValue, numberValue;

+ (OdbcParameterDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber {
    
    OdbcParameterDescriptor * desc =
    
    [[OdbcParameterDescriptor alloc] initWithStatement : stmt parameterNumber : paramNumber];
    
    return desc;
}

- (OdbcParameterDescriptor *) initWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber {
    
    self = [super init];
    
    if (! self) return self;
    
    self.statement = stmt;
    
    self.parameterNumber = paramNumber;
    
    [self fetchDescription];
    
    return self;
}

- (void) fetchDescription {
    
    short rc;
    
    short null;
    
    rc = SQLDescribeParam (self.statement.hstmt,
                           self.parameterNumber,
                           &self->dataType,
                           &self->parameterSize,
                           &self->decimalDigits,
                           &null);
        
    CHECK_ERROR ("SQLDescribeParameter",rc,SQL_HANDLE_STMT,self.statement.hstmt);
    
    self->nullable = (null == SQL_NULLABLE ? YES : NO);
    
    NSAssert (self->parameterSize > 0,@"parameter size < 1");
    
    self->parameterValue.voidPtr = 0;

    self->valueType = -1;
    
    self->valueSize = 0;
}

- (void) dealloc {
    
    if (self.parameterValue.voidPtr) {
    
        free (self->parameterValue.voidPtr);
    }
}

- (long) longValue {
    
    return * self.parameterValue.longPtr;
}

- (void) setLongValue : (long) value {
    
    SQLSMALLINT type = SQL_C_LONG;
    
    SQLULEN size = sizeof (long);
    
    [self bindIfRequiredType : type size : size];
        
    (* self->parameterValue.longPtr) = value;
}

- (void) setDoubleValue : (double) value {
    
    SQLSMALLINT type = SQL_C_DOUBLE;
    
    SQLULEN size = sizeof (double);
    
    [self bindIfRequiredType : type size : size];
    
    (* self->parameterValue.doublePtr) = value;
}

- (void) setStringValue : (NSString *) value {
    
    const char * valuec = value.UTF8String;
    
    SQLSMALLINT type = SQL_C_CHAR;
    
    SQLULEN size = strlen (valuec);
    
    [self bindIfRequiredType : type size : size];
    
    strcpy (self.parameterValue.charPtr,valuec);
}

- (void) setDateValue : (NSDate *) value {
            
    SQLSMALLINT type = SQL_C_TYPE_DATE;
    
    SQLULEN size = sizeof (SQL_DATE_STRUCT);
    
    [self bindIfRequiredType : type size : size];
    
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
        
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents * dateComps = [gregorian components : unitFlags fromDate : value];
    
    self.parameterValue.datePtr->year = dateComps.year;
    
    self.parameterValue.datePtr->month = dateComps.month;
    
    self.parameterValue.datePtr->day = dateComps.day;
}

- (void) setObjectValue : (id) object {

    if ([object isKindOfClass : [NSString class]]) {
        
        self.stringValue = object;
        
    } else if ([object isKindOfClass: [NSDate class]]) {
        
        self.dateValue = object;
        
    } else if ([object isKindOfClass:[NSNumber class]]) {
        
        self.numberValue = object;
    
    } else {
        
        NSString * msg = [NSString stringWithFormat : @"Unsupported object type '%@'",[object class]];
        
        RAISE_ODBC_EXCEPTION ("setObjectValue",msg.UTF8String);
    }
}

- (void) setNumberValue : (NSNumber *) number {
    
    const char * ctype = number.objCType;
    
    switch (ctype[0]) {
        
        case 'f':
        case 'd': {
            
            double value = number.doubleValue;
            
            self.doubleValue = value;
            
            break;
        }
            
        default: {
            
            long value = number.longValue;
            
            self.longValue = value;
            
            break;
        }            
    }
}

- (void) bindIfRequiredType : (SQLSMALLINT) type size : (SQLULEN) size {
 
    SQLRETURN rc;
    
    if (self.parameterValue.voidPtr == 0 || self.valueType != type || self.valueSize < size) {
        
        if (self.parameterValue.voidPtr) free (self.parameterValue.voidPtr);
        
        self->parameterValue.voidPtr = malloc (size + 1);
        
        self->valueType = type;
        
        self->valueSize = size;
        
        self->strLenOrInd = size;
        
        rc = SQLBindParam (self.statement.hstmt,
                           self.parameterNumber,
                           self.valueType,
                           self.dataType,
                           self.parameterSize,
                           self.decimalDigits,
                           self.parameterValue.voidPtr,
                           &self->strLenOrInd);
        
        CHECK_ERROR ("SQLBindParam",rc,SQL_HANDLE_STMT,self.statement.hstmt);
        
    }
}

@end
