//
//  Database.m
//  RunCommand
//
//  Created by Mikael Hakman on 2013-10-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcStoreDatabase.h"

#import "OdbcStore.h"

#import <Odbc/Odbc.h>

@interface OdbcStoreDatabase () {
    
@protected
    
    OdbcStore * odbcStore;
    
    OdbcConnection * odbcConnection;
    
    NSMutableDictionary * stmtDict;
    
    NSMutableDictionary * relationshipTablesDict;
    
    NSString * catalog;
    
    NSString * schema;
    
    NSMutableDictionary * fetchedObjects;
}

@property (nonatomic) OdbcStatement * fetchCoreDataEntityForNameStmt;
@property (nonatomic) OdbcStatement * insertCoreDataEntityForNameStmt;
@property (nonatomic) OdbcStatement * updateCoreDataEntityForNameStmt;

@end

@implementation OdbcStoreDatabase

@synthesize fetchCoreDataEntityForNameStmt, insertCoreDataEntityForNameStmt, updateCoreDataEntityForNameStmt;

- (id) fetchRelationship : (NSRelationshipDescription *) relationship
                objectId : (NSManagedObjectID *) objectId
                 context : (NSManagedObjectContext *) context {
    
    id result = [NSNull null];
    
    if (relationship.isToMany) {
        
        result = [NSMutableArray new];
    }
    
    NSEntityDescription * ed = relationship.destinationEntity;
    
    OdbcStatement * stmt = [self selectStmtForRelationship : relationship objectId : objectId];
        
    [stmt execute];
    
    while ([stmt fetch]) {
        
        unsigned long pk = [stmt getLong : 1];
        
        NSManagedObjectID * objectId = [self objectIdForEntity : ed primaryKey : pk];
        
        if (! relationship.isToMany) {
            
            result = objectId;
            
            break;
        }
                
        [result addObject : objectId];
    }
    
    [stmt closeCursor];
        
    return result;
}

- (OdbcStatement *) selectStmtForRelationship : (NSRelationshipDescription *) relationship
                                     objectId : (NSManagedObjectID *) objectId {
    
    NSString * sql = [self selectSqlForRelationship : relationship];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setSelectParametersForObjectId : objectId stmt : stmt];
    
    return stmt;
}

- (void) setSelectParametersForObjectId : (NSManagedObjectID *) objectId stmt : (OdbcStatement *) stmt {
    
    unsigned long pk = [self primaryKeyForObjectId : objectId];
    
    [stmt setLong : 1 value : pk];
}

- (NSString *) selectSqlForRelationship : (NSRelationshipDescription *) relationship {
    
    NSString * relTabName = [self tableForRelationship : relationship];
    
    NSString * srcTabName = relationship.entity.name;
    
    NSString * dstTabName = relationship.destinationEntity.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"select %@.id",dstTabName];
    
    for (id key in relationship.destinationEntity.attributeKeys) {
        
        NSAttributeDescription * ad = [relationship.destinationEntity.attributesByName objectForKey : key];
        
        [sql appendFormat : @",%@.%@",dstTabName,ad.name];
    }
    
    [sql appendFormat : @" from %@,%@",relTabName,dstTabName];
    
    [sql appendFormat : @" where %@.%@ = ?",relTabName,srcTabName];
    
    [sql appendFormat : @" and %@.%@ = %@.id",relTabName,dstTabName,dstTabName];
    
    return sql;
}

- (NSString *) tableForRelationship : (NSRelationshipDescription *) relationship {
    
    NSRelationshipDescription * selectedRelationship = [self selectMainRelationship : relationship];
    
    return selectedRelationship.name;
}

