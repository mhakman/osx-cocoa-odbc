//
//  AppDelegate.m
//  LoginServer
//
//  Created by Mikael Hakman on 2014-01-16.
//  Copyright (c) 2014 Mikael Hakman. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginModel.h"

@interface AppDelegate ()

@property bool loginIsValid;

@end

@implementation AppDelegate

@synthesize dsnField;
//
// Initialize application
//
- (void) applicationDidFinishLaunching : (NSNotification *) notification {
    
    NSApplication * app = NSApp;
    
    [app activateIgnoringOtherApps : YES];
    
    [self.dsnField becomeFirstResponder];
}
//
// We should terminate when the last window is closed
//
- (BOOL) applicationShouldTerminateAfterLastWindowClosed : (NSApplication *) theApplication {
    
    return YES;
}
//
// Terminate application
//
- (void) applicationWillTerminate : (NSNotification *) notification {

    if (! self.loginIsValid) {
        
        printf ("quit:\n");
    }
}
//
// Quit action
//
- (IBAction) quitAction : (id) sender {
    
    NSApplication * app = NSApp;
    
    [app terminate : self];
}
//
// Login action
//
- (IBAction) loginAction : (id) sender {

    NSApplication * app = NSApp;

    @try {
     
        [self.loginModel loginAndOut];
        
        self.loginIsValid = YES;
        
        printf ("login:\n");
        
        printf ("%s\n",self.loginModel.dsn.UTF8String);
        
        printf ("%s\n",self.loginModel.username.UTF8String);
    
        printf ("%s\n",self.loginModel.password.UTF8String);
    
        [app terminate : self];
        
    } @catch (NSException * ex) {
        
        NSDictionary * userInfo = @{NSLocalizedDescriptionKey : ex.description};
        
        NSError * err = [NSError errorWithDomain : @"Could not connect to database" code : 0 userInfo : userInfo];
        
        [app presentError : err];
    }
}

@end
