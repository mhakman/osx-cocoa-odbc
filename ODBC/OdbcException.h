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
    raiseOdbcHandle ((__PRETTY_FUNCTION__),(function),(handleType),(handle));   \
}

#define RAISE_INVALID_HANDLE(function) {                    \
                                                            \
    raiseInvalidHandle ((__PRETTY_FUNCTION__),(function));  \
}

#define RAISE_ODBC_EXCEPTION(function,message) {                        \
                                                                        \
    raiseOdbcException ((__PRETTY_FUNCTION__),(function),(message));    \
}

#define CHECK_ERROR(function,rc,handleType,handle) {                    \
                                                                        \
    if (rc == SQL_INVALID_HANDLE) {                                     \
                                                                        \
        RAISE_INVALID_HANDLE (function);                                \
                                                                        \
    } else if (rc != SQL_SUCCESS) {                                     \
                                                                        \
        RAISE_ODBC_HANDLE (function,handleType,handle);                 \
    }                                                                   \
}

void raiseInvalidHandle (const char * method, const char * function);

void raiseOdbcHandle (const char * method, const char * function, SQLSMALLINT handleType, SQLHANDLE handle);

void raiseOdbcException (const char * method, const char * function, const char * message);

@interface OdbcException : NSException

- (NSString *) name;

+ (void) raiseInvalidHandle : (const char *) method
                   function : (const char *) function;

+ (void) raiseOdbcHandle : (const char *) method
                function : (const char *) function
              handleType : (SQLSMALLINT) handleType
                  handle : (SQLHANDLE) handle;

+ (void) raiseOdbcException : (const char *) method
                   function : (const char *) function
                    message : (const char *) message;

@end
