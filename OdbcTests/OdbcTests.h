//
//  OdbcTests.h
//  OdbcTests
//
//  Created by Mikael Hakman on 2013-09-30.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class OdbcConnection;

@interface OdbcTests : SenTestCase {
    
@protected
    
    OdbcConnection * connection;
}

- (void) connect;

- (void) disconnect;

@end
