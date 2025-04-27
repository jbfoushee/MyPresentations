--------------------------------------------------------------------
-- LIKE demo: range and negation
--------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'dbo' 
    AND TABLE_NAME = 'Table_1'
    )  
	RAISERROR('Wait! Demo table not built yet!', 20, 1) WITH LOG;


SET NOCOUNT ON
--------------------------------------------------------------------
-- The dash ( - ) character is a range of characters from its
-- immediate left to its immediate right
-- Characters must be contiguous; Lower value must be on the left
--------------------------------------------------------------------

SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '[1-2][5-7]'

--     1  →  5      2  →  5
--     |\           |\
--     | \          | \
--     |  →  6      |  →  6
--     |\           |\
--       \            \
--        →  7         →  7


SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '[1-46]8'

--    1     2     3     4     6
--    |     |     |     |     |
--    |     |     |     |     |
--    v     v     v     v     v
--    8     8     8     8     8


-- A proper alphabetic range
SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[a-f]'


-- A proper range and a bonus character
SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[a-em]'


-- You get nothing! (incorrect alphabetical order)
SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[f-a]'


-- Dash becomes a literal
SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[-f]'


--------------------------------------------------------------------
-- The caret ( ^ ) character is the negation character.
-- It provides a "NOT" to all characters on its right.
-- (Must be the FIRST character within the containment 
--  characters to take effect)
--------------------------------------------------------------------

-- One character, but NOT "4"
SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '[^4]'


-- This is NOT the same as " NOT LIKE '[4]' "

-- Everything, but NOT the entry "4"
SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] NOT LIKE '[4]'


-- a two-digit number; First digit 2, the second NOT a 4, 6, or 7
SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '2[^467]'  -- the caret is the first character


-- a two-digit number; First digit 2, the second can be a 4, ^, 6, or 7
SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '2[4^67]'  -- the caret is NOT the first character


-- a two-character word; First character "a", second character NOT a thru v
SELECT * FROM dbo.Table_1
WHERE [value] LIKE 'a[^a-v]'
