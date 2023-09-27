-- Prefix the object with "TYPE::" to work.
-- Note this option is not available in SSMS .
GRANT EXECUTE ON TYPE::dbo.Type_Measurements TO MeasureProc_Executor

-- Why "TYPE::" ? Probably because this item is governed by sys.types
SELECT * FROM sys.types ORDER BY [name]

-- whereas this statement for a proc could be re-written as 
GRANT EXECUTE ON OBJECT::dbo.usp_Measurements_Upsert TO MeasureProc_Executor
-- because this item is governed by sys.objects
SELECT * FROM sys.objects ORDER BY [name]