//
//  OdbcColumnDescriptor.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OdbcStatement;

@interface OdbcColumnDescriptor : NSObject

@property (readonly) OdbcStatement * statement;
@property (readonly) int             columnNumber;
@property (readonly) NSString      * columnName;
@property (readonly) short           dataType;
@property (readonly) unsigned long   columnSize;
@property (readonly) short           decimalDigits;
@property (readonly) BOOL            nullable;

+ (OdbcColumnDescriptor *) descriptorWithStatement : (OdbcStatement *) stmt columnNumber : (int) colNo;

- (OdbcColumnDescriptor *) initWithStatement : (OdbcStatement *) stmt columnNumber : (int) colNo; 

@end
