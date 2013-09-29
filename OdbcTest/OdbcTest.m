//
//  OdbcTest.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-09-29.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcTest.h"
#import "Odbc/Odbc.h"

@interface OdbcTest () {
    
@protected
    
    OdbcConnection * connection;
}

@end

@implementation OdbcTest

- (void) run {
    
    [self connect];
    
    [self catalogs];
    
    [self schemas];
    
    [self tableTypes];
    
    [self tables];
}

- (void) tables {
    
    NSLog (@"%s",__PRETTY_FUNCTION__);
    
    OdbcStatement * tableStmt = [self->connection tablesCatalog : @"%" schema : @"%" table : @"%" tableTypes : @""];
    
    while ([tableStmt fetch]) {
        
        NSString * catalog = [tableStmt getStringByName : @"TABLE_CAT"];
        
        if (! catalog) catalog = @"";
        
        NSString * schema = [tableStmt getStringByName : @"TABLE_SCHEM"];
        
        if (! schema) schema = @"";
        
        NSString * table = [tableStmt getStringByName : @"TABLE_NAME"];
        
        NSString * tableType = [tableStmt getStringByName : @"TABLE_TYPE"];
        
        NSString * remarks = [tableStmt getStringByName : @"REMARKS"];
        
        if (! remarks) remarks = @"";
        
        NSLog (@"%@ %@ %@ %@ %@",catalog,schema,table,tableType,remarks);
    }
    
    [tableStmt closeCursor];
}

- (void) tableTypes {
    
    NSArray * tableTypes = [self->connection tableTypes];
    
    NSLog (@"%s table types %@",__PRETTY_FUNCTION__,tableTypes);
}

- (void) schemas {
    
    NSArray * schemas = [self->connection schemas];
    
    NSLog (@"%s schemas %@",__PRETTY_FUNCTION__,schemas);
}

- (void) catalogs {
    
    NSArray * catalogs = [self->connection catalogs];
    
    NSLog (@"%s catalogs %@",__PRETTY_FUNCTION__,catalogs);
}

- (void) connect {
    
    self->connection = [OdbcConnection new];
    
    [self->connection connect : @"testdb" user : @"root" password : nil];
}

@end
