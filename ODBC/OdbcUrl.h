//
//  OdbcUrl.h
//  Library1
//
//  Created by Mikael Hakman on 2013-10-06.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OdbcUrl : NSURL

@property (readonly) NSString * dataSource;

@property (readonly) NSString * username;

@property (readonly) NSString * password;

+ (OdbcUrl *) urlWithUrl : (NSURL *) url;

- (OdbcUrl *) initWithUrl : (NSURL *) url;

@end
