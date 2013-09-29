//
//  OdbcConnection.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcConnection.h"

#import "OdbcException.h"

#import "OdbcStatement.h"

@interface OdbcConnection ()
    
@property OdbcEnvironment * env;

@property bool connected;

@property NSString * dataSource;

@property NSString * username;

@property NSArray * catalogs;

@property NSArray * schemas;

@property NSArray * tableTypes;

@end

@implementation OdbcConnection

@synthesize hdbc;

- (NSArray *) tableTypes {
    
    SQLRETURN rc;
    
    OdbcStatement * stmt = [self newStatement];
    
    rc = SQLTables (stmt.hstmt,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)SQL_ALL_TABLE_TYPES,SQL_NTS);
    
    CHECK_ERROR ("SQLTables",rc,SQL_HANDLE_STMT,stmt.hstmt);
    
    NSMutableArray * tableTypes = [NSMutableArray new];
    
    while ([stmt fetch]) {
        
        NSString * tableType = [stmt getStringByName : @"TABLE_TYPE"];
                
        [tableTypes addObject : tableType];
    }
    
    [stmt closeCursor];
    
    return tableTypes;
}

- (NSArray *) schemas {
    
    SQLRETURN rc;
    
    OdbcStatement * stmt = [self newStatement];
    
    rc = SQLTables (stmt.hstmt,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)SQL_ALL_SCHEMAS,SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS);
    
    CHECK_ERROR ("SQLTables",rc,SQL_HANDLE_STMT,stmt.hstmt);
    
    NSMutableArray * schemas = [NSMutableArray new];
    
    while ([stmt fetch]) {
        
        NSString * schema = [stmt getStringByName : @"TABLE_SCHEM"];
        
        if (! schema) schema = @"";
        
        [schemas addObject : schema];
    }
    
    [stmt closeCursor];
    
    return schemas;
}

- (NSArray *) catalogs {
    
    SQLRETURN rc;
    
    OdbcStatement * stmt = [self newStatement];
    
    rc = SQLTables (stmt.hstmt,
                    (SQLCHAR *)SQL_ALL_CATALOGS,SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS);
    
    CHECK_ERROR ("SQLTables",rc,SQL_HANDLE_STMT,stmt.hstmt);
    
    NSMutableArray * catalogs = [NSMutableArray new];
    
    while ([stmt fetch]) {
        
        NSString * catalog = [stmt getStringByName : @"TABLE_CAT"];
        
        [catalogs addObject : catalog];
    }
    
    [stmt closeCursor];
    
    return catalogs;
}

- (bool) autocommit {
    
    SQLRETURN rc;
    
    unsigned int autocommit = 0;
    
    rc = SQLGetConnectAttr (self.hdbc,SQL_ATTR_AUTOCOMMIT,&autocommit,0,0);
    
    CHECK_ERROR ("SQLGetConnectAttr",rc,SQL_HANDLE_DBC,self.hdbc);
       
    return (autocommit == 0 ? NO : YES);

}

- (void) setAutocommit : (bool) autocommit {
    
    SQLRETURN rc;
    
    unsigned long autoc = (autocommit ? SQL_AUTOCOMMIT_ON : SQL_AUTOCOMMIT_OFF);
    
    rc = SQLSetConnectAttr (self.hdbc,SQL_ATTR_AUTOCOMMIT,&autoc,0);
    
    CHECK_ERROR ("SQLSetConnectAttr",rc,SQL_HANDLE_DBC,self.hdbc);
}

- (unsigned long) transactionIsolation {
    
    SQLRETURN rc;
    
    unsigned long txnIsolation = 0;
    
    rc = SQLGetConnectAttr (self.hdbc,SQL_ATTR_TXN_ISOLATION,&txnIsolation,0,0);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLGetConnectAttr");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLGetConnectAttr",SQL_HANDLE_DBC,self.hdbc);
    }
    
    return txnIsolation;
}

- (void) setTransactionIsolation : (unsigned long) txnIsolation {
    
    SQLRETURN rc;
    
    rc = SQLSetConnectAttr (self.hdbc,SQL_ATTR_TXN_ISOLATION,&txnIsolation,8);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLSetConnectAttr");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLSetConnectAttr",SQL_HANDLE_DBC,self.hdbc);
    }
}

- (OdbcStatement *) newStatement {
    
    OdbcStatement * statement = [OdbcStatement statementWithConnection : self];
    
    return statement;
}

- (void) rollback {
    
    SQLRETURN rc;
    
    rc = SQLEndTran (SQL_HANDLE_DBC,self.hdbc,SQL_ROLLBACK);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLEndTran");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLEndTran",SQL_HANDLE_DBC,self.hdbc);
    }
}

- (void) commit {
    
    SQLRETURN rc;
    
    rc = SQLEndTran (SQL_HANDLE_DBC,self.hdbc,SQL_COMMIT);

    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLEndTran");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLEndTran",SQL_HANDLE_DBC,self.hdbc);
    }
}

- (void) connect : (NSString *) server user : (NSString *) user password : (NSString *) password {
    
    SQLRETURN rc;
    
    const char * serverc = 0;
    
    SQLSMALLINT serverLen = 0;
    
    if (server) {
        
        serverc = [server UTF8String];
    
        serverLen = strlen (serverc);
    }
    
    const char * userc = 0;
    
    SQLSMALLINT userLen = 0;
    
    if (user) {
        
        userc = [user UTF8String];
        
        userLen = strlen (userc);
    }

    const char * passwordc = 0;
    
    SQLSMALLINT passLen = 0;
    
    if (password) {
        
        passwordc = [password UTF8String];
        
        passLen = strlen (passwordc);
    }
    
    rc = SQLConnect (self.hdbc,(SQLCHAR *)serverc,serverLen,(SQLCHAR *)userc,userLen,(SQLCHAR *)passwordc,passLen);
    
    CHECK_ERROR ("SQLConnect",rc,SQL_HANDLE_DBC,self.hdbc);
    
    self.connected = YES;
    
    self.autocommit = NO;
    
    self.dataSource = server;
    
    self.username = user;
    
}

- (void) disconnect {
    
    if (! self.connected) return;
    
    SQLRETURN rc;
    
    rc = SQLDisconnect (self.hdbc);
    
    CHECK_ERROR ("SQLDisconnect",rc,SQL_HANDLE_DBC,self.hdbc);
        
    self.connected = NO;

}

- (id) init {
    
    self = [super init];
    
    if (! self) return self;
    
    [self allocEnv];
        
    [self allocHandle];
    
    return self;
}

- (void) dealloc {
    
    [self disconnect];
    
    [self freeHandle];
}

- (void) freeHandle {
    
    SQLRETURN rc;
    
    rc = SQLFreeHandle (SQL_HANDLE_DBC,self.hdbc);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLFreeHandle");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLFreeHandle",SQL_HANDLE_DBC,self.hdbc);
    }
}

- (void) allocEnv {
    
    self.env = [OdbcEnvironment sharedInstance];
}

- (void) allocHandle {
    
    SQLRETURN rc;
    
    rc = SQLAllocHandle (SQL_HANDLE_DBC,self.env.henv,&self->hdbc);
    
    if (rc == SQL_INVALID_HANDLE) {
        
        RAISE_INVALID_HANDLE ("SQLAllocHandle");
        
    } else if (rc != SQL_SUCCESS) {
        
        RAISE_ODBC_HANDLE ("SQLAllocHandle",SQL_HANDLE_ENV,self.env.henv);
    }
}

@end