- (NSRelationshipDescription *) selectMainRelationship : (NSRelationshipDescription *) relationship {
    
    NSString * tableName = [self->relationshipTablesDict objectForKey : relationship.name];
    
    if (tableName) {
        
        if ([tableName isEqualToString : relationship.name]) {
            
            return relationship;
            
        } else {
            
            return relationship.inverseRelationship;
        }
    }
    
    if (relationship.inverseRelationship == nil) {
        
        [self->relationshipTablesDict setValue : relationship.name forKey : relationship.name];
        
        return relationship;
        
    } else if (relationship.isToMany != relationship.inverseRelationship.isToMany) {
        
        if (relationship.isToMany) {
            
            [self->relationshipTablesDict setValue : relationship.name forKey : relationship.name];
            
            [self->relationshipTablesDict setValue : relationship.name forKey : relationship.inverseRelationship.name];
            
            return relationship;
            
        } else {
         
            [self->relationshipTablesDict setValue : relationship.inverseRelationship.name
                                            forKey : relationship.inverseRelationship.name];
            
            [self->relationshipTablesDict setValue : relationship.inverseRelationship.name
                                            forKey : relationship.name];
            
            return relationship.inverseRelationship;
        }
        
    } else {
        
        tableName = relationship.name;
            
        NSString * inverseTableName = relationship.inverseRelationship.name;
    
        NSRelationshipDescription * selectedRelationship = relationship;
        
        int cmp = [tableName compare : inverseTableName];
    
        if (cmp < 0) {
            
            selectedRelationship = relationship.inverseRelationship;
         }
    
        [self->relationshipTablesDict setValue : selectedRelationship.name forKey : selectedRelationship.name];
    
        [self->relationshipTablesDict setValue : selectedRelationship.name
                                        forKey : selectedRelationship.inverseRelationship.name];
    
        return selectedRelationship;
    }
}

- (NSArray *) fetchObjects : (NSFetchRequest *) request context : (NSManagedObjectContext *) context {
        
    request.returnsObjectsAsFaults = YES;
    
    NSMutableArray * result = [NSMutableArray new];
    
    OdbcStatement * stmt = [self selectStmtForRequest : request];
    
    NSEntityDescription * ed = request.entity;
    
    [stmt execute];
    
    while ([stmt fetch]) {
        
        unsigned long pk = [stmt getLongByName : @"id"];
        
        NSManagedObjectID * objId = [self objectIdForEntity : ed primaryKey : pk];
        
        NSManagedObject * mo = [context objectWithID : objId];
                
        [result addObject: mo];
        
        [self storeFetchedObjectId : objId context : context];
    }
    
    [stmt closeCursor];
    
    return result;
}

- (void) storeFetchedObjectId : (NSManagedObjectID *) objId context : (NSManagedObjectContext *) context {
    
    NSDictionary * relationships = nil;
    
    NSDictionary * attributes = [self fetchObject : objId context : context relationships : &relationships];
    
    OdbcObject * obj = [OdbcObject objectWithId : objId
                                     attributes : attributes
                                  relationships : relationships
                                          store : self->odbcStore];
    
    [self addToFetchedObjects : objId object : obj];    
}

- (void) addToFetchedObjects : (NSManagedObjectID *) objId object : (OdbcObject *) obj {
    
    NSString * key = objId.URIRepresentation.absoluteString;
    
    NSString * val = obj.string;
    
    [self->fetchedObjects setObject : val forKey : key];
}

- (OdbcStatement *) selectStmtForRequest : (NSFetchRequest *) request {
    
    NSString * sql = [self selectSqlForRequest : request];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setSelectParametersForRequest : request];
    
    return stmt;
}

- (NSString *) selectSqlForRequest : (NSFetchRequest *) request {
        
    NSEntityDescription * ed = request.entity;
    
    NSString * tableName = ed.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"select id from %@",tableName];
    
    if (request.predicate != nil) {
        
        NSString * where = [[OdbcPredicate new] genSqlFromPredicate : request.predicate];
        
        [sql appendFormat : @" %@",where];
    }
    
    if (request.sortDescriptors != nil && request.sortDescriptors.count > 0) {
        
        [sql appendString : @" order by " ];
        
        bool first = YES;
        
        for (NSSortDescriptor * sd in request.sortDescriptors) {
            
            if (! first) [sql appendString : @","];
            
            [sql appendString : sd.key];
            
            first = NO;
        }
    }
    
    return sql;
}

- (void) setSelectParametersForRequest : (NSFetchRequest *) request {
    
}

- (NSDictionary *) fetchObjectId : (NSManagedObjectID *) objectId context : (NSManagedObjectContext *) context {
    
    NSDictionary * attributes = [self fetchObject : objectId context : context relationships : nil];
    
    return attributes;
}

- (NSDictionary *) fetchObject : (NSManagedObjectID *) objectId
                       context : (NSManagedObjectContext *) context
                 relationships : (NSDictionary **) relationships {
    
    NSMutableDictionary * result = [NSMutableDictionary new];
    
    NSManagedObject * mo = [context objectWithID : objectId];
    
    OdbcStatement * stmt = [self selectStmtForObject : mo];
    
    NSEntityDescription * ed = mo.entity;
    
    [stmt execute];
    
    bool found = [stmt fetch];
    
    if (found) {
        
        for (id key in ed.attributeKeys) {
            
            NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
            
            id value = [stmt getObjectByName : ad.name];
            
            [result setObject : value forKey : ad.name];
        }
        
        if (relationships) (* relationships) = [self fetchAllRelationshipsForObjectId : objectId context : context];
        
    } else {
        
        [stmt closeCursor];
        
        NSString * msg = [NSString stringWithFormat : @"Object not found '%@'",objectId];
        
        RAISE_ODBC_EXCEPTION ("fetchObjectId",msg.UTF8String);
    }
    
    [stmt closeCursor];
    
    return result;
}

