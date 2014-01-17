//
//  OdbcLoginModel.m
//  Odbc
//
//  Created by Mikael Hakman on 2014-01-14.
//  Copyright (c) 2014 Mikael Hakman. All rights reserved.
//

#import "LoginModel.h"

#import <Odbc/Odbc.h>

@implementation LoginModel

@synthesize dsn, username, password, loginUrl;
//
// Connect to and disconnect from the database. Throws an exception if error.
//
- (void) loginAndOut {
    
    OdbcConnection * conn = [OdbcConnection connectionWithDataSource : self.dsn
                                                            username : self.username
                                                            password : self.password];
    
    [conn disconnect];
}
//
// Return ODBC URL
//
- (NSURL *) loginUrl {
    
    NSString * urlStr =
    
    [NSString stringWithFormat : @"odbc:///%@?username=%@&password=%@",self.dsn,self.username,self.password];
    
    NSURL * url = [NSURL URLWithString : urlStr];
    
    return url;
}

@end
