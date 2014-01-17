//------------------------------------------------------------------------------
//  OdbcConnection.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#import "OdbcEnvironment.h"

@class OdbcStatement;
//------------------------------------------------------------------------------
/**
This class represents a connection to an ODBC data source.

The class is used to connect to a database, to create OdbcStatement and to
retrieve information about the database.
*/
//------------------------------------------------------------------------------
@interface OdbcConnection : NSObject {
    
@protected
    
    void * hdbc;
}
//------------------------------------------------------------------------------
/**
 @name Creating connection and connecting to a database
 */
//------------------------------------------------------------------------------
/**
Creates a connection and connects to a database.
 
@param dataSource ODBC data source name
@param username database username
@param password users password
 
@return connected OdbcConnection
*/
//------------------------------------------------------------------------------
+ (OdbcConnection *) connectionWithDataSource : (NSString *) dataSource
                                     username : (NSString *) username
                                     password : (NSString *) password;
//------------------------------------------------------------------------------
/**
Initializes connection and connects to a database.
 
@param dataSource ODBC data source name
@param username database username
@param password users password
 
@return a connected connection
*/
//------------------------------------------------------------------------------
- (OdbcConnection *) initWithDataSource : (NSString *) dataSource
                               username : (NSString *) username
                               password : (NSString *) password;
//------------------------------------------------------------------------------
/**
Connects to an ODBC data source.
 
@param server ODBC data source name
@param username database user name
@param password users password
*/
//------------------------------------------------------------------------------
- (void) connect : (NSString *) server
        username : (NSString *) username
        password : (NSString *) password;
//------------------------------------------------------------------------------
/**
Disconnects from database.
*/
//------------------------------------------------------------------------------
- (void) disconnect;
//------------------------------------------------------------------------------
/**
@name Commit and rollback
*/
//------------------------------------------------------------------------------
/**
Commits current transaction.
*/
//------------------------------------------------------------------------------
- (void) commit;
//------------------------------------------------------------------------------
/**
Rollbacks current transaction.
*/
//------------------------------------------------------------------------------
- (void) rollback;
//------------------------------------------------------------------------------
/**
@name Creating OdbcStatement
*/
//------------------------------------------------------------------------------
/**
Creates new OdbcStatement.
 
@return OdbcStatement
*/
//------------------------------------------------------------------------------
- (OdbcStatement *) newStatement;
//------------------------------------------------------------------------------
/**
@name Executing SQL
*/
//------------------------------------------------------------------------------
/**
Executes SQL and returns an OdbcStatement.
 
@param sql sql text
 
@return OdbcStatement
*/
//------------------------------------------------------------------------------
- (OdbcStatement *) execDirect : (NSString *) sql;
//------------------------------------------------------------------------------
/**
@name Retrieving information about connection and database
*/
//------------------------------------------------------------------------------
/**
Retrieves information about catalogs, schemas, tables, and table types.

@param catalog catalog to use
@param schema schema pattern to use
@param table table pattern to use
@param tableTypes table types to use
 
@return OdbcStatement
*/
//------------------------------------------------------------------------------
- (OdbcStatement *) tablesCatalog : (NSString *) catalog
                           schema : (NSString *) schema
                            table : (NSString *) table
                       tableTypes : (NSString *) tableTypes;
//------------------------------------------------------------------------------
/**
True if connection is connected to a database, false otherwise.
*/
//------------------------------------------------------------------------------
@property (readonly) bool connected;
//------------------------------------------------------------------------------
/**
Sets or gets transaction isolation level
*/
//------------------------------------------------------------------------------
@property (nonatomic) unsigned long transactionIsolation;
//------------------------------------------------------------------------------
/**
Sets or gets autocommit property of connection.
*/
//------------------------------------------------------------------------------
@property (nonatomic) bool autocommit;
//------------------------------------------------------------------------------
/**
ODBC data source name.
*/
//------------------------------------------------------------------------------
@property (readonly) NSString * dataSource;
//------------------------------------------------------------------------------
/**
Database user name.
*/
//------------------------------------------------------------------------------
@property (readonly) NSString * username;
//------------------------------------------------------------------------------
/**
Names of catalogs in database.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSArray * catalogs;
//------------------------------------------------------------------------------
/**
Names of schemas in database.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSArray * schemas;
//------------------------------------------------------------------------------
/**
Names of table types supported by the database.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSArray * tableTypes;
//------------------------------------------------------------------------------
/**
Name of current database catalog.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * currentCatalog;
//------------------------------------------------------------------------------
/**
Name of current database user. May be different from username of the connection.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * currentUser;
//------------------------------------------------------------------------------
/**
Term used for schemas in the database.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * schemaTerm;
//------------------------------------------------------------------------------
/**
Name of current schema in database.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * currentSchema;
//------------------------------------------------------------------------------
/**
Database vendor name.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * dbmsName;
//------------------------------------------------------------------------------
/**
 OdbcEnvironment object. For internal use only.
 */
//------------------------------------------------------------------------------
@property (readonly) OdbcEnvironment * env;
//------------------------------------------------------------------------------
/**
 Original low level API handle for a connection. For internal use only.
 */
//------------------------------------------------------------------------------
@property (readonly) void * hdbc;

@end