- (OdbcStatement *) selectStmtForObject : (NSManagedObject *) object {
    
    NSString * sql = [self selectSqlForObject : object];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setSelectParametersForObject: object stmt : stmt];
    
    return stmt;
}

- (NSString *) selectSqlForObject : (NSManagedObject *) object {
    
    NSMutableString * sql = [NSMutableString stringWithString : @"select id"];
    
    NSEntityDescription * ed = object.entity;
    
    for (id key in ed.attributeKeys) {
        
        NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
        
        [sql appendString : @","];
        
        [sql appendString : ad.name];
    }
    
    NSString * tableName = ed.name;
    
    [sql appendFormat : @" from %@ where id = ?",tableName];
    
    return sql;
}

- (void) setSelectParametersForObject : (NSManagedObject *) object stmt : (OdbcStatement *) stmt {
    
    unsigned long pk = [self primaryKeyForObject : object];
    
    [stmt setLong : 1 value : pk];
}

- (NSDictionary *) fetchAllRelationshipsForObjectId : (NSManagedObjectID *) objId
                                            context : (NSManagedObjectContext *) context {
    
    NSMutableDictionary * result = [NSMutableDictionary new];
    
    NSEntityDescription * ed = objId.entity;
    
    NSDictionary * relationShips = ed.relationshipsByName;
    
    for (NSRelationshipDescription * rd in relationShips.allValues) {
        
        id value = [self fetchRelationship : rd objectId : objId context : context];
        
        if (! value) continue;
        
        [result setObject : value forKey : rd.name];
    }
    
    return result;
}

- (void) deleteObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self deleteStmtForObject : object];
    
    [stmt execute];
    
    [self commit];
    
    [self deleteFetchedObject : object];
}

- (void) deleteFetchedObject : (NSManagedObject *) obj {
    
    [self->fetchedObjects removeObjectForKey : obj.objectID.URIRepresentation.absoluteString];
}

- (void) deleteRelationshipsForObject : (NSManagedObject *) object {
    
    NSEntityDescription * ed = object.entity;
    
    NSDictionary * relationships = ed.relationshipsByName;
    
    NSEnumerator * enumerator = relationships.objectEnumerator;
    
    NSRelationshipDescription * rd = enumerator.nextObject;
    
    while (rd) {
        
        [self deleteRelationship : rd forObject : object];
        
        rd = enumerator.nextObject;
    }
    
    [self commit];
}

- (void) deleteRelationship : (NSRelationshipDescription *) relationship forObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self deleteRelationshipStmt : relationship forObject : object];
    
    [stmt execute];
}

- (OdbcStatement *) deleteRelationshipStmt : (NSRelationshipDescription *) relationship
                                 forObject : (NSManagedObject *) object {
    
    NSString * sql = [self deleteRelationshipSql : relationship];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setDeleteRelationshipParameters : object stmt : stmt];
    
    return stmt;
}

- (NSString *) deleteRelationshipSql : (NSRelationshipDescription *) relationship {
    
    NSString * relTabName = [self tableForRelationship : relationship];
    
    NSString * srcTabName = relationship.entity.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"delete from %@ where %@ = ?",relTabName,srcTabName];
    
    return sql;
}

- (void) setDeleteRelationshipParameters : (NSManagedObject *) object stmt : (OdbcStatement *) stmt {
    
    unsigned long pk = [self primaryKeyForObject : object];
    
    [stmt setLong : 1 value : pk];
}

- (OdbcStatement *) deleteStmtForObject : (NSManagedObject *) object {
    
    NSString * sql = [self deleteSqlForObject : object];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setDeleteParametersForObject : object stmt : stmt];
    
    return stmt;
}

- (NSString *) deleteSqlForObject : (NSManagedObject *) object {
    
    NSString * columnName = object.entity.name;
    
    NSString * sql = [NSMutableString stringWithFormat : @"delete from %@ where id = ?",columnName];
    
    return sql;
}

- (void) setDeleteParametersForObject : (NSManagedObject *) object stmt : (OdbcStatement *) stmt {
    
    unsigned long objId = [self primaryKeyForObject : object];
    
    [stmt setLong:1 value:objId];
}

