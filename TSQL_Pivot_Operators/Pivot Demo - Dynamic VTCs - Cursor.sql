SELECT DISTINCT [Year] FROM dbo.[3ColPivot]
----------------------------------------------------

DECLARE @_VTCNames varchar(MAX); SET @_VTCNames = ''

DECLARE Cursor_VTCNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT DISTINCT [Year]  FROM dbo.[3ColPivot] ORDER BY [Year]

DECLARE @_variable varchar(50)
DECLARE @_rowcount integer; SET @_rowcount = 0

OPEN Cursor_VTCNames

FETCH NEXT FROM Cursor_VTCNames INTO @_variable

WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @_rowcount = @_rowcount + 1
    IF @_rowcount > 1 SET @_VTCNames = @_VTCNames + ','
    SET @_VTCNames = @_VTCNames + '[' + @_variable + ']'
    FETCH NEXT FROM Cursor_VTCNames INTO @_variable 
  END

CLOSE Cursor_VTCNames; DEALLOCATE Cursor_VTCNames

PRINT @_VTCNames

-- Could I use this variable in the PIVOT clause?

SELECT PivotResults.*
FROM (
     SELECT StoreID, [Year], Sales 
     FROM [dbo].[3ColPivot] 
) AS RawData
PIVOT (
  SUM(Sales)
  FOR [Year]
  IN ( @_VTCNames )
 ) AS PivotResults
ORDER BY 1 ASC;

-- No, because the IN-clause does not accept variables

----------------------------------------------------

DECLARE @_VTCNames varchar(MAX); SET @_VTCNames = ''

DECLARE Cursor_VTCNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT DISTINCT [Year] FROM dbo.[3ColPivot] ORDER BY [Year]

DECLARE @_variable varchar(50)
DECLARE @_rowcount integer; SET @_rowcount = 0

OPEN Cursor_VTCNames

FETCH NEXT FROM Cursor_VTCNames INTO @_variable

WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @_rowcount = @_rowcount + 1
    IF @_rowcount > 1 SET @_VTCNames = @_VTCNames + ','
    SET @_VTCNames = @_VTCNames + '[' + @_variable + ']'
    FETCH NEXT FROM Cursor_VTCNames INTO @_variable 
  END

CLOSE Cursor_VTCNames; DEALLOCATE Cursor_VTCNames

DECLARE @_Stmt varchar(MAX); SET @_Stmt = ''

SET @_Stmt = @_Stmt + ' SELECT PivotResults.* '				 + CHAR(13)
SET @_Stmt = @_Stmt + ' FROM ( '							 + CHAR(13)
SET @_Stmt = @_Stmt + '      SELECT StoreID, [Year], Sales ' + CHAR(13)
SET @_Stmt = @_Stmt + '      FROM [dbo].[3ColPivot] '		 + CHAR(13)
SET @_Stmt = @_Stmt + ' ) AS RawData '						 + CHAR(13)
SET @_Stmt = @_Stmt + ' PIVOT ( '							 + CHAR(13)
SET @_Stmt = @_Stmt + '   SUM(Sales) '						 + CHAR(13)
SET @_Stmt = @_Stmt + '   FOR [Year] '						 + CHAR(13)
SET @_Stmt = @_Stmt + '   IN (' + @_VTCNames + ')'			 + CHAR(13)
SET @_Stmt = @_Stmt + '  ) AS PivotResults'					 + CHAR(13)
SET @_Stmt = @_Stmt + ' ORDER BY 1 ASC; '					 + CHAR(13)

PRINT @_Stmt

EXEC(@_Stmt)
