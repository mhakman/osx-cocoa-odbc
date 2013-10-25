//
//  main.c
//  TestConnect
//
//  Created by Mikael Hakman on 2013-10-25.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

#import <sql.h>

#import "OdbcException.h"

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

int main (int argc, const char * argv []) {
    
    char dsn [256] = "";
    
    char user [256] = "";
    
    char pwd [256] = "";
    
    if (argc < 2) {
        
        fprintf (stderr,"Data source:");
        
        fgets (dsn,sizeof(dsn),stdin);
        
        if (dsn[strlen(dsn) - 1] == '\n') dsn[strlen(dsn) - 1] = 0;
        
    } else {
        
        strcpy (dsn,argv[1]);
    }
    
    if (argc < 3) {
        
        fprintf (stderr,"Username:");
        
        fgets (user,sizeof(user),stdin);
        
        if (user[strlen(user) - 1] == '\n') user[strlen(user) - 1] = 0;
        
    } else {
        
        strcpy (user,argv[2]);
    }
    
    if (argc < 4) {
        
        fprintf (stderr,"Password:");
        
        fgets (pwd,sizeof(pwd),stdin);
        
        if (pwd[strlen(pwd) - 1] == '\n') pwd[strlen(pwd) - 1] = 0;
        
    } else {
        
        strcpy (pwd,argv[3]);
    }
    
    SQLRETURN rc;
    
    SQLHANDLE env = 0;
    
    SQLHANDLE conn = 0;
    
    @try {
    
        rc = SQLAllocHandle (SQL_HANDLE_ENV,0,&env);
        
        CHECK_ERROR ("SQLAllocHandle1",rc,SQL_HANDLE_ENV,env);
        
        rc = SQLSetEnvAttr (env,SQL_ATTR_ODBC_VERSION,(SQLPOINTER)SQL_OV_ODBC3,0);
        
        CHECK_ERROR ("SQLSetEnvAttr",rc,SQL_HANDLE_ENV,env);
        
        rc = SQLAllocHandle (SQL_HANDLE_DBC,env,&conn);
        
        CHECK_ERROR ("SQLAllocHandle2",rc,SQL_HANDLE_ENV,env);
        
        rc = SQLConnect(conn,(SQLCHAR *)dsn,SQL_NTS,(SQLCHAR *)user,SQL_NTS,(SQLCHAR *)pwd,SQL_NTS);
        
        CHECK_ERROR ("SQLConnect",rc,SQL_HANDLE_DBC,conn);
        
        rc = SQLDisconnect (conn);

        CHECK_ERROR ("SQLDisconnect",rc,SQL_HANDLE_DBC,conn);
        
        fprintf (stderr,"Connection was successful\n");
        
    } @catch (NSException * exception) {
        
        NSString * description = exception.description;
        
        const char * desc = description.UTF8String;
        
        fprintf (stderr,"%s\n",desc);
        
    }

    return 0;
}

