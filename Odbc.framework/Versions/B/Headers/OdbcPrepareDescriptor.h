//
//  PrepareDescriptor.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sql.h>

@class OdbcStatement;
@class OdbcParameterDescriptor;

@interface OdbcPrepareDescriptor : NSObject {
    
@protected
    
    OdbcStatement  * statement;
    SQLSMALLINT      numParams;
    NSMutableArray * parameterDescriptors;
}

@property (readonly) OdbcStatement * statement;
@property (readonly) SQLSMALLINT     numParams;
@property (readonly) NSArray       * parameterDescriptors;

+ (OdbcPrepareDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt;

- (OdbcPrepareDescriptor *) initWithStatement : (OdbcStatement *) stmt;

- (OdbcParameterDescriptor *) parameterDescriptorAtIndex : (int) index;

@end
