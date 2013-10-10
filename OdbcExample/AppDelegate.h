//
//  AppDelegate.h
//  OdbcExample
//
//  Created by Mikael Hakman on 2013-10-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Odbc/Odbc.h>

extern NSString * DraggedAuthorsType;
extern NSString * DraggedBooksType;

@class BooksController;
@class AuthorsController;

@interface AppDelegate : OdbcAppDelegate <NSApplicationDelegate>

@property (readonly) IBOutlet NSWindow * window;

@property (readonly) IBOutlet BooksController * booksController;
@property (readonly) IBOutlet AuthorsController * authorsController;

@property NSArray * booksSortDescriptors;
@property NSArray * authorsSortDescriptors;

@property IBOutlet NSButton * commitChangesButton;

- (IBAction) saveAction : (id) sender;

- (IBAction) reloadAction : (id) sender;

@end
