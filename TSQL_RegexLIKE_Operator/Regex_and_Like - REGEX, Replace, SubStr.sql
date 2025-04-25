--------------------------------------------------------------------
-- REGEX demo: REGEXP_REPLACE, REGEXP_SUBSTR
--------------------------------------------------------------------

-- Setup:

IF EXISTS (SELECT 1
            FROM sys.databases 
            WHERE name = DB_NAME()
              AND compatibility_level < 170)
    BEGIN
        DECLARE @_ErrMessage varchar(8000) = 
           CONCAT('Compatibility level too low for expected results.', CHAR(13), CHAR(13)
                   , 'Run "ALTER DATABASE [', DB_NAME(), '] SET COMPATIBILITY_LEVEL = 170;')
        RAISERROR(@_ErrMessage, 16, 1)
    END


IF EXISTS (SELECT 1 FROM sys.objects
           WHERE object_id = OBJECT_ID(N'[dbo].[Employees]')
             AND type IN (N'U'))
    DROP TABLE dbo.Employees

CREATE TABLE dbo.Employees (
    ID INT IDENTITY(101,1),
    [Name] VARCHAR(150),
    Email VARCHAR(320),
    Phone_Number VARCHAR(20)
);

INSERT INTO dbo.Employees ([Name], Email, Phone_Number) 
VALUES ('John Doe', 'john@contoso.com', '123-456-7890')
    , ('Alice Smith', 'alice@fabrikam.com', '234-567-8901')
    , ('Bob Johnson', 'bob@fabrikam.net','345-678-9012')
    , ('Eve Jones', 'eve@contoso.com', '456-789-0123')
    , ('Charlie Brown', 'charlie@contoso.co.in', '567-890-124');

-- Hint: Go to Edit, Intellisense, Refresh Local Cache



--------------------------------------------------------------------
-- REGEXP_REPLACE 
--    ( string, RegExPtrn, withPattern
--        [, startPos = 1 [, occurrence = 0 [, flags = 'c']]] )

-- Returns an in-string replacement of one regular expression 
-- pattern, with another regular expression pattern.
--------------------------------------------------------------------

SELECT Phone_Number  
   , REGEXP_REPLACE
        ( Phone_Number, '\d{3}-\d{3}-\d{4}' , 'Valid. Trust me, bro' ) 
      AS isValid
FROM Employees


-- Same query, but with sub-expressions walled-off... and unused
SELECT Phone_Number  
   , REGEXP_REPLACE
        ( Phone_Number, '(\d{3})-(\d{3})-(\d{4})' , 'Valid. Trust me, bro' ) 
      AS isValid
FROM Employees


SELECT Phone_Number  
   , REGEXP_REPLACE
        ( Phone_Number, '(\d{3})-(\d{3})-(\d{4})' , '(\1) \2-\3' ) 
      AS Pretty_Format
FROM Employees

SELECT Phone_Number  
   , REGEXP_REPLACE
        ( Phone_Number, '(\d{3})-(\d{3})-(\d{4})' , '(XXX) XXX-\3' ) 
      AS DataMask
FROM Employees

--------------------------------------------------------------------
-- REGEXP_SUBSTR 
--    (string, RegExPtrn [,startPos = 1 [,occurrence = 1
--       [,flags = 'c' [,whichSubExp = 0]]]] )

-- Extracts a substring -- matching a regular expression 
--  pattern -- found within a string
--------------------------------------------------------------------


SELECT Email
    , RIGHT(email, LEN(email) - CHARINDEX('@', email)) 
            AS [Domain_w/RIGHT_&_LEN_&_CHARINDEX]

    , REGEXP_SUBSTR(email, '@(.+)$', 1, 1, 'c', 1) 
            AS [Domain_w/REGEXP_SUBSTR]
FROM Employees


DECLARE @_text VARCHAR(500) 
  = '1: 2023-08-01, 2: 2024-09-01, 3: 10/01/2025';
--      YYYY-MM-DD     YYYY-MM-DD     MM/DD/YYYY
--                                      ^ Hold my beer

SELECT 
  REGEXP_SUBSTR(@_text, '1: ([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, 'i', 1) AS Month1
, REGEXP_SUBSTR(@_text, '2: ([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, 'i', 1) AS Month2
, REGEXP_SUBSTR(@_text, '3: ([0-9]{2})/([0-9]{2})/([0-9]{4})', 1, 1, 'i', 3) AS Month3
