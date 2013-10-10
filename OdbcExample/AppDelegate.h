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

@property (readonly) IBOutlet NSWindow * window;

@property (readonly,nonatomic) NSManagedObjectContext * managedObjectContext;

@property NSArray * booksSortDescriptors;
@property NSArray * authorsSortDescriptors;

@property IBOutlet NSButton * commitChangesButton;

- (IBAction) saveAction : (id) sender;

- (IBAction) reloadData : (id) sender;

@end
