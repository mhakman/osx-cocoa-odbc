//
//  BooksController.h
//  Library1
//
//  Created by Mikael Hakman on 2013-10-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Odbc/Odbc.h>

@class AppDelegate;

@interface BooksController : OdbcArrayController

@property IBOutlet AppDelegate * appDelegate;

@property IBOutlet NSTableView * booksTableView;

@end
