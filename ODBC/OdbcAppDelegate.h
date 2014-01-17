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
The OdbcAppDelegate class is inteded to be used instead of XCode generated AppDelegate
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
 
In your now empty AppDelegate.m implement following methods:

<pre><code>

 #import "AppDelegate.h"
 
 @implementation AppDelegate
 
 - (void) applicationDidFinishLaunching:(NSNotification *) notification {
 
    [super applicationDidFinishLaunching : aNotification];
 }
 
 - (NSURL *) persistentStoreUrl {
 
    return self.loginUrl;
 }
 
</code></pre>
The method 'persistentStoreUrl' will be called by OdbcAppDelegate to get ODBC database URL. 
The method loginUrl is implemented by this class. It allows the user to fill in ODBC data
source name (DSN), username, and password using a dialog box. Then it verifies that
the information is correct by connecting to and disconnecting from the database.
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
Returns model file name.
 
This property returns model file name without extension. Implement it if your
model has other name than your application. Default implementation return name
of your application.
 
@return NSString containing model file name without extension.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * modelFileName;
//------------------------------------------------------------------------------
/**
This method shall return fetch predicate given entity.
 
This method shall be implemented by an application when application is using
predicates to fetch data. The default implementation returna nil which means
that no predicate is used.
 
@param entity the entity to return a predicate for.
 
@return NSPredicate or nil.
 */
//------------------------------------------------------------------------------
- (NSPredicate *) predicateForEntity : (NSEntityDescription *) entity;
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
/** This allows the user to login and returns Odbc Url

@return NSURL

This method displays a login dialog and lets the user to login. If the login is
ok then the method returns login information encoded as an NSURL. If the login
is not ok then the method displays an error box and waits for new login. The
user may terminate application using "Quit" button.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSURL * loginUrl;
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
This action reloads data from the database.
 
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
If you implement this method then you should call the superclass 
applicationDidFinishLaunching in the beginning of your method. Implementation 
provided here needs to do some cleanup if the method loginUrl was called.
 
See also Apple documentaton of NSApplicationDelegate protocol for the description.
 
@param notification a notification
*/
//------------------------------------------------------------------------------
- (void) applicationDidFinishLaunching : (NSNotification *) notification;
//------------------------------------------------------------------------------
/**
This method saves data by calling saveAction and then it terminates the application.
 
See Apple also documentaton of NSApplicationDelegate protocol for the description.
 
@param sender NSApplication
@return NSApplicationTerminateReply 
*/
//------------------------------------------------------------------------------
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) sender;
//------------------------------------------------------------------------------
/**
if you dont want do save data in the database on exit, implement this method and
return NO

@return bool
*/
//------------------------------------------------------------------------------
- (bool) shouldSaveDataOnExit;
//------------------------------------------------------------------------------
/**
@name Other methods
*/
//------------------------------------------------------------------------------
/**
This method returns undo manager for given window.

@param window the window
@return undo manager
*/
//------------------------------------------------------------------------------
- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window;

@end
