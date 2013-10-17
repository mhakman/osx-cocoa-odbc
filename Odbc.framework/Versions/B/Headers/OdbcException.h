//
//  OdbcException.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sql.h>
#import <sqlext.h>
#import <sqltypes.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#define RAISE_ODBC_HANDLE(function,handleType,handle) {                         \
                                                                                \
    raiseOdbcHandle ((__FILE__),(__LINE__),(function),(handleType),(handle));   \
}

#define RAISE_INVALID_HANDLE(function) {                    \
                                                            \
    raiseInvalidHandle ((__FILE__),(__LINE__),(function));  \
}

#define RAISE_ODBC_EXCEPTION(function,message) {                        \
                                                                        \
    raiseOdbcException ((__FILE__),(__LINE__),(function),(message));    \
}

#define CHECK_ERROR(function,rc,handleType,handle) {                    \
                                                                        \
    if (rc == SQL_INVALID_HANDLE) {                                     \
                                                                        \
        RAISE_INVALID_HANDLE (function);                                \
                                                                        \
    } else if (rc != SQL_SUCCESS) {                                     \
                                                                        \
        RAISE_ODBC_HANDLE (function,handleType,handle);  \
    }                                                                   \
}

void raiseInvalidHandle (const char * file, int line, const char * function);

void raiseOdbcHandle (const char * file, int line, const char * function, SQLSMALLINT handleType, SQLHANDLE handle);

void raiseOdbcException (const char * file, int line, const char * function, const char * message);

@interface OdbcException : NSException

@property (readonly,nonatomic) NSString * userDescription;

- (NSString *) name;

+ (void) raiseInvalidHandle : (const char *) file
                       line : (int) line
                   function : (const char *) function;

+ (void) raiseOdbcHandle : (const char *) file
                    line : (int) line
                function : (const char *) function
              handleType : (SQLSMALLINT) handleType
                  handle : (SQLHANDLE) handle;

+ (void) raiseOdbcException : (const char *) file
                       line : (int) line
                   function : (const char *) function
                    message : (const char *) message;

@end
