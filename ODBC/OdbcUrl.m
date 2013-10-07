//
//  OdbcUrl.m
//  Library1
//
//  Created by Mikael Hakman on 2013-10-06.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcUrl.h"

static NSString * OdbcScheme = @"odbc";

@interface OdbcUrl ()

@property NSString * dataSource;

@property NSString * username;

@property NSString * password;

@end

@implementation OdbcUrl

+ (OdbcUrl *) urlWithUrl : (NSURL *) url {
    
    OdbcUrl * odbcUrl = [[OdbcUrl alloc] initWithUrl : url];
    
    return odbcUrl;
}

- (OdbcUrl *) initWithUrl : (NSURL *) url {
    
    self = [super initWithString : url.absoluteString];
    
    if (! self) return self;
    
    bool valid = [self parseUrl];
    
    if (! valid) return nil;
    
    return self;
}

- (bool) parseUrl {
    
    bool valid = YES;
        
    if (! [self.scheme isEqualToString : OdbcScheme]) valid = NO;
    
    if (self.host != nil) valid = NO;
        
    if (self.port != nil) valid = NO;
    
    NSRange range = [self.path rangeOfString : @"/" options : NSBackwardsSearch];
    
    if (range.location != 0) valid = NO;
    
    self.dataSource = [self.path substringFromIndex : 1];
    
    if (self.dataSource == nil || self.dataSource.length < 1) valid = NO;
    
    NSString * query = self.query;
    
    NSCharacterSet * delims = [NSCharacterSet characterSetWithCharactersInString : @"=&"];
    
    NSCharacterSet * spaces = [NSCharacterSet characterSetWithCharactersInString : @" \t\n\r"];
    
    NSArray * items = [query componentsSeparatedByCharactersInSet : delims];
    
    if (items.count != 0 && items.count != 2 && items.count != 4) valid = NO;
    
    for (int i = 0; i < items.count; i += 2) {
        
        NSString * name = [[[items objectAtIndex : i] lowercaseString] stringByTrimmingCharactersInSet : spaces];
        
        NSString * value = [items objectAtIndex : i + 1];
        
        if ([name isEqualToString : @"username"]) {
            
            self.username = value;
            
        } else if ([name isEqualToString : @"password"]) {
            
            self.password = value;
        }
    }
    
    return valid;
}

- (NSString *) description {
    
    NSMutableString * desc = [NSMutableString new];
    
    if (self.scheme) [desc appendFormat : @"%@:",self.scheme];
    
    [desc appendString : @"//" ];
    
    if (self.host) [desc appendString : self.host];
    
    if (self.port) [desc appendFormat : @":%@",self.port];
    
    [desc appendFormat : @"/%@?",self.dataSource];
    
    if (self.username) [desc appendFormat : @"username=%@",self.username];
    
    return desc;
}

@end
