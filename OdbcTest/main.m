//
//  main.c
//  OdbcTest
//
//  Created by Mikael Hakman on 2013-09-29.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

#import "OdbcTest.h"

int main (int argc, const char * argv []) {

    NSLog (@"%s",__PRETTY_FUNCTION__);
    
    OdbcTest * test = [OdbcTest new];
    
    [test run];
    
    return 0;
}

