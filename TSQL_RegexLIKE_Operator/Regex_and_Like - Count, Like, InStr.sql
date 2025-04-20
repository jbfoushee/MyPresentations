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



-- REGEXP_COUNT

SELECT [Name] 
 , REGEXP_COUNT([Name],'[AEIOU]',1,'sc') AS [COUNT(Name.Vowels[].Upper)]
 , '|' AS '|'
 , REGEXP_COUNT([Name],'[AEIOU]',1,'i')  AS [COUNT(Name.Vowels[])] 
 , REGEXP_COUNT([Name],'[AaEeIiOoUu]')   AS [COUNT(Name.Vowels[])]
 , REGEXP_COUNT(UPPER([Name]),'[AEIOU]') AS [COUNT(Name.Vowels[])]
FROM dbo.Employees

-- REGEXP_LIKE
SELECT ID, Phone_Number 
FROM dbo.Employees 
WHERE REGEXP_LIKE(Phone_Number, '^456-')


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

-- REGEXP_INSTR

SELECT Email
  , REGEXP_INSTR(email,'@' , 1, 1, 0) AS [1st_At]
  , REGEXP_INSTR(email,'co', 1, 2, 0) AS [2nd_co_Start]
  , REGEXP_INSTR(email,'co', 1, 2, 1) AS [2nd_co_End]
FROM Employees
