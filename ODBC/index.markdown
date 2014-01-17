#Odbc framework documentation#

Odbc framework is Cocoa framework providing access to ODBC databases. It works on
top of iODBC framework which is a low level C-oriented framework of ODBC routines
that follow ODBC specification. The framework includes also an experimental Cocoa
Core Data Persistent Store for Odbc. It has been tested with IBM DB2, Mimer SQL, 
MySQL, Oracle, PostgreSQL and SQLite.

A database manager that uses optimistic transaction control (e.g. Mimer SQL) is
highly recommeded. If a database manager uses locking transaction control (as the 
majority of database managers on the market) then there a risk of multiple application
locking each other.

ODBC framework consists of a number of classes. Currently only OdbcConnection,
OdbcStatement, and OdbcException are used in non-Core Data applications. 
OdbcStore class and OdbcAppDelegate class are used in Core Data applications. 
The rest is for internal framework use.

In order to use Odbc framework you **don't** need to know ODBC specification. You
**do** need to know some basics of SQL, relational databases and of course Objective-C. 

The documntation consists of:

* This overview page
* Class hierarchy page
* Invidual pages for each class
