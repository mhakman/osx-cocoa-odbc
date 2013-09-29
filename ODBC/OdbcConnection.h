//
//  OdbcConnection.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OdbcEnvironment.h"

@class OdbcStatement;

@interface OdbcConnection : NSObject {
    
@protected
    
    SQLHANDLE hdbc;
}

@property (readonly) SQLHANDLE hdbc;

@property (readonly) OdbcEnvironment * env;

@property (readonly) bool connected;

@property (nonatomic) unsigned long transactionIsolation;

@property (nonatomic) bool autocommit;

@property (readonly) NSString * dataSource;

@property (readonly) NSString * username;

@property (readonly,nonatomic) NSArray * catalogs;

@property (readonly,nonatomic) NSArray * schemas;

@property (readonly,nonatomic) NSArray * tableTypes;

- (void) connect : (NSString *) server user : (NSString *) user password : (NSString *) password;

- (void) disconnect;

- (void) commit;

- (void) rollback;

- (OdbcStatement *) newStatement;

- (OdbcStatement *) tablesCatalog : (NSString *) catalog
                           schema : (NSString *) schema
                            table : (NSString *) table
                       tableTypes : (NSString *) tableTypes;

@end
