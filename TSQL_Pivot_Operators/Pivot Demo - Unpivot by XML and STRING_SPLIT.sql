DECLARE @_MyString varchar(20) = '1 2 3 4 5'

DECLARE @_MyString_XML XML
 = CAST(
   '<root><item>' 
   + Replace(@_MyString, ' ', '</item><item>') 
   + '</item></root>' 
  AS XML)

SELECT t.value('.', 'varchar(max)') AS MyStrings
FROM @_MyString_XML.nodes('//root/item') AS a(t)

---------------------------------------------------

DECLARE @_MyString varchar(20) = '1,2,3,4,5'

DECLARE @_MyString_XML XML
 = CAST(
   '<root><item>' 
   + Replace(@_MyString, ',', '</item><item>') 
   + '</item></root>' 
  AS XML)

SELECT t.value('.', 'varchar(max)') AS MyStrings
FROM @_MyString_XML.nodes('//root/item') AS a(t)

---------------------------------------------------

DECLARE @_MyString varchar(20) = '1 2 3 4 5'

-- STRING_SPLIT() requires SQL 2016
SELECT value AS [blah] 
FROM STRING_SPLIT (@_MyString, ' ')

---------------------------------------------------

DECLARE @_MyList varchar(20) = '1,2,3,4,5'
SELECT @_MyList AS ListCol INTO #temp

SELECT t.ListCol, l.[value] AS [blah]
FROM #temp t
  CROSS APPLY STRING_SPLIT(t.ListCol, ',') l
