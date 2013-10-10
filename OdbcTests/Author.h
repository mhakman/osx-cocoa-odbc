//
//  Author.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-09.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book;

@interface Author : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSSet *authorBooks;
@end

@interface Author (CoreDataGeneratedAccessors)

- (void)addAuthorBooksObject:(Book *)value;
- (void)removeAuthorBooksObject:(Book *)value;
- (void)addAuthorBooks:(NSSet *)values;
- (void)removeAuthorBooks:(NSSet *)values;

@end
