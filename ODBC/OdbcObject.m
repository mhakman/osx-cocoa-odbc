//
//  OdbcObject.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-21.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcObject.h"

@interface OdbcObject () {
    
    NSMutableString * string;
    
    NSIncrementalStore * store;
}

@property NSString * string;

@end

@implementation OdbcObject

@synthesize string;

+ (OdbcObject *) objectWithId : (NSManagedObjectID *) newId
                   attributes : (NSDictionary *) newAttributes
                relationships : (NSDictionary *) newRelationships
                        store : (NSIncrementalStore *) newStore {
    
    OdbcObject * obj =
    
    [[OdbcObject alloc] initWithId : newId attributes : newAttributes relationships : newRelationships store : newStore];
    
    return obj;
}

+ (OdbcObject *) objectWithObject : (NSManagedObject *) newObj store : (NSIncrementalStore *) newStore {
    
    OdbcObject * obj = [[OdbcObject alloc] initWithObject : newObj store : newStore];
    
    return obj;
}

- (OdbcObject *) initWithObject : (NSManagedObject *) newObj store : (NSIncrementalStore *) newStore {
    
    NSManagedObjectID * objId = newObj.objectID;
    
    NSDictionary * attributes = [self attributesFor : newObj];
    
    NSDictionary * relationships = [self relationshipsFor : newObj];
    
    return [self initWithId : objId attributes : attributes relationships : relationships store : newStore];
}

- (NSDictionary *) attributesFor : (NSManagedObject *) obj {
    
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    
    NSEntityDescription * ed = obj.entity;
    
    for (NSAttributeDescription * ad in ed.attributesByName.allValues) {
        
        id value = [obj valueForKey : ad.name];
        
        [attributes setObject : value forKey : ad.name];
    }
    
    return attributes;
}


- (NSDictionary *) relationshipsFor : (NSManagedObject *) obj {
    
    NSMutableDictionary * relationships = [NSMutableDictionary new];
    
    NSEntityDescription * ed = obj.entity;
    
    for (NSRelationshipDescription * rd in ed.relationshipsByName.allValues) {
        
        NSSet * relSet = [obj mutableSetValueForKey : rd.name];
        
        NSMutableArray * arr = [NSMutableArray new];
        
        for (NSManagedObject * mo in relSet) {
            
            [arr addObject : mo.objectID];
        }
        
        if (rd.isToMany) {
            
            [relationships setObject : arr forKey : rd.name];
            
        } else {
            
            [relationships setObject : arr[0] forKey : rd.name];
        }
    }

    return relationships;
}

- (OdbcObject *) initWithId : (NSManagedObjectID *) newId
                 attributes : (NSDictionary *) newAttributes
              relationships : (NSDictionary *) newRelationships
                      store : (NSIncrementalStore *) newStore {
    
    self = [super init];
    
    if (! self) return self;
    
    self->store = newStore;
    
    self->string = [NSMutableString new];
    
    [self encodeId : newId attributes : newAttributes];
    
    [self encodeId : newId relationships : newRelationships];
    
    return self;
}

- (void) encodeId : (NSManagedObjectID *) objId attributes : (NSDictionary *) attributes {
    
    bool first = YES;
    
    for (id attribute in attributes.allValues) {
        
        if (! first) {
            
            [self->string appendString : @"\t"];
        }
        
        [self->string appendString : [attribute description]];
        
        first = NO;
    }
}

- (void) encodeId : (NSManagedObjectID *) objId relationships : (NSDictionary *) relationships {
    
    NSArray * sortedRelationships = [self sortRelationships : relationships];
    
    for (id relationship in sortedRelationships) {
        
        [self->string appendString : @"\n"];
        
        if ([relationship isKindOfClass : [NSManagedObjectID class]]) {
            
            NSNumber * pk = [self->store referenceObjectForObjectID : objId];
            
            [self->string appendString : pk.stringValue];
            
            continue;
        }
        
        NSArray * objIds = relationship;
        
        NSArray * sortedObjIds = [self sortObjIds : objIds];
        
        bool first = YES;
        
        for (NSManagedObjectID * objId in sortedObjIds) {
            
            if (! first) {
                
                [self->string appendString : @"\t"];
            }
            
            NSNumber * pk = [self->store referenceObjectForObjectID : objId];
            
            [self->string appendString : pk.stringValue];
            
            first = NO;
        }
    }
}

- (NSArray *) sortRelationships : (NSDictionary *) relationships {
    
    NSMutableArray * result = [NSMutableArray new];
    
    NSArray * keys = relationships.allKeys;
    
    NSArray * sortedKeys = [keys sortedArrayUsingComparator: ^ (NSString *  obj1, NSString * obj2) {
        
        return [obj1 compare : obj2];
    }];
    
    for (NSString * key in sortedKeys) {
        
        [result addObject : [relationships valueForKey : key]];
    }
    
    return result;
}

- (NSArray *) sortObjIds : (NSArray *) objIds {
    
    NSArray * sortedObjIds = [objIds sortedArrayUsingComparator: ^ (id objId1, id objId2) {
        
        NSNumber * pk1 = [self->store referenceObjectForObjectID : objId1];
        
        NSNumber * pk2 = [self->store referenceObjectForObjectID : objId2];
        
        if ([pk1 integerValue] > [pk2 integerValue]) {
            
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([pk1 integerValue] < [pk2 integerValue]) {
            
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    

    return sortedObjIds;
}


- (BOOL) isEqual : (id) obj {
    
    if (! [obj isMemberOfClass : [OdbcObject class]]) return NO;
    
    OdbcObject * that = (OdbcObject *) obj;
    
    if ([self->string isEqualToString : that->string]) return YES;
    
    return NO;
}

@end
