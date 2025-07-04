--------------------------------------------------------------------
-- LIKE demo: wildcards and containment
--------------------------------------------------------------------

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'dbo' 
    AND TABLE_NAME = 'Table_1'
	)
	DROP TABLE dbo.Table_1


CREATE TABLE dbo.Table_1
( ArbitraryID int IDENTITY(1,1) NOT NULL
	, [value] varchar(3)
)

SET NOCOUNT ON
DECLARE @_value0 smallint = NULL
DECLARE @_value1 smallint = NULL
DECLARE @_value2 smallint = NULL

DECLARE @_value1_flag bit = 0
DECLARE @_value0_flag bit = 0

IF NOT EXISTS (SELECT 1 FROM dbo.Table_1)
	BEGIN
		WHILE 1 = 1
			BEGIN
				SET @_value2 = IsNull(@_value2, 96) + 1

				IF @_value2 > 122
					BEGIN
						SET @_value1_flag = 1 
						SET @_value2 = NULL
					END
				ELSE
					BEGIN
						DECLARE @_text varchar(3) = 
							CONCAT(
								CHAR(@_value0), CHAR(@_value1), CHAR(@_value2)
								  )
						PRINT CONCAT(@_value0, ',', @_value1, ',', @_value2)
						INSERT INTO dbo.Table_1([value]) VALUES (@_text)
					END

				IF @_value1_flag = 1
					BEGIN
						SET @_value1 = IsNull(@_value1, 96) +  1
						SET @_value1_flag = 0
					END

				IF @_value1 > 122
					BEGIN
						SET @_value0_flag = 1
						SET @_value1 = 97
						SET @_value2 = NULL
					END

				IF @_value0_flag = 1
					BEGIN
						SET @_value0 = IsNull(@_value0, 96) + 1
						SET @_value0_flag = 0
					END

				IF @_value0 > 122
					BREAK

			END

		INSERT INTO [dbo].[Table_1] ([value]) VALUES(','), ('%'), ('_'), ('^'), ('-')

	END

SELECT * FROM dbo.Table_1

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '%'

--------------------------------------------------------------------
-- The underscore ( _ ) character is a wildcard of 
-- one character
--------------------------------------------------------------------

-- Return anything with exactly only/one character
SELECT TOP 4 * 
FROM dbo.Table_1
WHERE [value] LIKE '_'
ORDER BY NEWID() -- randomizer


-- Return anything with exactly only/two characters
SELECT TOP 4 * 
FROM dbo.Table_1
WHERE [value] LIKE '__'
ORDER BY NEWID() -- randomizer


-- Return anything with at least two characters
SELECT TOP 4 * 
FROM dbo.Table_1
WHERE [value] LIKE '__%'  -- guarantees 
ORDER BY NEWID() -- randomizer



--------------------------------------------------------------------
-- Brackets ( [] ) are an array of allowable characters
-- representing one position
--------------------------------------------------------------------

--By themselves, they do nothing

DECLARE @_value varchar(20) = ''
IF @_value LIKE '[]'
   PRINT 'yes, `` LIKE []'
ELSE 
   PRINT 'no, `` NOT LIKE []'

-- An 'ablaut' is a change of vowel in related words or 
-- forms.
-- Here we are selecting one such where the first letter 
-- is 'm' and the last is 'd'

SELECT * FROM dbo.Table_1
WHERE [value] LIKE 'm[aeiou]d'

-- The % character loses its special wildcard ability 
-- within the containment characters

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[%]'


-- We can use multiple sets of containment characters...

SELECT * FROM dbo.Table_1
WHERE ArbitraryID LIKE '%[2%]9[86][90]'


SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[[ab][cd]][f]'
--No results? What happened?


-- Brackets also lose their special containment character
-- ability within containment characters.


-- [[ab][cd]][f]
-- 12  34  567 8

-- Bracket 1 started a new containment
-- Bracket 2 is just a literal and did not start a new containment
-- Bracket 3 ended the containment started at 1
-- Bracket 4 started a new containment
-- Bracket 5 ended the containment started at 4
-- Bracket 6 is just a literal with no matching containment
-- Bracket 7 started a new containtment
-- Bracket 8 ended the containment started at 7


-- So if the table contained these values, it would have 
-- returned them:
SELECT *
FROM ( 
	VALUES ('[c]f')
	     , ('ac]f')
	     , ('bc]f')
	     , ('[d]f')
	     , ('ad]f')
	     , ('bd]f')
   ) t([value])
WHERE [value] LIKE '[[ab][cd]][f]'