DECLARE @MyString varchar(20) = '1 2 3 4 5'

DECLARE @MyString_XML XML
 = CAST(
   '<root><item>' 
   + Replace(@MyString, ' ', '</item><item>') 
   + '</item></root>' 
  AS XML)

SELECT t.value('.', 'varchar(max)') AS MyStrings
FROM @MyString_XML.nodes('//root/item') AS a(t)

---------------------------------------------------

DECLARE @MyString varchar(20) = '1,2,3,4,5'

DECLARE @MyString_XML XML
 = CAST(
   '<root><item>' 
   + Replace(@MyString, ',', '</item><item>') 
   + '</item></root>' 
  AS XML)

SELECT t.value('.', 'varchar(max)') AS MyStrings
FROM @MyString_XML.nodes('//root/item') AS a(t)

---------------------------------------------------

DECLARE @MyString varchar(20) = '1 2 3 4 5'

-- STRING_SPLIT() requires SQL 2016
SELECT value AS [blah] 
FROM STRING_SPLIT (@MyString, ' ')