- (unsigned long) primaryKeyForObject : (NSManagedObject *) object {
    
    NSManagedObjectID * mid = object.objectID;
    
    return [self primaryKeyForObjectId : mid];
}

- (unsigned long) primaryKeyForObjectId : (NSManagedObjectID *) objectId {
    
    NSNumber * number = [self->odbcStore referenceObjectForObjectID : objectId];
    
    return number.unsignedLongValue;
}

- (NSManagedObjectID *) objectIdForEntity : (NSEntityDescription *) entity primaryKey : (unsigned long) pk {
    
    NSManagedObjectID * objId = [self->odbcStore newObjectIDForEntity : entity referenceObject : @(pk)];
    
    return objId;
}

- (OdbcStatement *) statementForSql : (NSString *) sql {
    
    OdbcStatement * stmt = [self->stmtDict objectForKey : sql];
    
    if (stmt) return stmt;
    
    stmt = [self->odbcConnection newStatement];
    
    [stmt prepare : sql];
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    if (! [dbms hasPrefix : @"Oracle"]) {
    
        [self->stmtDict setValue : stmt forKey : sql];
    }
    
    return stmt;
}

- (void) insertObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self insertStmtForObject : object];
    
    [stmt execute];
    
    [self commit];
    
    [self insertFetchedObject : object];
}

- (void) insertFetchedObject : (NSManagedObject *) obj {
        
    OdbcObject * oo = [OdbcObject objectWithObject : obj store : self->odbcStore];
    
    NSString * key = obj.objectID.URIRepresentation.absoluteString;
    
    NSString * val = oo.string;
    
    [self->fetchedObjects setObject : val forKey : key];
}

- (void) insertRelationshipsForObject : (NSManagedObject *) object {
    
    [self deleteRelationshipsForObject : object];

    NSEntityDescription * ed = object.entity;
    
    NSDictionary * relationships = ed.relationshipsByName;
    
    NSEnumerator * enumerator = relationships.objectEnumerator;
    
    NSRelationshipDescription * rd = enumerator.nextObject;
    
    while (rd) {
        
        [self insertRelationship : rd forObject : object];
        
        rd = enumerator.nextObject;
    }
    
    [self commit];
    
    [self updateFetchedObject : object];
}

- (void) insertRelationship : (NSRelationshipDescription *) relationship forObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self insertRelationshipStmt : relationship forObject : object];
    
    NSSet * dstObjects = [object mutableSetValueForKey : relationship.name];

    for (NSManagedObject * dstObject in dstObjects) {
        
        [self setInsertRelationshipParameters : object dstObject : dstObject stmt : stmt];
        
        [stmt execute];
        
        [self updateFetchedObject : dstObject];
    }
}

- (void) setInsertRelationshipParameters : (NSManagedObject *) srcObject
                               dstObject : (NSManagedObject *) dstObject
                                    stmt : (OdbcStatement *) stmt {
    
    [stmt setLong : 1 value : [self primaryKeyForObject : srcObject]];

    [stmt setLong : 2 value : [self primaryKeyForObject : dstObject]];
}

- (OdbcStatement *) insertRelationshipStmt : (NSRelationshipDescription *) relationship
                                 forObject : (NSManagedObject *) object {
    
    NSString * sql = [self insertRelationshipSql : relationship];
    
    OdbcStatement * stmt = [self statementForSql : sql];
        
    return stmt;
} 

- (NSString *) insertRelationshipSql : (NSRelationshipDescription *) relationship {
    
    NSString * relTabName = [self tableForRelationship : relationship];
    
    NSString * srcTabName = relationship.entity.name;
    
    NSString * dstTabName = relationship.destinationEntity.name;
    
    NSMutableString * sql =
    
    [NSMutableString stringWithFormat : @"insert into %@ (%@,%@) values (?,?)",relTabName,srcTabName,dstTabName];
    
    return sql;
}

- (OdbcStatement *) insertStmtForObject : (NSManagedObject *) object {
    
    NSString * sql = [self insertSqlForObject : object];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setInsertParametersForObject : object stmt : stmt];
    
    return stmt;
}

- (NSString *) insertSqlForObject : (NSManagedObject *) object {
    
    NSEntityDescription * ed = object.entity;
    
    NSString * tableName = ed.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"insert into %@ (id",tableName];
        
    for (NSString * key in ed.attributeKeys) {
        
        NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
        
        [sql appendString : @","];
        
        [sql appendString : ad.name];
    }
    
    [sql appendString : @") values (?"];
    
    for (NSString * key in ed.attributeKeys) {
        
        [sql appendString : @",?"];
    }
    
    [sql appendString : @")"];
    
    return sql;
}

