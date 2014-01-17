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

#import <iODBC/sql.h>
#import <iODBC/sqltypes.h>
#import <iODBC/sqlext.h>

@interface OdbcConnection ()
    
@property OdbcEnvironment * env;

@property bool connected;

@property NSString * dataSource;

@property NSString * username;

@end

@implementation OdbcConnection

@synthesize hdbc;

+ (OdbcConnection *) connectionWithDataSource : (NSString *) newDataSource
                                     username : (NSString *) newUsername
                                     password : (NSString *) newPassword {
    
    OdbcConnection * connection = [[OdbcConnection alloc] initWithDataSource : newDataSource
                                                                    username : newUsername
                                                                    password : newPassword];
    
    return connection;
}

- (OdbcConnection *) initWithDataSource : (NSString *) newDataSource
                               username : (NSString *) newUsername
                               password : (NSString *) newPassword {
    
    self = [self init];
    
    if (! self) return self;
    
    [self connect : newDataSource username : newUsername password : newPassword];
    
    return self;
}

- (NSString *) dbmsName {
    
    SQLRETURN rc;
    
    char namec [128] = "";
    
    short len = 0;
    
    rc = SQLGetInfo (self->hdbc,SQL_DBMS_NAME,namec,sizeof(namec),&len);
    
    CHECK_ERROR ("SQLGetInfo",rc,SQL_HANDLE_DBC,self->hdbc);
    
    NSString * name = [NSString stringWithUTF8String : namec];
    
    return name;
}

- (OdbcStatement *) execDirect : (NSString *) sql {
    
    OdbcStatement * stmt = [self newStatement];
    
    [stmt execDirect : sql];
    
    return stmt;
}

- (NSString *) currentSchema {
    
    NSString * schemaTerm = self.schemaTerm;
    
    if (schemaTerm.length <= 0) return @"";
    
    NSString * schema = [self.currentUser copy];
    
    return schema;
}

- (NSString *) schemaTerm {
    
    SQLRETURN rc;
    
    char termc [128] = "";
    
    SQLSMALLINT len = 0;
    
    rc = SQLGetInfo (self.hdbc,SQL_SCHEMA_TERM,termc,sizeof(termc),&len);
    
    CHECK_ERROR ("SQLGetInfo",rc,SQL_HANDLE_DBC,self.hdbc);
    
    NSString * term = [NSString stringWithUTF8String : termc];
    
    return term;
}

- (NSString *) currentUser {
    
    SQLRETURN rc;
    
    char userc [128] = "";
    
    SQLSMALLINT len = 0;
    
    rc = SQLGetInfo (self.hdbc,SQL_USER_NAME,userc,sizeof(userc),&len);
    
    CHECK_ERROR ("SqlGetInfo",rc,SQL_HANDLE_DBC,self.hdbc);
    
    NSString * user = [NSString stringWithUTF8String : userc];
    
    return user;
}

- (NSString *) currentCatalog {
    
    SQLRETURN rc;
    
    char catalogc [128] = "";
    
    SQLINTEGER len = 0;
    
    rc = SQLGetConnectAttr (self.hdbc,SQL_ATTR_CURRENT_CATALOG,catalogc,sizeof(catalogc),&len);
    
    CHECK_ERROR ("SQLGetConnectAttr",rc,SQL_HANDLE_DBC,self.hdbc);
    
    NSString * catalog = [NSString stringWithUTF8String : catalogc];
    
    return catalog;
}

- (OdbcStatement *) tablesCatalog : (NSString *) catalog
                           schema : (NSString *) schema
                            table : (NSString *) table
                       tableTypes : (NSString *) tableTypes {
    
    SQLRETURN rc;
        
    NSString * dbms = self.dbmsName;
    
    if ([dbms hasPrefix : @"DB2"] || [dbms hasPrefix : @"Mimer"] || [dbms hasPrefix : @"Oracle"]) {
        
        catalog = [catalog uppercaseString];
        
        schema = [schema uppercaseString];
        
        table = [table uppercaseString];
        
        tableTypes = [tableTypes uppercaseString];
        
    } else if ([dbms hasPrefix : @"PostgreSQL"]) {
        
        catalog = [catalog lowercaseString];
        
        schema = [schema lowercaseString];
        
        table = [table lowercaseString];
        
        tableTypes = [tableTypes lowercaseString];
    }

    OdbcStatement * stmt = [self newStatement];
    
    rc = SQLTables (stmt.hstmt,
                    (SQLCHAR *)catalog.UTF8String,SQL_NTS,
                    (SQLCHAR *)schema.UTF8String,SQL_NTS,
                    (SQLCHAR *)table.UTF8String,SQL_NTS,
                    (SQLCHAR *)tableTypes.UTF8String,SQL_NTS);

    CHECK_ERROR ("SQLTables",rc,SQL_HANDLE_STMT,stmt.hstmt);

    return stmt;
}

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
        
        NSString * schema = nil;
        
        @try {
            
            schema = [stmt getStringByName : @"TABLE_SCHEM"];
            
        } @catch (NSException * exception) {
            
            schema = [stmt getStringByName : @"TABLE_OWNER"];
        }
        
        if (schema) [schemas addObject : schema];
    }
    
    [stmt closeCursor];
    
    return schemas;
}

- (NSArray *) catalogs {
    
    SQLRETURN rc;
    
    NSMutableArray * catalogs = [NSMutableArray new];
    
    OdbcStatement * stmt = [self newStatement];
    
    rc = SQLTables (stmt.hstmt,
                    (SQLCHAR *)SQL_ALL_CATALOGS,SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS,
                    (SQLCHAR *)"",SQL_NTS);
    
    @try {
    
        CHECK_ERROR ("SQLTables",rc,SQL_HANDLE_STMT,stmt.hstmt);
        
        while ([stmt fetch]) {
                    
            NSString * catalog = nil;
            
            @try {
                
                catalog = [stmt getStringByName : @"TABLE_CAT"];
                
            } @catch (NSException * exception) {
                
                catalog = [stmt getStringByName : @"TABLE_QUALIFIER"];
            }
        
            if (catalog) [catalogs addObject : catalog];
        }
        
        [stmt closeCursor];
        
    } @catch (OdbcException * exception) {
        
        NSDictionary * userInfo = exception.userInfo;
        
        if (! userInfo) @throw exception;
        
        NSString * sqlState = [userInfo objectForKey : @"sqlState"];
        
        if (! [sqlState isEqualToString : @"HYC00"]) @throw exception;
    }
    
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
    
    rc = SQLSetConnectAttr (self.hdbc,SQL_ATTR_AUTOCOMMIT,(void *)autoc,8);
    
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
    
    rc = SQLSetConnectAttr (self.hdbc,SQL_ATTR_TXN_ISOLATION,(void *) txnIsolation,8);
    
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

- (void) connect : (NSString *) server username : (NSString *) user password : (NSString *) password {
    
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
    
    NSString * dbms = self.dbmsName;
    
    if ([[dbms lowercaseString] hasPrefix : @"oracle"]) {
        
        self.transactionIsolation = SQL_TXN_READ_COMMITTED;
        
    } else if ([dbms hasPrefix : @"SQLite"]) {
        
        ;
        
    } else {
    
        self.transactionIsolation = SQL_TXN_REPEATABLE_READ;
    }
    
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
