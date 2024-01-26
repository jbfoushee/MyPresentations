-----------------------------------------
-- Slide 8
-----------------------------------------

DECLARE @_beforemap varchar(12) = '[]{}ñé“”‘’'
DECLARE @_aftermap  varchar(12) = '()()ne""'''''

SELECT TRANSLATE('“héllo{}”', @_beforemap, @_aftermap)
SELECT TRANSLATE(
     '“héllo{}”', '[]{}ñé“”‘’', '()()ne""''''')

-----------------------------------------
-- Slide 10
-----------------------------------------

DECLARE @_beforemap varchar(100) 
   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
DECLARE @_aftermap varchar(100)  
   = 'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm'

SELECT TRANSLATE(
	'Hello' COLLATE Latin1_General_CS_AS
   , @_beforemap, @_aftermap) AS [Value]

SELECT TRANSLATE(
   'Hello'
   , @_beforemap, @_aftermap) AS [Value]

-----------------------------------------
-- Slide 17
-----------------------------------------

DECLARE @_cr char(1) = CHAR(13)
DECLARE @_lf char(1) = CHAR(10)
DECLARE @_tab char(1) = CHAR(9)

DECLARE @_value varchar(10) 
    = 'hello' + @_cr + @_lf + @_tab + '!'

DECLARE @_beforemap char(3) = CONCAT(@_cr, @_lf, @_tab)
DECLARE @_aftermap  char(3) = '---'

PRINT @_value
PRINT TRANSLATE(@_value, @_beforemap, @_aftermap) 

-----------------------------------------
-- Slide 18
-----------------------------------------

DECLARE @_cr char(1) = CHAR(13)
DECLARE @_lf char(1) = CHAR(10)
DECLARE @_tab char(1) = CHAR(9)
DECLARE @_bksp char(1) = CHAR(0)

DECLARE @_value varchar(10) 
    = 'hello' + @_cr + @_lf + @_tab + '!'

DECLARE @_beforemap char(3) = CONCAT(@_cr, @_lf, @_tab)
DECLARE @_aftermap  char(3) = CONCAT(@_bksp, @_bksp, @_bksp)

PRINT @_value
PRINT TRANSLATE(@_value, @_beforemap, @_aftermap) 
-- Wait, did that truly work? Take the results from SSMS and paste
-- into Notepad. What happens? What happens if you use the Delete
-- character (CHAR 127) or the NULL character (CHAR 0) ? Compare.

-----------------------------------------
-- Slide 20
-----------------------------------------

DECLARE @_cr char(1) = CHAR(13)
DECLARE @_lf char(1) = CHAR(10)
DECLARE @_tab char(1) = CHAR(9)

DECLARE @_value varchar(10) 
    = 'hello' + @_cr + @_lf + @_tab + '!'

DECLARE @_beforemap char(3) = CONCAT(@_cr, @_lf, @_tab)
DECLARE @_aftermap  char(3) = '•••'

PRINT @_value
PRINT REPLACE(
        TRANSLATE(@_value, @_beforemap, @_aftermap), '•', '')

-----------------------------------------
-- Slide 21
-----------------------------------------

DECLARE @_myint int = 123
DECLARE @_mytext varchar(8) = 'hello'

SELECT @_myint AS MyInt
  , TRANSLATE(@_myint, '3', '6') 
       AS MyNewInt
  , @_mytext AS MyText
  , TRANSLATE(@_mytext, 'E', 'A') 
       AS MyNewText
INTO dbo.Table1

SELECT ssc.name AS ColumnName, st.name AS DataType, ssc.length
FROM sys.syscolumns ssc
  INNER JOIN sys.types st
      ON ssc.xtype = st.system_type_id
WHERE id = OBJECT_ID('Table1')

--DROP TABLE dbo.Table1

-----------------------------------------
-- Slide 22
-----------------------------------------

DECLARE @_myint int = 123
DECLARE @_mytext varchar(8) = 'hello'

SELECT @_myint AS MyInt
  , TRY_CONVERT(int, TRANSLATE(@_myint, '3', '6'))  
       AS MyNewInt
  , @_mytext AS MyText
  , CONVERT(varchar(8),
        TRANSLATE(@_mytext, 'E', 'A'))
       AS MyNewText
INTO dbo.Table1

SELECT ssc.name AS ColumnName, st.name AS DataType, ssc.length
FROM sys.syscolumns ssc
  INNER JOIN sys.types st
      ON ssc.xtype = st.system_type_id
WHERE id = OBJECT_ID('Table1')

--DROP TABLE dbo.Table1