- (void) setInsertParametersForObject : (NSManagedObject *) object stmt : (OdbcStatement *) stmt {
    
    int iparam = 1;
    
    unsigned long objId = [self primaryKeyForObject : object];
    
    [stmt setLong : iparam value : objId];
    
    iparam ++;
    
    NSEntityDescription * ed = object.entity;
        
    for (NSString * key in ed.attributeKeys) {
        
        NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
        
        id value = [object valueForKey : ad.name];
        
        [stmt setObject : iparam value : value];

        iparam ++;
    }
}

- (void) updateObject : (NSManagedObject *) object context : (NSManagedObjectContext *) context {
    
    [self checkUpdateIsPossible : object context : context];
    
    OdbcStatement * stmt = [self updateStmtForObject : object];
    
    [stmt execute];
    
    [self commit];
    
    [self updateFetchedObject : object];
}

- (void) updateFetchedObject : (NSManagedObject *) obj {
    
    OdbcObject * oo = [OdbcObject objectWithObject : obj store : self->odbcStore];
    
    NSString * key = obj.objectID.URIRepresentation.absoluteString;
    
    NSString * val = oo.string;
    
    [self->fetchedObjects setObject : val forKey : key];
}

- (void) checkUpdateIsPossible : (NSManagedObject *) obj context : (NSManagedObjectContext *) context {
    
    OdbcObject * rereadObject = [self rereadObject : obj context : context];
    
    NSString * newString = rereadObject.string;
    
    NSManagedObjectID * objId = obj.objectID;
    
    NSString * oldString = [self->fetchedObjects valueForKey : objId.URIRepresentation.absoluteString];
    
    if (! [oldString isEqualToString:newString]) {
                
        RAISE_ODBC_EXCEPTION_WITH_SQLSTATE ("Transaction rolled back","Database was changed by another application","40001");
    }
}

- (OdbcObject *) rereadObject : (NSManagedObject *) obj context : (NSManagedObjectContext *) context {
    
    NSDictionary * relationships;
    
    NSDictionary * attributes = [self fetchObject:obj.objectID context : context relationships : &relationships];
    
    return [OdbcObject objectWithId : obj.objectID
                         attributes : attributes
                      relationships : relationships
                              store : self->odbcStore];
}

- (void) updateRelationshipsForObject : (NSManagedObject *) object {
    
    [self insertRelationshipsForObject : object];
    
    [self commit];
    
    [self updateFetchedObject : object];
}

- (OdbcStatement *) updateStmtForObject : (NSManagedObject *) object {
    
    NSString * sql = [self updateSqlForObject : object];
    
    OdbcStatement * stmt = [self statementForSql : sql];
    
    [self setUpdateParametersForObject : object stmt : stmt];
    
    return stmt;
}

- (void) setUpdateParametersForObject : (NSManagedObject *) object stmt : (OdbcStatement *) stmt {
    
    int iparam = 1;
        
    NSEntityDescription * ed = object.entity;
    
    for (NSString * key in ed.attributeKeys) {
        
        NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
        
        id value = [object valueForKey : ad.name];
        
        [stmt setObject : iparam value : value];
        
        iparam ++;
    }
    
    unsigned long objId = [self primaryKeyForObject : object];
    
    [stmt setLong : iparam value : objId];
}

- (NSString *) updateSqlForObject : (NSManagedObject *) object {
    
    NSEntityDescription * ed = object.entity;
    
    NSString * tableName = ed.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"update %@ set ",tableName];
    
    bool first = YES;
    
    for (NSString * key in ed.attributeKeys) {
        
        NSAttributeDescription * ad = [ed.attributesByName objectForKey : key];
        
        if (! first) [sql appendString : @","];
        
        [sql appendFormat : @"%@ = ?", ad.name];
        
        first = NO;
    }
    
    [sql appendString : @" where id = ?"];
        
    return sql;
}

- (void) commit {
    
    [self->odbcConnection commit];
}

- (void) rollback {
    
    [self->odbcConnection rollback];
}

- (unsigned long) objectIdForName : (NSString *) name {
    
    unsigned long lastId;
    
    bool found = [self fetchCoreDataEntityForName : name lastId : &lastId];
    
    lastId ++;
    
    if (! found) {
        
        [self insertCoreDataEntity : lastId forName : name];
        
    } else {
        
        [self updateCoreDataEntity : lastId forName : name];
    }
    
    return lastId;
}

