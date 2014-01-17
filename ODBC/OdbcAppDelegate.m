//
//  OdbcAppDelegate.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-10.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcAppDelegate.h"
#import "Odbc.h"

NSString * PersistentStoreType  = @"OdbcStore";
NSString * PersistentStoreClass = @"OdbcStore";

@interface OdbcAppDelegate () {
    
    bool terminating;
}

@property bool terminating;

@end

@implementation OdbcAppDelegate;

@synthesize terminating;
@synthesize persistentStoreType;
@synthesize persistentStoreClass;
@synthesize persistentStoreUrl;

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

@synthesize productName;
@synthesize applicationFilesDirectory;
@synthesize modelFileName;

@synthesize loginUrl;
//
// Initialize object
//
- (OdbcAppDelegate *) init {
    
    self = [super init];
    
    if (! self) return self;
    
    self->terminating = NO;
    
    return self;
}
//
// Set up mainWindow correctly after login dialog
//
- (void) applicationDidFinishLaunching : (NSNotification *) aNotification {

    NSApplication * app = NSApp;
    
    [app activateIgnoringOtherApps : YES];
/*
    if (self->loginController) {
        
        if (! [app.windows[0] isVisible]) {
        
            [app.windows[0] miniaturize : self];
        
            [app.windows[0] deminiaturize : self];
        }
        
        NSLog (@"hidden %d",[app isHidden]);
        
        [app unhide : self];
        
        [app.windows[0] makeFirstResponder : nil];
        
        [app.windows[0] makeKeyAndOrderFront : self];
    
        [app.windows[0] makeMainWindow];
        
        NSRunningApplication * ra = [NSRunningApplication currentApplication];
        
        [ra activateWithOptions : NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps];
    }
*/
}
//
// Returns persistent store type
//
- (NSString *) persistentStoreType {
    
    return PersistentStoreType;
}
//
// Returns persistent store class
//
- (NSString *) persistentStoreClass {
    
    return PersistentStoreClass;
}
//
// Returns persistent store url
//
- (NSURL *) persistentStoreUrl {
    
    if (self->persistentStoreUrl) return self->persistentStoreUrl;
    
    if (self.persistentStoreClass) {
        
        RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,"Method 'persistentStoreUrl should be implemented by the application");
    }
    
    
    NSString * storeFileName = [NSString stringWithFormat : @"%@.storedata",self.productName];
    
    self->persistentStoreUrl = [self.applicationFilesDirectory URLByAppendingPathComponent : storeFileName];
    
    return self->persistentStoreUrl;
}
//
// Allows user to login and returns persistenStoreUrl
//
- (NSURL *) loginUrl {
    
    NSString * loginServerPath = [self loginServerPath];

    FILE * loginPipe = popen (loginServerPath.UTF8String,"r");
    
    if (! loginPipe) {
        
        NSLog (@"Cannot open LoginServer");
        
        exit (1);
    }
    
    NSURL * url = [self processLoginServerOutputPipe : loginPipe];
    
    pclose (loginPipe);
    
    return url;
}
//
// Process LoginServer output and return loginUrl or exit
//
- (NSURL *) processLoginServerOutputPipe : (FILE *) loginPipe {
    
    char line [256];
    
    NSString * dsn;
    NSString * username;
    NSString * password;
    
    for (int i = 0; i < 4; ++i) {
        
        char * ptr = fgets (line,sizeof(line),loginPipe);
        
        if (ptr == 0) {
            
            NSLog (@"Cannot communicate with LoginServer");
            
            exit (1);
        }
        
        if (line[strlen(line) - 1] == '\n') line[strlen(line) - 1] = 0;
        
        switch (i) {
                
            case 0: {
                
                int rc = strcasecmp ("quit:",line);
                
                if (rc == 0) {
                    
                    exit (1);
                }
                
                rc = strcasecmp ("login:",line);
                
                if (rc != 0) {
                    
                    NSLog (@"Invalid response from LoginServer");
                    
                    exit (1);
                }
            }
                
            break;
                
            case 1: dsn      = [NSString stringWithUTF8String : line]; break;
            case 2: username = [NSString stringWithUTF8String : line]; break;
            case 3: password = [NSString stringWithUTF8String : line]; break;
        }
    }
    
    NSString * urlStr = [NSString stringWithFormat:@"odbc:///%@?username=%@&password=%@",dsn,username,password];
    
    NSURL * url = [NSURL URLWithString : urlStr];
    
    return url;
}
//
// Return path to LoginServer excutable
//
- (NSString *) loginServerPath {
    
    NSBundle * bundle = [NSBundle bundleForClass : [OdbcAppDelegate class]];
    
    NSString * loginPath = [NSString stringWithFormat : @"%@/LoginServer.app/Contents/MacOS/LoginServer",bundle.bundlePath];
    
    return loginPath;
}
//
// Returns product name
//
- (NSString *) productName {
    
    if (self->productName) return self->productName;
    
    NSDictionary * bundleInfo = [[NSBundle mainBundle] infoDictionary];
    
    self->productName = [bundleInfo objectForKey : @"CFBundleName"];
    
    return self->productName;
}
//
// Reloads data and merges changes
//
- (IBAction) reloadAction : (id) sender {
    
    [self reloadMerge : NO];
}
//
// Reloads data with or without merge
//
- (void) reloadMerge : (bool) merge {
            
    NSMutableDictionary * oldDict = [self currentObjectsDict];
    
    [self commit];
    
    [self fetchObjectsIntoContext : self.managedObjectContext];
    
    NSManagedObjectContext * newContext = [self createNewContext];
    
    NSSet * newSet = [self fetchObjectsIntoContext : newContext];
    
    NSMutableSet * delSet = [NSMutableSet new];
    
    NSMutableSet * insSet = [NSMutableSet new];
    
    NSMutableSet * updSet = [NSMutableSet new];
    
    for (NSManagedObject * newObj in newSet) {
        
        NSManagedObject * oldObj = [oldDict objectForKey : newObj.objectID];
        
        if (oldObj) {
            
            [self.managedObjectContext refreshObject : oldObj mergeChanges : merge];
            
            [updSet addObject : oldObj];
            
            [oldDict removeObjectForKey : oldObj.objectID];
            
        } else {
                        
            [insSet addObject : newObj];
        }
    }
    
    for (NSManagedObject * oldObj in oldDict.allValues) {
        
        [self.managedObjectContext deleteObject : oldObj];
        
        [delSet addObject : oldObj];
    }

    [self.managedObjectContext processPendingChanges];
    
    NSDictionary * userInfo = @{NSDeletedObjectsKey     : delSet,
                                NSInsertedObjectsKey    : insSet,
                                NSUpdatedObjectsKey     : updSet,
                                @"managedObjectContext" : self.managedObjectContext};
    
    NSNotification * notif = [NSNotification notificationWithName : NSManagedObjectContextObjectsDidChangeNotification
                                                           object : self.managedObjectContext
                                                         userInfo : userInfo];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc postNotification : notif];
}
//
// Return predicate for given entity
//
- (NSPredicate *) predicateForEntity : (NSEntityDescription *) entity {
    
    return nil;
}
//
// Fetch and return objects into context
//
- (NSSet *) fetchObjectsIntoContext : (NSManagedObjectContext *) moc {
    
    NSError * error = nil;
 
    NSMutableSet * set = [NSMutableSet new];
    
    NSArray * entities = self.managedObjectModel.entities;
    
    for (NSEntityDescription * ed in entities) {
        
        NSFetchRequest * fr = [NSFetchRequest fetchRequestWithEntityName : ed.name];
        
        NSPredicate * pred = [self predicateForEntity : ed];
        
        if (pred) fr.predicate = pred;
        
        NSArray * objs = [moc executeFetchRequest : fr error : &error];
        
        if (objs == nil) {
            
            [[NSApplication sharedApplication] presentError : error];
            
            return nil;
        }
        
        [set addObjectsFromArray : objs];
    }
    
    return set;
}
//
// Return dictionary of current objects
//
- (NSMutableDictionary *) currentObjectsDict {
    
    NSMutableDictionary * dict = [NSMutableDictionary new];
    
    NSSet * set = self.managedObjectContext.registeredObjects;
    
    for (NSManagedObject * obj in set) {
                
        [dict setObject : obj forKey : obj.objectID];
    }
    
    return dict;
}
//
// Commits current transaction
//
- (void) commit {
    
    NSSet * delSet = [NSSet new];
    
    NSSet * insSet = [NSSet new];
    
    NSSet * updSet = [NSSet new];
    
    NSSet * locSet = [NSSet new];
    
    NSSaveChangesRequest * req = [[NSSaveChangesRequest alloc] initWithInsertedObjects : insSet
                                                                        updatedObjects : updSet
                                                                        deletedObjects : delSet
                                                                         lockedObjects : locSet];
    
    NSPersistentStore * store = self.managedObjectContext.persistentStoreCoordinator.persistentStores[0];
    
    if ([store isKindOfClass : [NSIncrementalStore class]]) {
        
        NSError * error = nil;
        
        [((NSIncrementalStore *)store) executeRequest : req withContext : self.managedObjectContext error : &error];
        
        if (error) {
            
            [[NSApplication sharedApplication] presentError : error];
                        
            return;
        }
    }
}
//
// Should save data at exit?
//
- (bool) shouldSaveDataOnExit {
    
    return YES;
}
//
//------------------------------------------------------------------------------
// Code below has been generated by XCode and modified by me.
//------------------------------------------------------------------------------
//
// Returns the managed object context for the application.
//
- (NSManagedObjectContext *) managedObjectContext {
    
    if (self->managedObjectContext) return self->managedObjectContext;
    
    self->managedObjectContext = [self createNewContext];
        
    return self->managedObjectContext;
}
//
// Create and return new context
//
- (NSManagedObjectContext *) createNewContext {
 
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    
    NSManagedObjectContext * moc = [NSManagedObjectContext new];
    
    [moc setPersistentStoreCoordinator : coordinator];
    
    [moc setStalenessInterval : 0.0];
    
    NSMergePolicy * policy = [[NSMergePolicy alloc] initWithMergeType : NSMergeByPropertyObjectTrumpMergePolicyType];
    
    moc.mergePolicy = policy;
    
    return moc;
}
//
// Returns the persistent store coordinator for the application.
//
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (self->persistentStoreCoordinator) return self->persistentStoreCoordinator;
    //
    // Get managed object model
    //
    NSManagedObjectModel * mom = self.managedObjectModel;
    
    NSError * error = nil;
    //
    // Using a method to get URL instead of a constant as it was in XCode generated code
    //
    NSURL * url = self.persistentStoreUrl;
    //
    // Register custom store type
    //
    if (self.persistentStoreType && self.persistentStoreClass) {
        
        [NSPersistentStoreCoordinator registerStoreClass : NSClassFromString (self.persistentStoreClass)
                                            forStoreType : self.persistentStoreType];
    }
    //
    // Create persisten store coordinator
    //
    NSPersistentStoreCoordinator * coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel : mom];
    //
    // Using global variable PersistentStoreType instead of a constant as it was in XCode generated code
    //
    if (! [coordinator addPersistentStoreWithType : self.persistentStoreType
                                    configuration : nil
                                              URL : url
                                          options : nil
                                            error : &error]) {
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return nil;
    }
    
    self->persistentStoreCoordinator = coordinator;
    
    return self->persistentStoreCoordinator;
}
//
// Creates if necessary and returns the managed object model for the application.
//
- (NSManagedObjectModel *) managedObjectModel {
    
    if (self->managedObjectModel) return self->managedObjectModel;
    //
    // Using bundle info instead of a constant as it was in XCode generated code
    //
    NSString * fileName = self.modelFileName;
	
    NSURL * modelURL = [[NSBundle mainBundle] URLForResource : fileName withExtension : @"momd"];
    
    self->managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL : modelURL];
    
    if (! self->managedObjectModel) {
        
        NSString * desc = [NSString stringWithFormat : @"Cannot create managed object model from url '%@'",modelURL];
        
        NSDictionary * dict = @{NSLocalizedDescriptionKey : desc};
        
        NSError * error = [NSError errorWithDomain : @"Managed Object Model" code : 0 userInfo : dict];
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return nil;
    }
    
    return self->managedObjectModel;
}
//
// Returns model file name
//
- (NSString *) modelFileName {
    
    return [self productName];
}
//
// Returns the directory the application uses to store the Core Data store file.
//
// Note that this method is not used when running against 'OdbcStore'.
//
- (NSURL *) applicationFilesDirectory {
    
    if (self->applicationFilesDirectory) return self->applicationFilesDirectory;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSURL * appSupportURL =
    
    [[fileManager URLsForDirectory : NSApplicationSupportDirectory inDomains : NSUserDomainMask] lastObject];
    
    NSError * error = nil;
    //
    // Get NSUrlIsDirectoryKey property for the url
    //
    NSDictionary * properties = [appSupportURL resourceValuesForKeys : @[NSURLIsDirectoryKey] error : &error];
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
            bool ok = [fileManager createDirectoryAtPath : [appSupportURL path]
                             withIntermediateDirectories : YES
                                              attributes : nil
                                                   error : &error];
            
            if (! ok) {
                //
                // Could not create directory
                //
                [[NSApplication sharedApplication] presentError : error];
                
                [[NSApplication sharedApplication] terminate : self];
                
                return nil;
            }
            
        } else {
            //
            // It was some other error
            //
            [[NSApplication sharedApplication] presentError : error];
            
            [[NSApplication sharedApplication] terminate : self];
            
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
                                         [appSupportURL path]];
            
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];
            
            [dict setValue : failureDescription forKey : NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain : @"Applcation Support Directory" code : 101 userInfo : dict];
            
            [[NSApplication sharedApplication] presentError : error];
            
            [[NSApplication sharedApplication] terminate : self];
            
            return nil;
        }
    }
    
    self->applicationFilesDirectory = appSupportURL;
    
    return self->applicationFilesDirectory;
}
//
// Returns the NSUndoManager for the application.
//
- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window {
    
    return [[self managedObjectContext] undoManager];
}
//
// Saves data in database and reloads all data again.
//
- (IBAction) saveAction : (id) sender {
    
    [self saveReload : YES];
}
//
// Save data in database with or without reload
//
- (void) saveReload : (bool) reload {
    
    NSError * error = nil;
    
    if (! self->managedObjectModel || ! self->managedObjectContext || ! self->persistentStoreCoordinator) return;
    
    if (! [[self managedObjectContext] commitEditing]) {
        
        error = [NSError errorWithDomain : @"Commit Editing"
                                    code : 0
                                userInfo : @{NSLocalizedDescriptionKey : @"Cannot commit editing"}];
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return;
    }
    
    if (! [[self managedObjectContext] hasChanges]) return;
    
    if (! [[self managedObjectContext] save : &error]) {
        
        if ([error.domain isEqualToString : @"Transaction rolled back"]) {
            
            NSString * desc = @"The database was modified during your work. "
            "Your transaction was rolled back in order to keep database integrity. "
            "Your data will be reloaded from database. "
            "Press OK button now to continue.";
            
            NSDictionary * userInfo = [NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey];
            
            NSError * err = [NSError errorWithDomain : @"Transaction rolled back" code : 0 userInfo : userInfo];
            
            [[NSApplication sharedApplication] presentError : err];
            
            if (! self.terminating) [self reloadMerge : NO];
            
            return;
        }
        
        [[NSApplication sharedApplication] presentError : error];
                
        return;
    }
    
    if (reload) {
        
        [self reloadMerge : NO];
    }
}
//
// Called when application is about to terminate
//
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) theApp {
    
    if (terminating) return NSTerminateNow;
    
    self.terminating = YES;
    //
    // Should we save data on exit ?
    //
    if ([self shouldSaveDataOnExit]) {
        //
        // Save changes in the application's managed object context before the application terminates.
        //
        [self saveReload : NO];
    }
    //
    // Terminate application
    //
    return NSTerminateNow;
}

@end
