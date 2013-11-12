//
//  AuthorsController.h
//  Library1
//
//  Created by Mikael Hakman on 2013-10-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Odbc/Odbc.h>

@class AppDelegate;

@interface AuthorsController : OdbcArrayController

@property IBOutlet AppDelegate * appDelegate;

@property IBOutlet NSTableView * authorsTableView;

@end
