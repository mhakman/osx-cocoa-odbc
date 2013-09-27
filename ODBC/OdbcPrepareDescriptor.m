//
//  PrepareDescriptor.m
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcPrepareDescriptor.h"
#import "OdbcStatement.h"
#import "OdbcParameterDescriptor.h"
#import "OdbcException.h"

#import <sql.h>

@interface OdbcPrepareDescriptor ()

@property OdbcStatement * statement;
@property SQLSMALLINT     numParams;
@property NSArray       * parameterDescriptors;

@end

@implementation OdbcPrepareDescriptor

@synthesize statement,numParams,parameterDescriptors;

+ (OdbcPrepareDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt {
    
    OdbcPrepareDescriptor * desc = [[OdbcPrepareDescriptor alloc] initWithStatement : stmt];
    
    return desc;
}

- (OdbcPrepareDescriptor *) initWithStatement : (OdbcStatement *) stmt {
    
    self = [super init];
    
    if (! self) return self;
    
    self.statement = stmt;
    
    [self fetchDescriptor];
    
    return self;
}

- (void) fetchDescriptor {
    
    [self fetchNumParams];
    
    self->parameterDescriptors = [NSMutableArray new];
    
    for (int iparam = 1; iparam <= self.numParams; iparam++) {
        
        OdbcParameterDescriptor * paramDesc =
        
        [OdbcParameterDescriptor descriptorWithStatement : self.statement parameterNumber : iparam];
        
        [self->parameterDescriptors addObject : paramDesc];
    }
}

- (void) fetchNumParams {
    
    SQLRETURN rc;
    
    rc = SQLNumParams (self.statement.hstmt,&self->numParams);
    
    CHECK_ERROR ("SQLNumParams",rc,SQL_HANDLE_STMT,self.statement.hstmt);
}

- (OdbcParameterDescriptor *) parameterDescriptorAtIndex : (int) index {
    
    return [self.parameterDescriptors objectAtIndex : index - 1];
}


@end
