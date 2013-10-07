//
//  AppDelegate.h
//  Library1
//
//  Created by Mikael Hakman on 2013-10-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * PersistentStoreType;
extern NSString * PersistentStoreClass;
extern NSURL    * PersistentStoreUrl;
extern NSString * DraggedAuthorsType;
extern NSString * DraggedBooksType;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property NSArray * booksSortDescriptors;
@property NSArray * authorsSortDescriptors;

@property IBOutlet NSButton * commitChangesButton;

- (IBAction) saveAction : (id) sender;

@end
