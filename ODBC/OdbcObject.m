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
}

@property NSString * string;

@end

@implementation OdbcObject

@synthesize string;

+ (OdbcObject *) objectWithId : (NSManagedObjectID *) newId
                   attributes : (NSDictionary *) newAttributes
                relationships : (NSDictionary *) newRelationships {
    
    OdbcObject * obj = [[OdbcObject alloc] initWithId : newId attributes : newAttributes relationships : newRelationships];
    
    return obj;
}

+ (OdbcObject *) objectWithObject : (NSManagedObject *) newObj {
    
    OdbcObject * obj = [[OdbcObject alloc] initWithObject : newObj];
    
    return obj;
}

- (OdbcObject *) initWithObject : (NSManagedObject *) newObj {
    
    NSManagedObjectID * objId = newObj.objectID;
    
    NSDictionary * attributes = [self attributesFor : newObj];
    
    NSDictionary * relationships = [self relationshipsFor : newObj];
    
    return [self initWithId : objId attributes : attributes relationships : relationships];
}

- (NSDictionary *) attributesFor : (NSManagedObject *) obj {
    
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    
    NSEntityDescription * ed = obj.entity;
    
    for (NSAttributeDescription * ad in ed.attributesByName.allValues) {
        
        id value = [obj valueForKey : ad.name];
        
        [attributes setObject:value forKey : ad.name];
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
              relationships : (NSDictionary *) newRelationships {
    
    self = [super init];
    
    if (! self) return self;
    
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
    
    for (id relationship in relationships.allValues) {
        
        [self->string appendString : @"\n"];
        
        if ([relationship isKindOfClass : [NSManagedObjectID class]]) {
            
            NSString * objStr = objId.URIRepresentation.absoluteString;
            
            [self->string appendString : objStr];
            
            continue;
        }
        
        NSArray * objIds = relationship;
        
        bool first = YES;
        
        for (NSManagedObjectID * objId in objIds) {
            
            if (! first) {
                
                [self->string appendString : @"\t"];
            }
            
            NSString * objStr = objId.URIRepresentation.absoluteString;
            
            [self->string appendString : objStr];
            
            first = NO;
        }
    }
}

- (BOOL) isEqual : (id) obj {
    
    if (! [obj isMemberOfClass : [OdbcObject class]]) return NO;
    
    OdbcObject * that = (OdbcObject *) obj;
    
    if ([self->string isEqualToString : that->string]) return YES;
    
    return NO;
}

@end
