//
//  OdbcPredicate.h
//  TestParseKit
//
//  Created by Mikael Hakman on 2013-10-14.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PKParser;

@class PKSParser;

@class PKParseTree;

@interface OdbcPredicate : NSObject

@property (readonly,nonatomic) NSString * grammar;

@property (readonly,nonatomic) PKParseTree * parseTree;

- (PKParseTree *) parse : (NSString *) input;

- (NSString *) genSqlFromString : (NSString *) input;

- (NSString *) genSqlFromPredicate : (NSPredicate *) pred;

@end
