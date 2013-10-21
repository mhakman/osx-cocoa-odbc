//
//  OdbcAppDelegate.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-10.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * PersistentStoreType;
extern NSString * PersistentStoreClass;

@interface OdbcAppDelegate : NSObject <NSApplicationDelegate>

@property (readonly,nonatomic) NSString * persistentStoreType;
@property (readonly,nonatomic) NSString * persistentStoreClass;
@property (readonly,nonatomic) NSURL    * persistentStoreUrl;

@property (readonly,nonatomic) NSManagedObjectContext       * managedObjectContext;
@property (readonly,nonatomic) NSManagedObjectModel         * managedObjectModel;
@property (readonly,nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;

@property (readonly,nonatomic) NSString * productName;
@property (readonly,nonatomic) NSURL    * applicationFilesDirectory;

- (IBAction) saveAction : (id) sender;

- (IBAction) reloadAction : (id)sender;

- (NSObjectController *) controllerForEntity : (NSString *) entityName;

- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window;

- (void) applicationDidFinishLaunching : (NSNotification *) aNotification;

- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) sender;

@end
