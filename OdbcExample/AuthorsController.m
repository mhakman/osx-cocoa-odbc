//
//  AuthorsController.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-04.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "AuthorsController.h"

#import "AppDelegate.h"

@interface AuthorsController () {
    
@protected
    
    NSMutableArray * draggedAuthors;
}

@end

@implementation AuthorsController

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    [self setUpDragAndDrop];
}

- (void) setUpDragAndDrop {
    
    [self.authorsTableView registerForDraggedTypes : [NSArray arrayWithObject : DraggedAuthorsType]];
    
    [self.authorsTableView setDraggingSourceOperationMask : NSDragOperationLink forLocal : YES];
    
    [self.authorsTableView setDraggingSourceOperationMask : NSDragOperationCopy forLocal : NO];
}

- (BOOL)   tableView : (NSTableView  *) tableView
writeRowsWithIndexes : (NSIndexSet   *) rowIndexes
        toPasteboard : (NSPasteboard *) pboard {
    
    [pboard clearContents];
        
    self->draggedAuthors = [NSMutableArray arrayWithCapacity : rowIndexes.count];
    
    NSMutableString * authorsText = [NSMutableString new];
    
    [rowIndexes enumerateIndexesUsingBlock : ^ void (NSUInteger index, BOOL * stop) {
        
        NSManagedObject * author = [self.arrangedObjects objectAtIndex : index];
        
        [self->draggedAuthors addObject : author];
        
        [authorsText appendFormat : @"%@ %@\n",[author valueForKey : @"firstName"],[author valueForKey : @"lastName"]];
    }];
    
    NSData * data = [NSData dataWithBytes : &self->draggedAuthors length : sizeof (self->draggedAuthors)];
    
    [pboard setData : data forType : DraggedAuthorsType];
    
    [pboard setString : authorsText forType : NSStringPboardType];
    
    return YES;
}

@end
