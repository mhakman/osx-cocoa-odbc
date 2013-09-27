//
//  OdbcParameterDescriptor.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sql.h>

@class OdbcStatement;

typedef union parameter_value_def {
    
    void   * voidPtr;
    long   * longPtr;
    char   * charPtr;
    double * doublePtr;
    
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
@property (nonatomic) NSString       * stringValue;
@property (nonatomic) double           doubleValue;

+ (OdbcParameterDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber;

- (OdbcParameterDescriptor *) initWithStatement : (OdbcStatement *) stmt parameterNumber : (int) paramNumber;

@end
