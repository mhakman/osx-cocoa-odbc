//
//  AppDelegate.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "AppDelegate.h"
#import "BooksController.h"
#import "AuthorsController.h"

NSString * DraggedAuthorsType = @"library.authors";
NSString * DraggedBooksType   = @"library.books";

@implementation AppDelegate;

@synthesize window, authorsController, booksController;

- (void) applicationDidFinishLaunching : (NSNotification *) aNotification {
    
    [super applicationDidFinishLaunching : aNotification];
    
    [self setUpSortDescriptors];
    
    [self setUpNotifications];
}
//
// Sets up notifcations
//
- (void) setUpNotifications {
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver : self selector : @selector (objectsDidChange:)
               name : NSManagedObjectContextObjectsDidChangeNotification
             object : self.managedObjectContext];
}
//
// Called when data has been changed
//
- (void) objectsDidChange : (NSNotification *) notification {
    
    [self.commitChangesButton setEnabled : YES];
}
//
// Sets up sort descriptors
//
- (void) setUpSortDescriptors {
    
    NSSortDescriptor * titleSort =
    
    [NSSortDescriptor sortDescriptorWithKey : @"title" ascending : YES selector : @selector (localizedCompare:)];
    
    self.booksSortDescriptors = @[titleSort];
    
    NSSortDescriptor * firstNameSort =
    
    [NSSortDescriptor sortDescriptorWithKey : @"firstName" ascending : YES selector : @selector (localizedCompare:)];
    
    NSSortDescriptor * lastNameSort =
    
    [NSSortDescriptor sortDescriptorWithKey : @"lastName" ascending : YES selector : @selector (localizedCompare:)];
    
    self.authorsSortDescriptors = @[lastNameSort,firstNameSort];
}
//
// Returns persistent store url
//
- (NSURL *) persistentStoreUrl {
    
    if ([self.persistentStoreClass isEqualToString : @"OdbcStore"]) {
    
        return [NSURL URLWithString : @"odbc:///sqllib?username=libuser&password=lib"];
        
    } else {
        
        return super.persistentStoreUrl;
    }
}
//
// Reload data
//
- (IBAction) reloadAction : (id) sender {
    
    [super reloadAction : sender];
    
    [self.commitChangesButton setEnabled : NO];
}
//
// Performs the save action for the application.
//
- (IBAction) saveAction : (id) sender {
    
    [super saveAction : sender];
    
    [self.commitChangesButton setEnabled : NO];
    
}
//
// Called when application is about to terminate
//
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) sender {
    
    return [super applicationShouldTerminate : sender];
}

@end
