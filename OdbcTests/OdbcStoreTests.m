//
//  OdbcStoreTests.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-09.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcStoreTests.h"
#import "OdbcStore.h"
#import "Author.h"
#import "Book.h"

NSString * PersistentStoreType;
NSString * PersistentStoreClass;
NSURL    * PersistentStoreUrl;

@interface OdbcStoreTests ()

@property (nonatomic) NSManagedObjectContext       * moc;
@property (nonatomic) NSPersistentStoreCoordinator * psc;
@property (nonatomic) NSManagedObjectModel         * mom;
@property (nonatomic) NSURL                        * psu;
@property (nonatomic) NSURL                        * afd;
@property (nonatomic) NSString                     * productName;

@end

@implementation OdbcStoreTests

@synthesize moc,psc,mom,psu,afd,productName;

+ (void) initialize {
    
    PersistentStoreType = @"OdbcStore";
    
    PersistentStoreClass = @"OdbcStore";
    
    PersistentStoreUrl = [NSURL URLWithString : @"odbc:///testdb?username=root"];
    
    if (PersistentStoreClass) {
        
        [NSPersistentStoreCoordinator registerStoreClass : NSClassFromString (PersistentStoreClass)
                                            forStoreType : PersistentStoreType];
    }
}

- (NSManagedObjectContext *) moc {
    
    if (self->moc) return self->moc;
    
    self->moc = [NSManagedObjectContext new];
    
    [self->moc setPersistentStoreCoordinator : self.psc];
    
    return self->moc;
}

- (NSPersistentStoreCoordinator *) psc {
    
    if (self->psc) return self->psc;
    
    NSError * error = nil;
    
    self->psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel : self.mom];
    
    bool ok = [self->psc addPersistentStoreWithType : PersistentStoreType
                                      configuration : nil
                                                URL : self.psu
                                            options : nil
                                              error : &error];
    
    if (! ok) {
    
        STFail ([error description]);
    }
    
    return self->psc;
}

- (NSManagedObjectModel *) mom {
    
    if (self->mom) return self->mom;
        
    NSString * modelPath =
    
    [NSString stringWithFormat : @"file://%s/OdbcTests.octest/Contents/Resources/%@.momd",
                                 TARGET_BUILD_DIR,self.productName];
    
    NSURL * modelURL = [NSURL URLWithString : modelPath];
    
    self->mom = [[NSManagedObjectModel alloc] initWithContentsOfURL : modelURL];
        
    if (! self->mom) {
        
        NSString * desc = [NSString stringWithFormat : @"Cannot create managed object model from url '%@'",modelURL];
        
        NSDictionary * dict = @{NSLocalizedDescriptionKey : desc};
        
        NSError * error = [NSError errorWithDomain : @"Managed Object Model" code : 0 userInfo : dict];
        
        STFail ([error description]);
        
        return nil;
    }
    
    return self->mom;
}

- (NSURL *) psu {
    
    if (self->psu) return self->psu;
    
    if (PersistentStoreUrl) {
        
        self->psu = PersistentStoreUrl;
        
        return self->psu;
    }
        
    NSString * storeFileName = [NSString stringWithFormat:@"%@.storedata",self.productName];
    
    self->psu = [self.afd URLByAppendingPathComponent : storeFileName];
    
    return self->psu;
}

- (NSURL *) afd {
    
    if (self->afd) return self->afd;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    self->afd =
    
    [[fileManager URLsForDirectory : NSApplicationSupportDirectory inDomains : NSUserDomainMask] lastObject];
    
    NSError * error = nil;
    //
    // Get NSUrlIsDirectoryKey property for the url
    //
    NSDictionary * properties = [self->afd resourceValuesForKeys : @[NSURLIsDirectoryKey] error : &error];
    //
    // Check if we got any properties
    //
    if (!properties) {
        //
        // We did not - check if path exsists
        //
        if ([error code] == NSFileReadNoSuchFileError) {
            //
            // It does not - try to create the directory
            //
            bool ok = [fileManager createDirectoryAtPath : [self->afd path]
                             withIntermediateDirectories : YES
                                              attributes : nil
                                                   error : &error];
                        
            if (! ok) {
                //
                // Could not create directory
                //
                STFail ([error description]);
                
                return nil;
            }
            
        } else {
            //
            // It was some other error
            //
            STFail ([error description]);
                        
            return nil;
        }
        
    } else {
        //
        // Check if url is directory
        //
        if (! [properties[NSURLIsDirectoryKey] boolValue]) {
            //
            // No it is not
            //
            NSString * failureDescription =
            
            [NSString stringWithFormat : @"Expected a folder to store application data, found a file (%@).",
             [self->afd path]];
            
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];
            
            [dict setValue : failureDescription forKey : NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain : @"Applcation Support Directory" code : 101 userInfo : dict];
            
            STFail ([error description]);
                        
            return nil;
        }
    }
    
    return self->afd;
}

- (NSString *) productName {
    
    if (self->productName) return self->productName;
    
    self->productName = @"OdbcStoreTests";
    
    return self->productName;
}

- (NSManagedObject *) entityName : (NSString *) entityName
                        attrName : (NSString *) attrName
                       attrValue : (id) attrValue {
    
    NSSet * objects = self.moc.registeredObjects;
    
    for (NSManagedObject * mo in objects) {
        
        if (! [mo.entity.name isEqualToString : entityName]) continue;
        
        id value = [mo valueForKey : attrName];
        
        if (! [value isEqualTo:attrValue]) continue;
        
        return mo;
    }
    
    return nil;
}

- (void) setUp {
    
    [super setUp];
    
    [self setUpCoreData];
}

- (void) tearDown {
    
    [self tearDownCoreData];
    
    [super tearDown];
}

