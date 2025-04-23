--------------------------------------------------------------------
-- REGEX demo: REGEXP_REPLACE, REGEXP_SUBSTR
--------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.objects
                WHERE object_id = OBJECT_ID(N'[dbo].[Employees]')
                AND type IN (N'U'))
	BEGIN
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
    END

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            WHERE TABLE_SCHEMA = 'dbo'
                AND TABLE_NAME = 'Employees'
                AND CONSTRAINT_TYPE = 'CHECK'
                AND CONSTRAINT_NAME = 'Phone_Validation')
    BEGIN
        ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [Phone_Validation]

        UPDATE dbo.Employees 
        SET Phone_Number = '567-890-124'
        WHERE [Name] = 'Charlie Brown'
    END



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
  , REGEXP_SUBSTR(email, '@.+$'  , 1, 1, 'c', 0) AS Suffix_Ver1
  , REGEXP_SUBSTR(email, '@(.+)$', 1, 1, 'c', 0) AS Suffix_Ver2
  , REGEXP_SUBSTR(email, '@(.+)$', 1, 1, 'c', 1) AS Domain
FROM Employees

