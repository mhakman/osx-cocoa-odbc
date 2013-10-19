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
    
    NSDictionary * stmtDict;
    
    NSDictionary * relationshipTablesDict;
    
    NSString * catalog;
    
    NSString * schema;
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
    }
    
    [stmt closeCursor];
    
    return result;
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

- (void) deleteObject : (NSManagedObject *) object {
    
    //[self deleteRelationshipsForObject : object];
    
    OdbcStatement * stmt = [self deleteStmtForObject : object];
    
    [stmt execute];
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
    
    [self->stmtDict setValue : stmt forKey : sql];
    
    return stmt;
}

- (void) insertObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self insertStmtForObject : object];
    
    [stmt execute];
    
//    [self insertRelationshipsForObject : object];
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
}

- (void) insertRelationship : (NSRelationshipDescription *) relationship forObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self insertRelationshipStmt : relationship forObject : object];
    
    NSSet * dstObjects = [object mutableSetValueForKey : relationship.name];

    for (NSManagedObject * dstObject in dstObjects) {
        
        [self setInsertRelationshipParameters : object dstObject : dstObject stmt : stmt];
        
        [stmt execute];
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

- (void) updateObject : (NSManagedObject *) object {
    
    OdbcStatement * stmt = [self updateStmtForObject : object];
    
    [stmt execute];
    
    //[self insertRelationshipsForObject : object];
}

- (void) updateRelationshipsForObject : (NSManagedObject *) object {
    
    [self insertRelationshipsForObject : object];
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
    
    [self.updateCoreDataEntityForNameStmt setLong : 1 value : lastId];
    
    [self.updateCoreDataEntityForNameStmt setString : 2 value : name];
    
    [self.updateCoreDataEntityForNameStmt execute];
}

- (OdbcStatement *) updateCoreDataEntityForNameStmt {
    
    if (self->updateCoreDataEntityForNameStmt) return self->updateCoreDataEntityForNameStmt;
    
    self->updateCoreDataEntityForNameStmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"update CoreDataEntity set lastId = ? where entityName = ?";
    
    [self->updateCoreDataEntityForNameStmt prepare : sql];
    
    return self->updateCoreDataEntityForNameStmt;
}

- (void) insertCoreDataEntity : (unsigned long) lastId forName : (NSString *) name {
    
    [self.insertCoreDataEntityForNameStmt setString : 1 value : name];
    
    [self.insertCoreDataEntityForNameStmt setLong : 2 value : lastId];
    
    [self.insertCoreDataEntityForNameStmt execute];
}

- (OdbcStatement *) insertCoreDataEntityForNameStmt {
    
    if (self->insertCoreDataEntityForNameStmt) return self->insertCoreDataEntityForNameStmt;
    
    self->insertCoreDataEntityForNameStmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"insert into CoreDataEntity (entityName,lastId) values (?,?)";
    
    [self->insertCoreDataEntityForNameStmt prepare : sql];
    
    return self->insertCoreDataEntityForNameStmt;
}

- (bool) fetchCoreDataEntityForName : name lastId : (unsigned long *) lastId {
    
    [self.fetchCoreDataEntityForNameStmt setString : 1 value : name];
    
    [self.fetchCoreDataEntityForNameStmt execute];
    
    * lastId = 0;
    
    bool found = [self.fetchCoreDataEntityForNameStmt fetch];
    
    if (found) {
        
        * lastId = [self.fetchCoreDataEntityForNameStmt getLongByName : @"lastId"];
        
        if (self.fetchCoreDataEntityForNameStmt.wasNull) * lastId = 0;
    }
    
    [self.fetchCoreDataEntityForNameStmt closeCursor];
    
    return found;
}

- (OdbcStatement *) fetchCoreDataEntityForNameStmt {
    
    if (self->fetchCoreDataEntityForNameStmt) return self->fetchCoreDataEntityForNameStmt;
    
    self->fetchCoreDataEntityForNameStmt = [self->odbcConnection newStatement];
    
    NSString * sql = @"select * from CoreDataEntity where entityName = ?";
    
    [self->fetchCoreDataEntityForNameStmt prepare : sql];
    
    return self->fetchCoreDataEntityForNameStmt;
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
    
    NSEntityDescription * srcEntity = mainRelationship.entity;
    
    NSEntityDescription * dstEntity = mainRelationship.destinationEntity;
    
    NSString * tableName = mainRelationship.name;
    
    NSMutableString * sql = [NSMutableString stringWithFormat : @"create table %@ (",tableName];
    
    [sql appendFormat : @"%@ bigint unsigned not null,",srcEntity.name];
    [sql appendFormat : @"%@ bigint unsigned not null,",dstEntity.name];
    [sql appendFormat : @"primary key (%@,%@),",srcEntity.name,dstEntity.name];
    [sql appendFormat : @"unique key %@Unique (%@,%@),",tableName,srcEntity.name,dstEntity.name];
    
    if (! mainRelationship.isToMany) {
        
        [sql appendFormat : @"unique key (%@),",srcEntity.name];
    }
    
    if (mainRelationship.inverseRelationship && ! mainRelationship.inverseRelationship.isToMany) {
        
        [sql appendFormat : @"unique key (%@),",dstEntity.name];
    }
    
    [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade on update cascade,",
                        tableName,dstEntity.name,dstEntity.name];
    
    NSString * inverseTableName = [NSString stringWithFormat : @"%@%@",dstEntity.name,srcEntity.name];
    
    if (mainRelationship.inverseRelationship) {
        
        inverseTableName = mainRelationship.inverseRelationship.name;
    }
    
    [sql appendFormat : @"constraint %@ foreign key (%@) references %@ (id) on delete cascade on update cascade)" ,
                        inverseTableName,srcEntity.name,srcEntity.name];
    
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
    
    NSString * tableName = entity.name;
    
    if ([self tableExists : tableName]) {
        
        [self checkTableId : tableName];
        
        return;
    }
    
    NSMutableString * sql =
    
    [NSMutableString stringWithFormat : @"create table %@ (id bigint unsigned not null primary key unique",tableName];
    
    NSArray * attributes = entity.attributesByName.allValues;
        
    for (NSAttributeDescription * ad in attributes) {
                
        NSString * columnName = ad.name;
        
        NSString * columnType = [self sqlColumnTypeForAttribute : ad];
        
        NSString * notNull = @"not null";
        
        if (ad.isOptional) notNull = @"";
        
        [sql appendFormat : @",%@ %@ %@",columnName,columnType,notNull];
    }
    
    [sql appendString : @")"];
    
    [self->odbcConnection execDirect : sql];
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
    
    switch (attribute.attributeType) {
        
        case NSInteger16AttributeType: sqlType = @"smallint"; break;
            
        case NSInteger32AttributeType: sqlType = @"integer";      break;
            
        case NSInteger64AttributeType: sqlType = @"bigint";       break;
            
        case NSDoubleAttributeType:    sqlType = @"double";       break;
            
        case NSFloatAttributeType:     sqlType = @"float";        break;
            
        case NSStringAttributeType:    sqlType = @"varchar(256)"; break;
            
        case NSBooleanAttributeType:   sqlType = @"tinyint"     ; break;
            
        case NSDateAttributeType:      sqlType = @"timestamp"   ; break;

        default: {
            
            NSString * msg = [NSString stringWithFormat : @"Unsupported attribute type '%ld'",attribute.attributeType];
            
            RAISE_ODBC_EXCEPTION("sqlColumnTypeForAttribute",msg.UTF8String);
        }
    }
    
    return sqlType;
}

- (void) createCoreDataEntityTableIfRequired {
    
    if ([self tableExists : @"CoreDataEntity"]) return;
    
    NSString * sql = @"create table CoreDataEntity ("
                      " entityName varchar(128) primary key not null unique,"
                      " lastId bigint unsigned not null"
                      ")";
    
    [self->odbcConnection execDirect : sql];
}

- (bool) tableExists : (NSString *) tableName {
    
    OdbcStatement * tables = [self->odbcConnection tablesCatalog : self->catalog
                                                          schema : self->schema
                                                           table : tableName
                                                      tableTypes : @""];
    
    int count = 0;
    
    while ([tables fetch]) {
        
        count ++;
    }
    
    [tables closeCursor];
    
    if (count == 0) return NO;
    
    if (count > 1) {
        
        NSString * msg = [NSString stringWithFormat : @"multiple tables with name '%@' found.",tableName];
        
        RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,msg.UTF8String);
    }
    
    return YES;
}

- (void) dropTablesForModel : (NSManagedObjectModel *) model {
        
    NSArray * entities = model.entities;
    
    for (NSEntityDescription * ed in entities) {
        
        NSDictionary * rsDict = ed.relationshipsByName;
        
        for (NSRelationshipDescription * rd in rsDict.allValues) {
            
            @try {
            
                [self dropTableForRelationship : rd];
                
            } @catch (NSException * exception) {}
        }
    }
    
    for (NSEntityDescription * ed in entities) {
        
        @try {
            
            [self dropTable : ed.name];
            
        } @catch (NSException * exception) {}
    }
    
    @try {
        
        [self dropTable : @"CoreDataEntity"];
        
    } @catch (NSException * exception) {}
}

- (void) dropTableForRelationship : (NSRelationshipDescription *) relationship {
    
    NSString * tabName = [self tableForRelationship : relationship];
    
    [self dropTable : tabName];
}

- (void) dropTable : (NSString *) tableName {
    
    NSString * sql = [NSString stringWithFormat : @"drop table %@",tableName];
    
    [self->odbcConnection execDirect : sql];
}

@end
