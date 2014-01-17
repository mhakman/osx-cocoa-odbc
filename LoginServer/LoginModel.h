//
//  OdbcLoginModel.h
//  Odbc
//
//  Created by Mikael Hakman on 2014-01-14.
//  Copyright (c) 2014 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginModel : NSObject

@property NSString * dsn;

@property NSString * username;

@property NSString * password;

@property (readonly,nonatomic) NSURL * loginUrl;

- (void) loginAndOut;

@end
