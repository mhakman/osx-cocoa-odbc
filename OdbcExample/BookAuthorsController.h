//
//  BookAuthorsController.h
//  Library1
//
//  Created by Mikael Hakman on 2013-10-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Odbc/Odbc.h>

@class AppDelegate;

@class BooksController;

@interface BookAuthorsController : OdbcArrayController

@property IBOutlet AppDelegate * appDelegate;

@property IBOutlet NSTableView * bookAuthorsTableView;

@property IBOutlet BooksController * booksController;

@end
