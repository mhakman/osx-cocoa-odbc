//
//  OdbcParameterDescriptor.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <iODBC/sql.h>
#import <iODBC/sqlext.h>
#import <iODBC/sqltypes.h>

@class OdbcStatement;

typedef union parameter_value_def {
    
    void                 * voidPtr;
    long                 * longPtr;
    unsigned long        * unsignedLongPtr;
    char                 * charPtr;
    double               * doublePtr;
    SQL_DATE_STRUCT      * datePtr;
    SQL_TIME_STRUCT      * timePtr;
    SQL_TIMESTAMP_STRUCT * timestampPtr;
    
} PARAMETER_VALUE;

@interface OdbcParameterDescriptor : NSObject {
        
@protected
        
    SQLSMALLINT     dataType;
    SQLULEN         parameterSize;
    SQLSMALLINT     decimalDigits;
    bool            nullable;
    PARAMETER_VALUE parameterValue;
    SQLSMALLINT     valueType;
    SQLLEN          valueSize;
    SQLLEN          strLenOrInd;
}

@property (readonly)  OdbcStatement  * statement;
@property (readonly)  int              parameterNumber;
@property (readonly)  short            dataType;
@property (readonly)  unsigned long    parameterSize;
@property (readonly)  short            decimalDigits;
@property (readonly)  bool             nullable;
@property (readonly)  short            valueType;
@property (readonly)  long             valueSize;
@property (readonly)  long             strLenOrInd;
@property (nonatomic) PARAMETER_VALUE  parameterValue;
@property (nonatomic) long             longValue;
@property (nonatomic) unsigned long    unsignedLongValue;
@property (nonatomic) NSString       * stringValue;
@property (nonatomic) double           doubleValue;
@property (nonatomic) NSDate         * dateValue;
@property (nonatomic) id               objectValue;
@property (nonatomic) NSNumber       * numberValue;
@property (nonatomic) NSDate         * timeValue;
@property (nonatomic) NSDate         * timestampValue;

+ (OdbcParameterDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber;

- (OdbcParameterDescriptor *) initWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber;

@end
