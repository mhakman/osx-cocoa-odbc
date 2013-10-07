//
//  AuthorBooksController.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "AuthorBooksController.h"

#import "AppDelegate.h"

#import "AuthorsController.h"

@implementation AuthorBooksController

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    [self setUpDragAndDrop];
}

- (void) setUpDragAndDrop {
    
    [self.authorBooksTableView registerForDraggedTypes : [NSArray arrayWithObject : DraggedBooksType]];
    
    [self.authorBooksTableView setDraggingSourceOperationMask : NSDragOperationLink forLocal : YES];
}

- (NSDragOperation) tableView : (NSTableView *)            tableView
                 validateDrop : (id <NSDraggingInfo>)      info
                  proposedRow : (NSInteger)                row
        proposedDropOperation : (NSTableViewDropOperation) operation {
    
    NSDragOperation dragOperation = info.draggingSourceOperationMask;
    
    if (! (dragOperation & NSDragOperationLink)) return NSDragOperationNone;
    
    NSPasteboard * pboard = info.draggingPasteboard;
    
    NSString * dataType = [pboard availableTypeFromArray : [NSArray arrayWithObject : DraggedBooksType]];
    
    if (! dataType) return NSDragOperationNone;
    
    if (self.authorsController.selectionIndex == NSNotFound) return NSDragOperationNone;
    
    return NSDragOperationLink;
}

- (BOOL) tableView : (NSTableView *)           tableView
        acceptDrop : (id <NSDraggingInfo>)     info
               row : (NSInteger)               row
     dropOperation : (NSTableViewDropOperation) operation {
    
    NSPasteboard * pboard = info.draggingPasteboard;
    
    NSData * booksData = [pboard dataForType : DraggedBooksType];
    
    NSArray * books = *((NSArray * const *) booksData.bytes);
    
    [self addBooks : books];
    
    return YES;
}

- (void) addBooks : (NSArray *) books {
    
    NSArray * authors = self.authorsController.arrangedObjects;
    
    NSManagedObject * author = [authors objectAtIndex : self.authorsController.selectionIndex];
    
    NSMutableSet * authorBooks = [author mutableSetValueForKey : @"authorBooks"];
    
    for (NSManagedObject * book in books) {
        
        if ([authorBooks containsObject : book]) continue;
        
        [authorBooks addObject : book];
    }
}

@end
