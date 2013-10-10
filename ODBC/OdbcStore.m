//
//  OdbcStore.m
//  RunCommand
//
//  Created by Mikael Hakman on 2013-10-02.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcStore.h"

#import "OdbcStoreDatabase.h"
#import "OdbcUrl.h"

#import <Odbc/Odbc.h>

@interface OdbcStore () {
    
@protected

    OdbcUrl  * odbcUrl;
    
    OdbcStoreDatabase * database;
}

@end

@implementation OdbcStore

- (void) dropTablesForModel : (NSManagedObjectModel *) model {
    
    [self->database dropTablesForModel : model];
    
    [self->database commit];
}

- (id) initWithPersistentStoreCoordinator : (NSPersistentStoreCoordinator *) root
                        configurationName : (NSString *) name
                                      URL : (NSURL *) url
                                  options : (NSDictionary *) options {
    
    self = [super initWithPersistentStoreCoordinator : root configurationName : name URL : url options : options];
    
    if (! self) return self;
    
    self->database = [OdbcStoreDatabase databaseWithOdbcStore : self];
    
    self->odbcUrl = [OdbcUrl urlWithUrl : url];
        
    return self;
}


+ (id) identifierForNewStoreAtURL : (NSURL *) storeURL {
    
    NSString * identifier = [OdbcUrl urlWithUrl : storeURL].description;
    
    return identifier;
}

- (id) executeRequest : (NSPersistentStoreRequest *) request
          withContext : (NSManagedObjectContext *) context
                error : (NSError **) error {
    
    id result;
    
    if (request.requestType == NSFetchRequestType) {
        
        result = [self executeFetch : (NSFetchRequest *)request withContext : context error : error];
        
    } else {
        
        result = [self executeSave : (NSSaveChangesRequest *)request withContext : context error : error];
    }
    
    return result;
}

- (id) executeFetch : (NSFetchRequest *) request
        withContext : (NSManagedObjectContext *) context
              error : (NSError **) error {
    
    NSFetchRequestResultType requestResultType = request.resultType;
    
    id result;
    
    @try {
        
        switch (requestResultType) {
            
            case NSManagedObjectResultType: {
            
                result = [self->database fetchObjects : request context : context];
            
                [self->database commit];
            
                break;
            }
            
            default: {
            
                * error = [NSError errorWithDomain : @"Unsupported result type"
                                              code : 0
                                          userInfo : @{@"result type" : @(requestResultType)}];
            
                return nil;
            }
        }
        
    } @catch (NSException * exception) {
        
        * error = [self errorForException : exception];
        
        return nil;
    }
    
    return result;
}

- (id) executeSave : (NSSaveChangesRequest *) request
       withContext : (NSManagedObjectContext *) context
             error : (NSError **) error {
    
    @try {
        
        for (NSManagedObject * object in request.deletedObjects) {
            
            [self->database deleteRelationshipsForObject : object];
        }
    
        for (NSManagedObject * object in request.deletedObjects) {
        
            [self->database deleteObject : object];
        }
    
        for (NSManagedObject * object in request.insertedObjects) {
                    
            [self->database insertObject : object];
        }
        
        for (NSManagedObject * object in request.insertedObjects) {
            
            [self->database insertRelationshipsForObject : object];
        }
    
        for (NSManagedObject * object in request.updatedObjects) {
        
            [self->database updateObject : object];
        }
        
        for (NSManagedObject * object in request.updatedObjects) {
            
            [self->database updateRelationshipsForObject : object];
        }
    
        [self->database commit];
        
    } @catch (NSException * exception) {
        
        * error = [self errorForException : exception];
        
        return nil;
    }
    
    return [NSArray new];
}


- (BOOL) loadMetadata : (NSError **) errorPtr {
        
    if (! self->odbcUrl) {
        
        NSDictionary * userInfo = @{NSLocalizedDescriptionKey : self.URL.absoluteString};
        
        NSError * error = [NSError errorWithDomain : @"Invalid ODBC URL" code : 0 userInfo : userInfo];
        
        * errorPtr = error;
        
        return NO;
    }
    
    @try {
        
        [self->database connectDataSource : self->odbcUrl.dataSource
                                 username : self->odbcUrl.username
                                 password : self->odbcUrl.password];
        
    } @catch (NSException * exception) {
        
        * errorPtr = [self errorForException : exception];
        
        return NO;
    }
    
    [self setMetadata : @{
       NSStoreTypeKey : NSStringFromClass (self.class),
       NSStoreUUIDKey : [OdbcStore identifierForNewStoreAtURL : self.URL]
    }];
    
    return YES;
}

- (void) managedObjectContextDidRegisterObjectsWithIDs : (NSArray *) objectIDs {
    
    [super managedObjectContextDidRegisterObjectsWithIDs : objectIDs];
}

- (void) managedObjectContextDidUnregisterObjectsWithIDs : (NSArray *) objectIDs {
    
    [super managedObjectContextDidUnregisterObjectsWithIDs : objectIDs];
}

- (id) newValueForRelationship : (NSRelationshipDescription *) relationship
               forObjectWithID : (NSManagedObjectID *) objectID
                   withContext : (NSManagedObjectContext *) context
                         error : (NSError **) error {
    id result;
    
    @try {
        
        result = [self->database fetchRelationship : relationship objectId : objectID context : context];
        
        [self->database commit];
        
    } @catch (NSException * exception) {
                
        * error = [self errorForException : exception];
        
        return nil;
    }

    return result;
}

- (NSIncrementalStoreNode *) newValuesForObjectWithID : (NSManagedObjectID *) objectID
                                          withContext : (NSManagedObjectContext *) context
                                                error : (NSError **) error {
    
    @try {
        
        NSDictionary * values = [self->database fetchObjectId : objectID context : context];
        
        [self->database commit];
        
        NSIncrementalStoreNode * node =
        
        [[NSIncrementalStoreNode alloc] initWithObjectID : objectID withValues : values version : 1];
        
        return node;
        
    } @catch (NSException * exception) {
        
        * error = [self errorForException : exception];
        
        return nil;
    }    
}

- (NSArray *) obtainPermanentIDsForObjects : (NSArray *) array error : (NSError **) error {
    
    NSMutableArray * ids = [NSMutableArray arrayWithCapacity : array.count];
    
    @try {
        
        for (NSManagedObject * object in array) {
            
            NSEntityDescription * description = object.entity;
            
            unsigned long longId = [self->database objectIdForName : description.name];
            
            NSManagedObjectID * objId = [self newObjectIDForEntity : description referenceObject : @(longId)];
            
            [ids addObject : objId];
        }
        
        [self->database commit];
        
    } @catch (NSException * exception) {
        
        * error = [self errorForException : exception];
        
        return nil;
    }
    
    return ids;
}

- (NSError *) errorForException : (NSException *) exception {
    
    NSString * description;
    
    if ([exception respondsToSelector : @selector (userDescription)]) {
        
        description = [(id)exception userDescription];
        
    } else {
        
        description = exception.description;
    }
    
    NSDictionary * userInfo = @{@"Data Source Url"        : self->odbcUrl.description,
                                NSLocalizedDescriptionKey : description};
    
    NSError * error = [NSError errorWithDomain : exception.name code : 0 userInfo : userInfo];
    
    return error;
}

@end