- (void) updateCoreDataEntity : (unsigned long) lastId forName : (NSString *) name {
    
    OdbcStatement * stmt = self.updateCoreDataEntityForNameStmt;
    
    [stmt setLong : 1 value : lastId];
    
    [stmt setString : 2 value : name];
    
    [stmt execute];
}

- (OdbcStatement *) updateCoreDataEntityForNameStmt {
    
    if (self->updateCoreDataEntityForNameStmt) return self->updateCoreDataEntityForNameStmt;
    
    OdbcStatement * stmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"update CoreDataEntity set lastId = ? where entityName = ?";
    
    [stmt prepare : sql];
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    if (! [dbms hasPrefix : @"Oracle"]) {

        self->updateCoreDataEntityForNameStmt = stmt;
    }
    
    return stmt;
}

- (void) insertCoreDataEntity : (unsigned long) lastId forName : (NSString *) name {
    
    OdbcStatement * stmt = self.insertCoreDataEntityForNameStmt;
    
    [stmt setString : 1 value : name];
    
    [stmt setLong : 2 value : lastId];
    
    [stmt execute];
}

- (OdbcStatement *) insertCoreDataEntityForNameStmt {
    
    if (self->insertCoreDataEntityForNameStmt) return self->insertCoreDataEntityForNameStmt;
    
    OdbcStatement * stmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"insert into CoreDataEntity (entityName,lastId) values (?,?)";
    
    [stmt prepare : sql];
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    if (! [dbms hasPrefix : @"Oracle"]) {

        self->insertCoreDataEntityForNameStmt = stmt;
    }
    
    return stmt;
}

- (bool) fetchCoreDataEntityForName : name lastId : (unsigned long *) lastId {
    
    OdbcStatement * stmt = self.fetchCoreDataEntityForNameStmt;
    
    [stmt setString : 1 value : name];
    
    [stmt execute];
    
    * lastId = 0;
    
    bool found = [stmt fetch];
    
    if (found) {
        
        * lastId = [stmt getLongByName : @"lastId"];
        
        if (stmt.wasNull) * lastId = 0;
    }
    
    [stmt closeCursor];
    
    return found;
}

- (OdbcStatement *) fetchCoreDataEntityForNameStmt {
    
    if (self->fetchCoreDataEntityForNameStmt) return self->fetchCoreDataEntityForNameStmt;
    
    OdbcStatement * stmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"select * from CoreDataEntity where entityName = ?";
    
    [stmt prepare : sql];
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    if (! [dbms hasPrefix : @"Oracle"]) {

        self->fetchCoreDataEntityForNameStmt = stmt;
    }
    
    return stmt;
}

+ (OdbcStoreDatabase *) databaseWithOdbcStore : (OdbcStore *) newOdbcStore {
    
    OdbcStoreDatabase * database = [[OdbcStoreDatabase alloc] initWithOdbcStore : newOdbcStore];
    
    return database;
}

- (OdbcStoreDatabase *) initWithOdbcStore : (OdbcStore *) newOdbcStore {

    self = [super init];
    
    if (! self) return self;
    
    self->odbcStore = newOdbcStore;
    
    self->odbcConnection = [OdbcConnection new];
    
    self->stmtDict = [NSMutableDictionary new];
    
    self->relationshipTablesDict = [NSMutableDictionary new];
    
    self->fetchedObjects = [NSMutableDictionary new];
    
    return self;
}

- (void) dealloc {
    
    [self disconnect];
}

- (void) connectDataSource : (NSString *) dataSource username : (NSString *) username password : (NSString *) password {
    
    [self->odbcConnection connect : dataSource username : username password : password];
    
    self->odbcConnection.transactionIsolation = SQL_TXN_SERIALIZABLE;
    
    self->catalog = self->odbcConnection.currentCatalog;
    
    self->schema = self->odbcConnection.currentSchema;
    
    [self createTablesIfRequired];
    
    [self commit];
}

- (void) disconnect {
    
    if (self->odbcConnection.connected) {
        
        [self->odbcConnection disconnect];
    }
}

- (void) createTablesIfRequired {
    
    [self createCoreDataEntityTableIfRequired];
    
    [self createEntityTablesIfRequired];
    
    [self createRelationshipsTablesIfRequired];
    
    [self->odbcConnection commit];
}

- (void) createRelationshipsTablesIfRequired {
    
    NSManagedObjectModel * mom = self->odbcStore.persistentStoreCoordinator.managedObjectModel;
    
    NSArray * entities = mom.entities;
        
    for (NSEntityDescription * ed in entities) {
        
        [self createRelationshipsTablesIfRequired : ed];
    }
}

