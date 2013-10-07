//
//  BookAuthorsController.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "BookAuthorsController.h"

#import "AppDelegate.h"
#import "BooksController.h"

@implementation BookAuthorsController

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    [self setUpDragAndDrop];
}

- (void) setUpDragAndDrop {
    
    [self.bookAuthorsTableView registerForDraggedTypes : [NSArray arrayWithObject : DraggedAuthorsType]];
    
    [self.bookAuthorsTableView setDraggingSourceOperationMask : NSDragOperationLink forLocal : YES];
}

- (NSDragOperation) tableView : (NSTableView *)            tableView
                 validateDrop : (id <NSDraggingInfo>)      info
                  proposedRow : (NSInteger)                row
        proposedDropOperation : (NSTableViewDropOperation) operation {
    
    NSDragOperation dragOperation = info.draggingSourceOperationMask;
    
    if (! (dragOperation & NSDragOperationLink)) return NSDragOperationNone;
    
    NSPasteboard * pboard = info.draggingPasteboard;
    
    NSString * dataType = [pboard availableTypeFromArray : [NSArray arrayWithObject : DraggedAuthorsType]];
    
    if (! dataType) return NSDragOperationNone;
    
    if (self.booksController.selectionIndex == NSNotFound) return NSDragOperationNone;
    
    return NSDragOperationLink;
}

- (BOOL) tableView : (NSTableView *)           tableView
        acceptDrop : (id <NSDraggingInfo>)     info
               row : (NSInteger)               row
     dropOperation : (NSTableViewDropOperation) operation {
    
    NSPasteboard * pboard = info.draggingPasteboard;
    
    NSData * authorsData = [pboard dataForType : DraggedAuthorsType];
    
    NSArray * authors = *((NSArray * const *) authorsData.bytes);
    
    [self addAuthors : authors];
    
    return YES;
}

- (void) addAuthors : (NSArray *) authors {
    
    NSArray * books = self.booksController.arrangedObjects;
    
    NSManagedObject * book = [books objectAtIndex : self.booksController.selectionIndex];
    
    NSMutableSet * bookAuthors = [book mutableSetValueForKey : @"bookAuthors"];
        
    for (NSManagedObject * author in authors) {
        
        if ([bookAuthors containsObject : author]) continue;
        
        [bookAuthors addObject : author];
    }
}

@end
