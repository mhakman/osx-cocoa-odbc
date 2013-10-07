//
//  BooksController.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-05.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "BooksController.h"

#import "AppDelegate.h"

@interface BooksController () {
    
@protected
    
    NSMutableArray * draggedBooks;
}

@end

@implementation BooksController

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    [self setUpDragAndDrop];
}

- (void) setUpDragAndDrop {
    
    [self.booksTableView registerForDraggedTypes : [NSArray arrayWithObject : DraggedBooksType]];
    
    [self.booksTableView setDraggingSourceOperationMask : NSDragOperationLink forLocal : YES];
    
    [self.booksTableView setDraggingSourceOperationMask : NSDragOperationCopy forLocal : NO];
}

- (BOOL)   tableView : (NSTableView  *) tableView
writeRowsWithIndexes : (NSIndexSet   *) rowIndexes
        toPasteboard : (NSPasteboard *) pboard {
    
    [pboard clearContents];
    
    self->draggedBooks = [NSMutableArray arrayWithCapacity : rowIndexes.count];
    
    NSMutableString * booksText = [NSMutableString new];
    
    [rowIndexes enumerateIndexesUsingBlock : ^ void (NSUInteger index, BOOL * stop) {
        
        NSManagedObject * book = [self.arrangedObjects objectAtIndex : index];
        
        [self->draggedBooks addObject : book];
        
        [booksText appendFormat : @"%@ %@\n",[book valueForKey : @"title"],[book valueForKey : @"price"]];
    }];
    
    NSData * data = [NSData dataWithBytes : &self->draggedBooks length : sizeof (self->draggedBooks)];
    
    [pboard setData : data forType : DraggedBooksType];
    
    [pboard setString : booksText forType : NSStringPboardType];
    
    return YES;
}



@end