- (void) createRelationshipsTablesIfRequired : (NSEntityDescription *) entity {
    
    NSArray * relationships = entity.relationshipsByName.allValues;
    
    for (NSRelationshipDescription * rd in relationships) {
        
        [self createRelationshipsTableIfRequired : rd];
    }
}

- (void) createRelationshipsTableIfRequired : (NSRelationshipDescription *) relationship {
    
    NSRelationshipDescription * mainRelationship = [self selectMainRelationship : relationship];
    
    if ([self tableExists : mainRelationship.name]) return;
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    NSEntityDescription * srcEntity = mainRelationship.entity;
    
    NSEntityDescription * dstEntity = mainRelationship.destinationEntity;
    
    NSString * tableName = mainRelationship.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"create table %@ (",tableName];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [sql appendFormat : @"%@ number(20) not null,",srcEntity.name];
        [sql appendFormat : @"%@ number(20) not null,",dstEntity.name];

    } else {
    
        [sql appendFormat : @"%@ bigint not null,",srcEntity.name];
        [sql appendFormat : @"%@ bigint not null,",dstEntity.name];
    }
    
    [sql appendFormat : @"primary key (%@,%@),",srcEntity.name,dstEntity.name];
    
    if (! mainRelationship.isToMany) {
        
        [sql appendFormat : @"unique key (%@),",srcEntity.name];
    }
    
    if (mainRelationship.inverseRelationship && ! mainRelationship.inverseRelationship.isToMany) {
        
        [sql appendFormat : @"unique key (%@),",dstEntity.name];
    }
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade,",
                            tableName,dstEntity.name,dstEntity.name];
        
    } else {
    
        [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade on update no action,",
                            tableName,dstEntity.name,dstEntity.name];
    }
    
    NSString * inverseTableName = [NSString stringWithFormat : @"%@%@",dstEntity.name,srcEntity.name];
    
    if (mainRelationship.inverseRelationship) {
        
        inverseTableName = mainRelationship.inverseRelationship.name;
    }
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade)" ,
                            inverseTableName,srcEntity.name,srcEntity.name];
        
    } else {
    
        [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade on update no action)" ,
                            inverseTableName,srcEntity.name,srcEntity.name];
    }
    
    [self->odbcConnection execDirect : sql];
}

- (void) createEntityTablesIfRequired {
    
    NSManagedObjectModel * mom = self->odbcStore.persistentStoreCoordinator.managedObjectModel;
    
    NSArray * entities = mom.entities;
    
    for (NSEntityDescription * ed in entities) {
        
        [self createEntityTableIfRequired : ed];
    }
}

- (void) createEntityTableIfRequired : (NSEntityDescription *) entity {
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    NSString * tableName = entity.name;
    
    if ([self tableExists : tableName]) {
        
        [self checkTableId : tableName];
        
        return;
    }
    
    NSMutableString * sql = [NSMutableString new];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [sql appendFormat : @"create table %@ (id number(20) not null primary key",tableName];
    
    } else {
    
        [sql appendFormat : @"create table %@ (id bigint not null primary key",tableName];
    }
    
    NSArray * attributes = entity.attributesByName.allValues;
        
    for (NSAttributeDescription * ad in attributes) {
                
        NSString * columnName = ad.name;
        
        NSString * columnType = [self sqlColumnTypeForAttribute : ad];
        
        NSString * notNull = @"not null";
        
        if (ad.isOptional) notNull = @"";
        
        if (ad.attributeType == NSStringAttributeType) {
            
            unsigned long columnWidth = [self sqlColumnWidthForAttribute : ad];
            
            [sql appendFormat : @",%@ %@(%lu) %@",columnName,columnType,columnWidth,notNull];
            
        } else {
        
            [sql appendFormat : @",%@ %@ %@",columnName,columnType,notNull];
        }
    }
    
    [sql appendString : @")"];
    
    [self->odbcConnection execDirect : sql];
}
    
- (unsigned long) sqlColumnWidthForAttribute : (NSAttributeDescription *) ad {
    
    unsigned long len = 256;
    
    NSArray * predicates = ad.validationPredicates;
    
    for (id pred in predicates) {
        
        NSString * expr = [pred description];
        
        NSArray * items = [expr componentsSeparatedByString : @" "];
        
        if (items.count != 3) continue;
        
        if (! [items[0] isEqualToString : @"length"]) continue;
        
        if (! [items[1] isEqualToString : @"<="]) continue;
        
        len = [items[2] integerValue];
        
        break;
    }
    
    return len;
}

