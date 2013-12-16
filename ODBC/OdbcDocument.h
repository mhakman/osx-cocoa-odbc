//
//  OdbcDocument.h
//  Odbc
//
//  Created by Mikael Hakman on 2013-11-14.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//------------------------------------------------------------------------------
/**
 The OdbcDocument class is inteded to use instead of XCode generated NSPersistentDocument
 class when creating a Core Data document-based project.
 
 When creating a new application, uncheck 'Create Document-Based application and
 uncheck also 'Use Core Data' check box. Then let your document inherit from 
 OdbcDocument like this:
 <pre><code>
 // MyDocument.h
 
 #import &lt;Cocoa/Cocoa.h&gt;
 #import &lt;Odbc/Odbc.h&gt;
 
 @interface MyDocument : OdbcDocument
 
 @end
 </code></pre>
 In your now empty MyDocument.m implement following methods:
 
 <pre><code>
 
 // MyDocument.m
 
 - (NSURL *) persistentStoreUrl {
 
    return [NSURL URLWithString : @"odbc:&#47;//testdb?username=root&password=secret"];
 }
 
 - (NSString *) windowNibName {
 
    return @"MyDocument"
 
 </code></pre>
 This methods will be called by OdbcDocument to get ODBC database URL and name of
 document nib file. 
 
 The URL shown above is only an example. You should replace 'testdb' by your own ODBC
 data source name (DSN). You should replace 'root' with your username and you
 should replace 'secrect' by your own password.
 
 The class name 'MyDocument' and nib name 'MyDocument' shown above are also only an example.
 */
//------------------------------------------------------------------------------
@interface OdbcDocument : NSPersistentDocument
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
 This property shall return name of document nib file.
 
 @return document nib file name.
*/
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSString * windowNibName;
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
 
 If you use NSArrayController for data access then in its Attribute Inspector in
 XCode Interface Builder you should set it to entity mode and specify the entity
 name. Next in Bindings Inspector in Managed Object Context you should bind to
 your using managedObjectContext as Model Key Path. 
 
 @return Core Data NSManagedObjectContext for the document.
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
 This returns Core Data NSManagedObjectModel for the document.
 
 @return NSManagedObjectModel for the application
 */
//------------------------------------------------------------------------------
@property (readonly,nonatomic) NSManagedObjectModel * managedObjectModel;
//------------------------------------------------------------------------------
/**
 This returns NSPersistentStoreCoordinator for the document.
 
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
