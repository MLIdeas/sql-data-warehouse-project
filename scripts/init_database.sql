/*

Warning

This script will permanently delete the existing DataWarehouse database if it already exists.

That means:

All tables will be deleted.
All data will be lost.
All stored procedures, views, and objects inside that database will be removed.

Only run this script if:

You are okay with deleting and recreating the database from scratch.


Do not run it on a production database or any database containing important data.

*/

USE master;
GO

-- Drop database if it already exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create schemas/layers
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
