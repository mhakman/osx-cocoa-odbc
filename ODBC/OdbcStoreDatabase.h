//
//  Database.h
//  RunCommand
//
//  Created by Mikael Hakman on 2013-10-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OdbcStore;

@interface OdbcStoreDatabase : NSObject

+ (OdbcStoreDatabase *) databaseWithOdbcStore : (OdbcStore *) odbcStore;

- (OdbcStoreDatabase *) initWithOdbcStore : (OdbcStore *) odbcStore;

- (void) connectDataSource : (NSString *) dataSource username : (NSString *) username password : (NSString *) password;

- (void) disconnect;

- (unsigned long) objectIdForName : (NSString *) name;

- (void) commit;

- (void) deleteObject : (NSManagedObject *) object;

- (void) insertObject : (NSManagedObject *) object;

- (void) updateObject : (NSManagedObject *) object;

- (NSArray *) fetchObjects : (NSFetchRequest *) request context : (NSManagedObjectContext *) context;

- (NSDictionary *) fetchObjectId : (NSManagedObjectID *) objId context : (NSManagedObjectContext *) context;

- (id) fetchRelationship : (NSRelationshipDescription *) relationship
                objectId : (NSManagedObjectID *) objectId
                 context : (NSManagedObjectContext *) context;

- (void) deleteRelationshipsForObject : (NSManagedObject *) object;

- (void) insertRelationshipsForObject : (NSManagedObject *) object;

- (void) updateRelationshipsForObject : (NSManagedObject *) object;

- (void) dropTablesForModel : (NSManagedObjectModel *) model;

@end