- (void) setUpCoreData {
    
    NSError * error = nil;
    
    self->moc = nil;
    
    self->psc = nil;
    
    self->mom = nil;
    
    [self dropTables];
    
    [self setUpObjectsAndRelationships];
    
    bool ok = [self.moc save : &error];
    
    if (! ok) STFail (error.description);
        
    self->moc = nil;
    
    self->psc = nil;
    
    self->mom = nil;
}

- (void) dropTables {
    
    NSPersistentStore * ps = [self.psc persistentStoreForURL : self.psu];
    
    if ([ps isKindOfClass : NSClassFromString (PersistentStoreClass)]) {
        
        OdbcStore * odbcStore = (OdbcStore *) ps;
        
        [odbcStore dropTablesForModel : self.mom];
        
        self->moc = nil;
        
        self->psc = nil;
        
        self->mom = nil;
    }
}

- (void) setUpObjectsAndRelationships {
    
    [self setUpObjects];
    
    [self setUpRelationships];
}

- (void) setUpObjects {
    
    [self setUpAuthors];
    
    [self setUpBooks];
}

- (void) setUpAuthors {
    
    NSEntityDescription * ed = [[self.mom entitiesByName] objectForKey : @"Author"];
    
    NSManagedObject * mo = [[NSManagedObject alloc] initWithEntity : ed insertIntoManagedObjectContext : self.moc];
    
    [mo setValue : @"Inger" forKey : @"firstName"];
    
    [mo setValue : @"Hakman" forKey : @"lastName"];

    mo = [[NSManagedObject alloc] initWithEntity : ed insertIntoManagedObjectContext : self.moc];
    
    [mo setValue : @"Mikael" forKey : @"firstName"];
    
    [mo setValue : @"Hakman" forKey : @"lastName"];
}

- (void) setUpBooks {
    
    NSEntityDescription * ed = [[self.mom entitiesByName] objectForKey : @"Book"];
    
    NSManagedObject * mo = [[NSManagedObject alloc] initWithEntity : ed insertIntoManagedObjectContext : self.moc];
    
    [mo setValue : @"First book" forKey : @"title"];
    
    [mo setValue : @1.23 forKey : @"price"];
    
    mo = [[NSManagedObject alloc] initWithEntity : ed insertIntoManagedObjectContext : self.moc];
    
    [mo setValue : @"Second book" forKey : @"title"];
    
    [mo setValue : @4.56 forKey : @"price"];
    
    mo = [[NSManagedObject alloc] initWithEntity : ed insertIntoManagedObjectContext : self.moc];
    
    [mo setValue : @"Third book" forKey : @"title"];
    
    [mo setValue : @7.98 forKey : @"price"];
}

- (void) setUpRelationships {
    
    Author * ingerAuthor = (Author *) [self entityName : @"Author" attrName : @"firstName" attrValue : @"Inger"];

    Author * mikaelAuthor = (Author *) [self entityName : @"Author" attrName : @"firstName" attrValue : @"Mikael"];
    
    Book * firstBook = (Book *) [self entityName : @"Book" attrName : @"title" attrValue : @"First book"];
    
    Book * secondBook = (Book *) [self entityName : @"Book" attrName : @"title" attrValue : @"Second book"];
    
    Book * thirdBook = (Book *) [self entityName : @"Book" attrName : @"title" attrValue : @"Third book"];
    
    [ingerAuthor addAuthorBooksObject : firstBook];
    
    [firstBook addBookAuthorsObject : ingerAuthor];
    
    [mikaelAuthor addAuthorBooksObject : secondBook];
    
    [secondBook addBookAuthorsObject : mikaelAuthor];
    
    [thirdBook addBookAuthorsObject : ingerAuthor];
    
    [thirdBook addBookAuthorsObject : mikaelAuthor];
    
    [ingerAuthor addAuthorBooksObject : thirdBook];
    
    [mikaelAuthor addAuthorBooksObject : thirdBook];
}

- (void) testExecuteFetchRequest {
    
    NSError * error = nil;
    
    NSFetchRequest * fr = [NSFetchRequest fetchRequestWithEntityName : @"Author"];
    
    NSArray * authors = [self.moc executeFetchRequest : fr error : &error];
    
    if (! authors) {
        
        STFail (error.description);
        
        return;
    }
            
    STAssertEquals (authors.count,(NSUInteger)2,@"");
    
    fr = [NSFetchRequest fetchRequestWithEntityName : @"Book"];
    
    NSArray * books = [self.moc executeFetchRequest : fr error : &error];
    
    if (! books) {
        
        STFail (error.description);
        
        return;
    }
    
    STAssertEquals (books.count,(NSUInteger)3,@"");
}

- (void) testExecuteFetchRequestWithPredicate {
    
    NSError * error = nil;
    
    NSFetchRequest * fr = [NSFetchRequest fetchRequestWithEntityName : @"Author"];
    
    NSPredicate * pred =
    
    [NSPredicate predicateWithFormat:@"firstName beginswith 'I' and lastName endsWith 'n'"];
    
    fr.predicate = pred;
    
    NSArray * authors = [self.moc executeFetchRequest : fr error : &error];
    
    if (! authors) {
        
        STFail (error.description);
        
        return;
    }
    
    STAssertEquals (authors.count,(NSUInteger)1,@"");
    
    fr = [NSFetchRequest fetchRequestWithEntityName : @"Book"];
    
    NSArray * books = [self.moc executeFetchRequest : fr error : &error];
    
    if (! books) {
        
        STFail (error.description);
        
        return;
    }
    
    STAssertEquals (books.count,(NSUInteger)3,@"");
}

- (void) tearDownCoreData {
    
    [self dropTables];
    
    self->moc = nil;
    
    self->psc = nil;
    
    self->mom = nil;
}

@end
