#Odbc framework documentation#

Odbc framework is Cocoa framework providing access to ODBC databases. It works on
top of iODBC framework which is a low level C-oriented framework of ODBC routines
that follow ODBC specification. The framework includes also an experimental Cocoa
Core Data Persistent Store for Odbc.

ODBC framework consists of a number of classes. Currently only OdbcConnection and
OdbcStatement are used in non-Core Data applications. OdbcStore class is used in
Core Data applications. The rest is for internal framework use.

In order to use Odbc framework you **don't** need to know ODBC specification. You
**do** need to know some basics of SQL, relational databases and of course Objective-C. 

The documntation consists of:

* This overview page
* Class hierarchy page
* Invidual pages for each class

This repository contains XCode project with 4 targets:

* Odbc - builds the framework itself
* OdbcDocumentation - generates the documentation
* OdbcExample - builds Cocoa Core Data application using Odbc
* OdbcTests - performs unit tests of the framework

#Example console application#

The following is a simple Cocoa console application that uses Odbc framework.

    // main.m
    
    #import <Cocoa/Cocoa.h>
    
    int main (int argc, char * argv []) {
    
        OdbcConnection * connection = [OdbcConnection new];
        
        [connection connect: @"testdb" user: @"root" password: nil];
        
        OdbcStatement * stmt = [connection newStatment];
        
        [stmt execDirect: @"select * from book order by title"];
        
        while ([stmt fetch]) {
        
            long bookId = [stmt getLongByName: @"bookId"];
            
            NSString * title = [stmt getStringByName: @"title"];
            
            double price = [stmt getDoubleByName: @"price"];
            
            NSLog (@"%ld %@ %f",bookId,title,price);
        }
        
        [stmt closeCursor];
    
        return 0;
    }

In this application we first create an OdbcConnection and then use it to connect to
ODBC data source named 'testdb' with username 'root'. Then we create a new OdbcStatement.
We use this statement to execute SQl query 'select * from book order by title'.
After that we go into a loop fetching a new row each time aroud. We get 'bookId', 
'title' and 'price'. Then we write them to the console. When the loop terminates
we close the statement.

#Prerequisites#

First and foremost you need XCode installed on your Mac. If you don't have it go
to AppStore download and install it. It's free of charge. Test your installation
by writting and running a small application.

Next you need a database manager, either standalone on your Mac, or on accessible
network server. If you don't have you need to download and install it. MySql Community 
Edition is free of charge. Download it and install. You can start/stop it by an
applet in System Preferences. You also need to dowload and install MySqlWorkbench. 
Go ahead and try it out. Create new database (schema) named 'testdb'. Create table
'book' in it. You also need MySql ODBC driver. Download it and install.

Next comes iODBC framework (Odbc framework builds upon iODBC framework). If you
don't have it go to iOdbc site, download and install it. Among other things it will
install 'iOdbc Administrator' application. You use it in a 2-step process. First you register
your ODBC driver - this is done under 'ODBC Driver' tab. Then you register your 
database under either 'User DSN' or 'System DSN' tab.

Test overall installation, perhaps by running the application above.

#Cocoa Core Data example#

The example uses the following Core Data model:

<img src="docs/Images/ExampleCoreDataModel.png" alt="ExampleCoreDataModel.png">



 