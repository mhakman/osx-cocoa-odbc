//------------------------------------------------------------------------------
//  OdbcStore.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-02.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//------------------------------------------------------------------------------
#import <CoreData/CoreData.h>
//------------------------------------------------------------------------------
/**
OdbcStore implements NSIncrementalStore specification.
 
This class is not used directly by applications. It is instantiated by Core
Data and used there in. It provides NSIncrementalStore interface to ODBC.
 
See Apple NSIncrementalStore specification for more information.
*/
//------------------------------------------------------------------------------
@interface OdbcStore : NSIncrementalStore

@end