- (void) checkTableId : (NSString *) tableName {
    
    NSString * sql = [NSString stringWithFormat : @"select max(id) from %@",tableName];
    
    OdbcStatement * stmt = [self->odbcConnection execDirect : sql];
    
    unsigned long maxIdTable = 0;
    
    if ([stmt fetch]) {
        
        maxIdTable = [stmt getUnsignedLong : 1];
        
        if (stmt.wasNull) maxIdTable = 0;
    }
    
    [stmt closeCursor];
    
    unsigned long maxIdSystem = 0;
    
    [self fetchCoreDataEntityForName : tableName lastId : &maxIdSystem];
    
    if (maxIdTable > maxIdSystem) {
        
        NSString * msg = [NSString stringWithFormat : @"Primary key '%lu' used in table '%@' is greather than corresponding"
                                                       "in table CoreDataEntity. Did you change table values manually?",
                                                        maxIdTable,tableName];
        
        RAISE_ODBC_EXCEPTION ("checkTableId",msg.UTF8String);
    }
}

- (NSString *) sqlColumnTypeForAttribute : (NSAttributeDescription *) attribute {
  
    NSString * sqlType;
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        switch (attribute.attributeType) {
                
            case NSInteger16AttributeType: sqlType = @"number(5)";      break;
                
            case NSInteger32AttributeType: sqlType = @"number(10)";     break;
                
            case NSInteger64AttributeType: sqlType = @"number(20)";     break;
                
            case NSDoubleAttributeType:    sqlType = @"float(53)";      break;
                
            case NSFloatAttributeType:     sqlType = @"float(24)";      break;
                
            case NSStringAttributeType:    sqlType = @"varchar";        break;
                
            case NSBooleanAttributeType:   sqlType = @"number(3)";      break;
                
            case NSDateAttributeType:      sqlType = @"timestamp";      break;
                
            default: {
                
                NSString * msg = [NSString stringWithFormat : @"Unsupported attribute type '%ld'",attribute.attributeType];
                
                RAISE_ODBC_EXCEPTION ("sqlColumnTypeForAttribute",msg.UTF8String);
            }
        }

    } else {
    
        switch (attribute.attributeType) {
                
            case NSInteger16AttributeType: sqlType = @"smallint"; break;
                
            case NSInteger32AttributeType: sqlType = @"integer";        break;
                
            case NSInteger64AttributeType: sqlType = @"bigint";         break;
                
            case NSDoubleAttributeType:    sqlType = @"float";          break;
                
            case NSFloatAttributeType:     sqlType = @"real";           break;
                
            case NSStringAttributeType:    sqlType = @"varchar";        break;
                
            case NSBooleanAttributeType:   sqlType = @"tinyint";        break;
                
            case NSDateAttributeType:      sqlType = @"timestamp";      break;
                
            default: {
                
                NSString * msg = [NSString stringWithFormat : @"Unsupported attribute type '%ld'",attribute.attributeType];
                
                RAISE_ODBC_EXCEPTION("sqlColumnTypeForAttribute",msg.UTF8String);
            }
        }
    }
    
    return sqlType;
}

- (void) createCoreDataEntityTableIfRequired {
    
    if ([self tableExists : @"CoreDataEntity"]) return;
    
    NSString * dbms = self->odbcConnection.dbmsName;
    
    NSString * sql;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        sql = @"create table CoreDataEntity ("
               " entityName varchar(128) primary key not null,"
               " lastId number(20) not null"
               ")";
        
    } else {
    
        sql = @"create table CoreDataEntity ("
               " entityName varchar(128) primary key not null,"
               " lastId bigint not null"
               ")";
    }
    
    [self->odbcConnection execDirect : sql];
    
    [self commit];
}

- (bool) tableExists : (NSString *) tableName {
    
    [self commit];
    
    OdbcStatement * tables = [self->odbcConnection tablesCatalog : self->catalog
                                                          schema : self->schema
                                                           table : tableName
                                                      tableTypes : @"TABLE"];
    
    int count = 0;
    
    while ([tables fetch]) {
        
        count ++;
    }
    
    [tables closeCursor];
    
    [self commit];
    
    if (count == 0) return NO;
    
    if (count > 1) {
        
        NSString * msg = [NSString stringWithFormat : @"multiple tables with name '%@' found.",tableName];
        
        RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,msg.UTF8String);
    }
    
    return YES;
}

@end
