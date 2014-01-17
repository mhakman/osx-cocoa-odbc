//
//  AppDelegate.h
//  LoginServer
//
//  Created by Mikael Hakman on 2014-01-16.
//  Copyright (c) 2014 Mikael Hakman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LoginModel;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow * window;

@property (readonly) IBOutlet NSTextField * dsnField;

@property IBOutlet LoginModel * loginModel;

- (IBAction) quitAction : (id) sender;

- (IBAction) loginAction : (id) sender;

@end
