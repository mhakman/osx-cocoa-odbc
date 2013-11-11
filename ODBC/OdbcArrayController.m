//
//  OdbcArrayController.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-11-11.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcArrayController.h"

@implementation OdbcArrayController

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver : self
           selector : @selector (didChangeObjects:)
               name : NSManagedObjectContextObjectsDidChangeNotification
             object : [self managedObjectContext]];
}

- (void) dealloc {
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc removeObserver : self
                  name : NSManagedObjectContextObjectsDidChangeNotification
                object : self.managedObjectContext];
}

- (void) didChangeObjects : (NSNotification *) notification {
    
    NSDictionary * userInfo = notification.userInfo;
    
    if (! userInfo) return;
    
    NSSet * insSet = [userInfo objectForKey : NSInsertedObjectsKey];
    
    if (! insSet) return;
    
    bool doFetch = NO;
    
    NSString * entityName = self.entityName;
    
    for (NSManagedObject * obj in insSet) {
        
        if ([obj.entity.name isEqualToString:entityName]) {
            
            doFetch = YES;
            
            break;
        }
    }
    
    if (doFetch) [self fetch : self];
}

@end
