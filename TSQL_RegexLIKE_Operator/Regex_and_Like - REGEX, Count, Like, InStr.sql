--------------------------------------------------------------------
-- REGEX demo: REGEXP_COUNT, REGEXP_LIKE, REGEXP_INSTR
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


--------------------------------------------------------------------
-- REGEXP_COUNT
--    ( string, RegExPtrn [,startPos = 1 [,flags = 'c']] )

-- Returns the number of times a regular-expression pattern 
-- matches within a string
--------------------------------------------------------------------

-- This is the old way to do this, with REPLACE and LEN

DECLARE @_find varchar(255) = 'in'
DECLARE @_inside varchar(255) = 'interesting'

SELECT @_inside AS original
  , @_find AS [find_this]
  , LEN(@_inside) AS [LEN(original)]
  , REPLACE(@_inside, @_find, '') AS [replaced]
  , LEN(REPLACE(@_inside, @_find, '')) AS [LEN(replaced)]
  , (LEN(@_inside) - LEN(REPLACE(@_inside, @_find, ''))) / LEN(@_find) AS [Count]

-- And the new way.. although literals are boring...

SELECT @_inside AS original
  , @_find AS [find_this]
  , REGEXP_COUNT(@_inside,@_find) AS [Count]

-- So let's introduce some RegEx. Find all the vowels...

SELECT [Name] 
 , REGEXP_COUNT([Name],'[AEIOU]') AS [UpperVowelCount_1]
 , REGEXP_COUNT([Name],'[AEIOU]',1,'c') AS [UpperVowelCount_2]
 , '|' AS '|'
 , REGEXP_COUNT([Name],'[AEIOU]',1,'i')  AS [AnyVowelCount_1] 
 , REGEXP_COUNT([Name],'[AaEeIiOoUu]')   AS [AnyVowelCount_2]
 , REGEXP_COUNT(UPPER([Name]),'[AEIOU]') AS [AnyVowelCount_3]
FROM dbo.Employees


--------------------------------------------------------------------
-- REGEXP_LIKE ( string, RegExPtrn [, flags='c'] )

-- Determines if a string matches a regular expression.
--------------------------------------------------------------------


SELECT ID, Phone_Number
FROM dbo.Employees
WHERE Phone_Number LIKE '456-%'

SELECT ID, Phone_Number 
FROM dbo.Employees 
WHERE REGEXP_LIKE(Phone_Number, '^456-')


SELECT ID, Phone_Number
FROM dbo.Employees
WHERE Phone_Number 
    LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-9012'
  OR Phone_Number 
    LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-0123'

SELECT ID, Phone_Number 
FROM dbo.Employees 
WHERE REGEXP_LIKE(Phone_Number
   , '^\d{3}-\d{3}-(9012|0123)$')



SELECT Phone_Number 
, CASE WHEN 
       REGEXP_LIKE(Phone_Number, '\d{3}-\d{3}-\d{4}') 
      THEN '(Valid)'
    ELSE ''
  END AS isValid   
FROM Employees


ALTER TABLE dbo.Employees
  ADD CONSTRAINT Phone_Validation
     CHECK ( REGEXP_LIKE(Phone_Number, '^\d{3}-\d{3}-\d{4}$') )

UPDATE dbo.Employees
SET Phone_Number = '000-000-0000'
WHERE NOT REGEXP_LIKE(Phone_Number, '\d{3}-\d{3}-\d{4}')

ALTER TABLE dbo.Employees
  ADD CONSTRAINT Phone_Validation
     CHECK ( REGEXP_LIKE(Phone_Number, '^\d{3}-\d{3}-\d{4}$') )


--------------------------------------------------------------------
-- REGEXP_INSTR 
--   (string, RegExPtrn [,startPos = 1 [,occurrence = 1
--     [,return_option = 0 [,flags = 'c']]]] )


-- From the starting position of some string, returns the 
-- starting/ending position (based on return_option), of 
-- the nᵗʰ occurrence of a Regex pattern.
--------------------------------------------------------------------
SELECT Email
  , REGEXP_INSTR(email,'@' , 1, 1, 0) AS [1st_At]
  , REGEXP_INSTR(email,'co', 1, 2, 0) AS [2nd_co_Start]
  , REGEXP_INSTR(email,'co', 1, 2, 1) AS [2nd_co_End]
  , REGEXP_INSTR(email,'\.', 1, 2, 0) AS [2nd_Period]
FROM Employees
