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
//------------------------------------------------------------------------------
/**
The OdbcAppDelegate class is inteded to use instead of XCode generated AppDelegate
code when creating a Core Data project.

When creating a new application, uncheck 'Use Core Data' check box. Then let
your AppDelegate inherit from OdbcAppDelegate like this:
<pre><code>
 // Appdelegate.h
 
 #import &lt;Cocoa/Cocoa.h&gt;
 #import &lt;Odbc/Odbc.h&gt;
 
 @interface AppDelegate : OdbcAppDelegate <NSApplicationDelegate>
 
 @property (assign) IBOutlet NSWindow * window;
 
 @end
</code></pre>
In your now empty AppDelegate.m implement following method:

<pre><code>

 // AppDelegate.m
 
 - (NSURL *) persistentStoreUrl {

    return [NSURL URLWithString : @"odbc:&#47;//testdb?username=root&password=secret"];
 }
 
</code></pre>
This method will be called by OdncAppDelegate to get ODBC database URL. The URL
shown above is only an example. You should replace 'testdb' by your own ODBC
data source name (DSN). You should replace 'root' with your username and you
should replace 'secrect' by your own password.
*/
//------------------------------------------------------------------------------
@interface OdbcAppDelegate : NSObject <NSApplicationDelegate>
//------------------------------------------------------------------------------
/**
@name Methods to override
*/
//------------------------------------------------------------------------------
/**
This property returns ODBC URL. It should be overwriten by subclasses.

 Returned URL should have following format:
 <pre><code>
 odbc::&#47;//[data source name]/?username=[username]&password=[password]
 </code></pre>
 where |data source name] is ODBC data source name, [username] is database username
 and [password] is users password.

@return ODBC URL for ODBC database to use.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSURL * persistentStoreUrl;
//------------------------------------------------------------------------------
/**
 @name Properties to bind to
*/
//------------------------------------------------------------------------------
/**
This is the property to bind to.
 
If you use NSArrayCntroller for data access then in its Attribute Inspector in 
XCode Interface Builder you should set it to entity mode and specify the entity 
name as shown below:
<center>
<img src="../docs/Images/OwnCoreDataArrayControllerAttributes.png" alt="OwnCoreDataArrayControlerAttributes.png">
</center>
The entity 'Author' is only an example. You should replace it with your own entity.
 
Next in Bindings Inspector in Managed Object Context you should bind to AppDelegate
using managedObjectContext as Model Key Path. This is shown below:
 
 <center>
 <img src="../docs/Images/OwnCoreDataArrayControllerBindnings.png" alt="OwnCoreDataArrayControllerBindings.png">
 </center>

@return Core Data NSManagedObjectContext for the application.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSManagedObjectContext * managedObjectContext;
//------------------------------------------------------------------------------
/**
@name Other properties
*/
//------------------------------------------------------------------------------
/**
This returns persistent store type as NSString.
 
The default implementation returns @"OdbcStore".
 
@return NSPersistentStoreType
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * persistentStoreType;
//------------------------------------------------------------------------------
/**
This returns persistent store class name as NSString.
 
The default implementation returns @"OdbcStore".
 
@return Persistent Store Class Name
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * persistentStoreClass;
//------------------------------------------------------------------------------
/**
This returns Core Data NSManagedObjectModel for the application.
 
@warning Currently the model file name must be the same as applications.

@return NSManagedObjectModel for the application
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSManagedObjectModel * managedObjectModel;
//------------------------------------------------------------------------------
/**
This returns NSPersistentStoreCoordinator for the application.
 
@return Persistent Store Coordinator
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;
//------------------------------------------------------------------------------
/**
This returns application name as NSString.
 
@return application name
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * productName;
//------------------------------------------------------------------------------
/**
This returns an URL to a directory where your application can store data.
 
@return NSURL to applications data directory
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSURL * applicationFilesDirectory;
//------------------------------------------------------------------------------
/**
@name Implemented actions
*/
//------------------------------------------------------------------------------
/**
This action saves all changes to the database.

@param sender the sender of the message - can be nil
*/
//------------------------------------------------------------------------------
- (IBAction) saveAction : (id) sender;
//------------------------------------------------------------------------------
/**
This action reloads data from the database and reapplies any pending changes.
 
@param sender the sender of the message - can be nil
*/
//------------------------------------------------------------------------------
- (IBAction) reloadAction : (id)sender;
//------------------------------------------------------------------------------
/**
@name Launching and termination
*/
//------------------------------------------------------------------------------
/**
Currently this method does nothing.
 
See Apple documentaton of NSApplicationDelegate protocol for the description.
 
@param notification a notification
*/
//------------------------------------------------------------------------------
- (void) applicationDidFinishLaunching : (NSNotification *) notification;
//------------------------------------------------------------------------------
/**
This method saves data by calling saveAction and then terminates the application.
 
See Apple documentaton of NSApplicationDelegate protocol for the description.
 
@param sender NSApplication
@return NSApplicationTerminateReply 
*/
//------------------------------------------------------------------------------
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) sender;
//------------------------------------------------------------------------------
/**
@name Other methods
*/
//------------------------------------------------------------------------------
/**
This method returns controller given entity name.
 
@param entityName name ot the entity
@return NSObjectController or its subclass
*/
//------------------------------------------------------------------------------
- (NSObjectController *) controllerForEntity : (NSString *) entityName;
//------------------------------------------------------------------------------
/**
This method returns undo manager for given window.

@param window the window
@return undo manager
*/
//------------------------------------------------------------------------------
- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window;

@end
