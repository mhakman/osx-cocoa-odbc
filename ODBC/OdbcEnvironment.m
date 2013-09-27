//
//  OdbcEnvironment.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcEnvironment.h"

static OdbcEnvironment * sharedInstance = 0;

@implementation OdbcEnvironment

@synthesize henv;

+ (OdbcEnvironment *) sharedInstance {
    
    @synchronized (self) {
    
        if (sharedInstance) return sharedInstance;
    
        sharedInstance = [[OdbcEnvironment alloc] init];
    
        return sharedInstance;
    }
}

- (id) init {
    
    if (sharedInstance != 0) {
        
        [NSException raise : NSInternalInconsistencyException
                    format : @"[%@ %@] cannot be called; use [%@ %@] instead",
                             NSStringFromClass ([self class]),
                             NSStringFromSelector (_cmd),
                             NSStringFromClass ([self class]),
                             NSStringFromSelector (@selector (sharedInstance))];
    }
        
    self = [super init];
    
    [self allocHandle];
    
    [self setOdbcVersion];
    
    return self;
}

- (void) setOdbcVersion {
    
    SQLRETURN rc;
    
    rc = SQLSetEnvAttr (self.henv,SQL_ATTR_ODBC_VERSION,(SQLPOINTER)SQL_OV_ODBC3,0);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLSetEnvAttr");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLSetEnvAttr",SQL_HANDLE_ENV,self.henv);
    }

}

- (void) allocHandle {
    
    SQLRETURN rc;
    
    rc = SQLAllocHandle (SQL_HANDLE_ENV,0,&self->henv);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLAllocHandle");
        
    } else  if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLAllocHandle",SQL_HANDLE_ENV,henv);
    }
}

- (void) dealloc {
    
    [self freeHandle];
}

- (void) freeHandle {
    
    SQLRETURN rc;
    
    rc = SQLFreeHandle (SQL_HANDLE_ENV,self.henv);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLFreeHandle");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLFreeHandle",SQL_HANDLE_ENV,self.henv);
    }
}

@end
