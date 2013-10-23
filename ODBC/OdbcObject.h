//
//  OdbcObject.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-21.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OdbcObject : NSObject

@property (readonly) NSString * string;

+ (OdbcObject *) objectWithId : (NSManagedObjectID *) newId
                   attributes : (NSDictionary *) newAttributes
                relationships : (NSDictionary *) newRelationships
                        store : (NSIncrementalStore *) newStore;

+ (OdbcObject *) objectWithObject : (NSManagedObject *) newObj store : (NSIncrementalStore *) newStore;

- (OdbcObject *) initWithId : (NSManagedObjectID *) newId
                 attributes : (NSDictionary *) newAttributes
              relationships : (NSDictionary *) newRelationships
                      store : (NSIncrementalStore *) newStore;

- (OdbcObject *) initWithObject : (NSManagedObject *) newObj store : (NSIncrementalStore *) newStore;


@end
