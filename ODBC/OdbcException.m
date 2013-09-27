//
//  OdbcException.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcException.h"

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

void raiseInvalidHandle (const char * file, int line, const char * function) {
    
    [OdbcException raiseInvalidHandle : file line : line function : function];
    
}

void raiseOdbcHandle (const char * file, int line, const char * function, SQLSMALLINT handleType, SQLHANDLE handle) {
    
    [OdbcException raiseOdbcHandle : file line : line function : function handleType : handleType handle : handle];
}

void raiseOdbcException (const char * file, int line, const char * function, const char * message) {
    
    [OdbcException raiseOdbcException : file line : line function : function message : message];
}

@interface OdbcException ()

@property NSString * userDescription;

@end


@implementation OdbcException

@synthesize userDescription;

- (NSString *) userDescription {
    
    NSRange range = [self.description rangeOfString : @": "];
    
    NSString * text = [self.description substringFromIndex:range.location + 2];
    
    return text;

}

- (NSString *) name {
    
    return NSStringFromClass ([self class]);
}

+ (void) raiseInvalidHandle : (const char *) file
                       line : (int) line
                   function : (const char *) function {
    
    [OdbcException raise : NSStringFromClass ([self class])
                  format : @"Error in %s line %d: %s invalid handle",file,line,function];
    
}

+ (void) raiseOdbcHandle : (const char *) file
                    line : (int) line
                function : (const char *) function
              handleType : (SQLSMALLINT) handleType
                  handle : (SQLHANDLE) handle {
    
    NSDictionary * diagRec = [self diagRec : handleType handle : handle];
        
    [OdbcException raise : NSStringFromClass ([self class])
                  format : @"Error in %s line %d: %s sqlState: %@ nativeError: %@ messageText: %@",
                           file,
                           line,
                           function,
                           [diagRec objectForKey : @"sqlState"],
                           [diagRec objectForKey : @"nativeError"],
                           [diagRec objectForKey : @"messageText"]];
     
    
}

+ (void) raiseOdbcException : (const char *) file
                       line : (int) line
                   function : (const char *) function
                    message : (const char *) message {
    
    [OdbcException raise : NSStringFromClass ([self class])
                  format : @"error in %s line %d: %s: %s",
                           file,
                           line,
                           function,
                           message];
}


+ (NSDictionary *) diagRec : (SQLSMALLINT) handleType handle : (SQLHANDLE) handle {
  
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

    NSDictionary * diagDict =

    [NSDictionary dictionaryWithObjectsAndKeys : [NSString stringWithUTF8String : sqlState]   ,@"sqlState",
                                                 [NSNumber numberWithShort      : nativeError],@"nativeError",
                                                 [NSString stringWithUTF8String : messageText],@"messageText",
                                                 nil];
    
    return diagDict;
}

@end
