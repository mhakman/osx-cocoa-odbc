//
//  OdbcTests.h
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

extern NSString * DataSourceName;
extern NSString * Username;
extern NSString * Password;

@class OdbcConnection;
@class OdbcStatement;

@interface OdbcTests : SenTestCase {
    
@protected
    
    OdbcConnection * connection;
    
    OdbcStatement  * statement;
}

- (void) connect;

- (void) disconnect;

@end
