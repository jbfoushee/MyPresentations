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


SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[a-f]'


SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[a-em]'


SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[f-a]'


SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[-f]'



--------------------------------------------------------------------
-- The caret ( ^ ) character is the negation character.
-- It provides a "NOT" to all characters on its right.
-- (Must be the FIRST character within the containment 
--  characters to take effect)
--------------------------------------------------------------------

SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '[^4]'


-- This is NOT the same as 
SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] NOT LIKE '[4]'


SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '2[^467]'  -- the caret is the first character


SELECT * FROM dbo.Table_1
WHERE [ArbitraryID] LIKE '2[4^67]'  -- the caret is NOT the first character


SELECT * FROM dbo.Table_1
WHERE [value] LIKE 'a[^a-v]'


