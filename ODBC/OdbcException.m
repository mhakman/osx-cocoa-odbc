//
//  OdbcException.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcException.h"

#import <iODBC/sql.h>
#import <iODBC/sqltypes.h>
#import <iODBC/sqlext.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

void raiseInvalidHandle (const char * method, const char * function) {
    
    [OdbcException raiseInvalidHandle : method function : function];
    
}

void raiseOdbcHandle (const char * method, const char * function, SQLSMALLINT handleType, SQLHANDLE handle) {
    
    [OdbcException raiseOdbcHandle : method function : function handleType : handleType handle : handle];
}

void raiseOdbcException (const char * method, const char * function, const char * message) {
    
    [OdbcException raiseOdbcException : method function : function message : message];
}

void raiseOdbcExceptionWithSqlState (const char * method,
                                     const char * function,
                                     const char * message,
                                     const char * sqlState) {

    [OdbcException raiseOdbcException : method function : function message : message sqlState : sqlState];
}

@interface OdbcException ()

@end


@implementation OdbcException

- (NSString *) description {
    
    if (! self.userInfo) return [super description];
    
    NSString * sqlState = [self.userInfo objectForKey : @"sqlState"];
    
    NSString * nativeError = [self.userInfo objectForKey : @"nativeError"];
    
    NSString * messageText = [self.userInfo objectForKey : @"messageText"];
    
    NSString * sqlFunction = [self.userInfo objectForKey : @"sqlFunction"];
    
    NSString * odbcMethod = [self.userInfo objectForKey : @"odbcMethod"];
    
    NSString * desc =
    
    [NSString stringWithFormat : @"Odbc Error\n\nOdbc errror in %@ at %@ sql state: %@ native error: %@ message text: %@",
                                 odbcMethod,sqlFunction,sqlState,nativeError,messageText];
    
    return desc;
}

- (NSString *) name {
    
    return NSStringFromClass ([self class]);
}

+ (void) raiseInvalidHandle : (const char *) method
                   function : (const char *) function {
    
    [OdbcException raise : NSStringFromClass ([self class])
                  format : @"Error in %s at %s: invalid handle",method,function];
    
}

+ (void) raiseOdbcHandle : (const char *) method
                function : (const char *) function
              handleType : (SQLSMALLINT) handleType
                  handle : (SQLHANDLE) handle {
    
    NSMutableDictionary * diagRec = [self diagRec : handleType handle : handle];
    
    [diagRec setObject : [NSString stringWithUTF8String : function] forKey : @"sqlFunction"];
    
    [diagRec setObject : [NSString stringWithUTF8String : method] forKey : @"odbcMethod"];
        
    OdbcException * exception = (OdbcException *) [OdbcException exceptionWithName : NSStringFromClass ([self class])
                                                                            reason : @"Odbc Error"
                                                                          userInfo : diagRec];
    [exception raise];
    
}

+ (void) raiseOdbcException : (const char *) method
                   function : (const char *) function
                    message : (const char *) message {
    
    [OdbcException raise : NSStringFromClass ([self class])
                  format : @"error in %s at %s: %s",
                           method,
                           function,
                           message];
}

+ (void) raiseOdbcException : (const char *) method
                   function : (const char *) function
                    message : (const char *) message
                   sqlState : (const char *) sqlState {
    
    NSDictionary * diagRec =
    
    [NSDictionary dictionaryWithObject : [NSString stringWithUTF8String : sqlState] forKey : @"sqlState"];
    
    OdbcException * exception = (OdbcException *) [OdbcException exceptionWithName : NSStringFromClass ([self class])
                                                                            reason : @"Odbc Error"
                                                                          userInfo : diagRec];
    [exception raise];
}


+ (NSMutableDictionary *) diagRec : (SQLSMALLINT) handleType handle : (SQLHANDLE) handle {
  
    SQLRETURN rc;
    
    char sqlState [6] = "";
    
    SQLINTEGER nativeError = 0;
    
    char messageText [512] = "";
    
    SQLSMALLINT retLen = 0;
    
    rc = SQLGetDiagRec (handleType,
                        handle,
                        1,
                        (SQLCHAR *)sqlState,
                        &nativeError,
                        (SQLCHAR *)messageText,
                        sizeof (messageText),
                        &retLen);
    
    if (rc == SQL_NO_DATA) {
        
        strcpy ((char *)sqlState,"00000");

        nativeError = 0;
        
        messageText[0] = 0;
        
    } else if (rc == SQL_SUCCESS) {
        
        ;
        
    } else {
        
        [NSException raise : @"SQL Exception" format : @"SQLGetDiagRec return code %d",rc];
    }
    
    if (sqlState[0] == 0) {
        
        strcpy ((char *)sqlState,"00000");
    }

    NSMutableDictionary * diagDict =

    [NSMutableDictionary dictionaryWithObjectsAndKeys : [NSString stringWithUTF8String : sqlState]   ,@"sqlState",
                                                        [NSNumber numberWithShort      : nativeError],@"nativeError",
                                                        [NSString stringWithUTF8String : messageText],@"messageText",
                                                        nil];
    
    return diagDict;
}

@end
