//
//  Book.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-09.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Author;

@interface Book : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSSet *bookAuthors;
@end

@interface Book (CoreDataGeneratedAccessors)

- (void)addBookAuthorsObject:(Author *)value;
- (void)removeBookAuthorsObject:(Author *)value;
- (void)addBookAuthors:(NSSet *)values;
- (void)removeBookAuthors:(NSSet *)values;

@end
