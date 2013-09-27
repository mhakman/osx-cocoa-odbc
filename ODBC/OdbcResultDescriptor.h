//
//  OdbcResultDescriptor.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OdbcStatement;
@class OdbcColumnDescriptor;

@interface OdbcResultDescriptor : NSObject {
    
@protected

    NSMutableArray * columnDescriptors;
    
    NSMutableDictionary * columnNameToNumberDict;
}

@property (readonly) OdbcStatement * statement;
@property (readonly) NSArray       * columnDescriptors;
@property (readonly) int             numResultCols;
@property (readonly) NSDictionary  * columnNameToNumberDict;

+ (OdbcResultDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt;

- (OdbcResultDescriptor *) initWithStatement : (OdbcStatement *) stmt;

- (OdbcColumnDescriptor *) columnDescriptorAtIndex : (int) index;

- (int) columnNumberFor : (NSString *) columnName;

@end
