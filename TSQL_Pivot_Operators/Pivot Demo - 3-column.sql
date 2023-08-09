USE [PivotDemo]

CREATE TABLE [dbo].[3ColPivot]
(
[StoreID] [smallint] NOT NULL,
[Quarter] [smallint] NOT NULL,
[Year] [smallint] NOT NULL,
[Sales] [money] NULL,
[DataEnteredBy] [varchar](6) NULL
) ON [PRIMARY]

INSERT INTO [dbo].[3ColPivot] (StoreID, [Quarter], [Year], Sales, [DataEnteredBy])
VALUES (1, 1, 2011, 10000, 'Mary')
, (1, 2, 2011, 15000, 'Chris')
, (1, 3, 2011, 17500, 'Mary')
, (1, 4, 2011, 18000, 'Mary')
, (1, 1, 2012, 22000, 'Chris')
, (1, 2, 2012, 35000, 'Bob')
, (1, 3, 2012, 40000, 'Chris')
, (1, 4, 2012, 60000, 'Mary')

, (1, 1, 2013, 38000, 'Mary')
, (1, 2, 2013, 32000, 'Chris')
, (1, 3, 2013, 45000, 'Bob')
, (1, 4, 2013, 50000, 'Chris')

, (2, 1, 2012, 20000, 'Kim')
, (2, 2, 2012, 15000, 'Kim')
, (2, 3, 2012, 30000, 'Kim')
, (2, 4, 2012, 8000, 'Lee')
, (2, 1, 2013, -3000, NULL)

, (3, 2, 2013, 50000, 'Jerry')
, (3, 3, 2013, 30000, 'Jerry')
, (3, 4, 2013, 50000, 'Bill')

---------------------------------------------------------------------------------------------

SELECT * FROM [dbo].[3ColPivot]

-----------------------------------------------
--pivot the sales by year by store
-----------------------------------------------
SELECT PivotResults.* 
FROM
 ( SELECT StoreID, [Year], Sales
   FROM [dbo].[3ColPivot]
 ) AS RawData
PIVOT
 ( SUM(Sales) FOR [YEAR] IN ([2011], [2012], [2013]) 
)
 AS PivotResults

 ----------------------------------------------------------
 --pivot the sales by year by store, add a "GrandTotal" row
 ----------------------------------------------------------
 SELECT PivotResults.* 
FROM
 ( SELECT Convert(varchar,StoreID) AS StoreID, [Year], Sales
   FROM [dbo].[3ColPivot]
 ) AS RawData
PIVOT
 ( SUM(Sales)  FOR [YEAR] IN ([2011], [2012], [2013]) 
)
 AS PivotResults
 UNION
SELECT 'ALL' AS StoreID, PivotResults.* 
FROM
 ( SELECT [Year], Sales --StoreID is missing from this predicate
   FROM [dbo].[3ColPivot]
 ) AS RawData
PIVOT
 ( SUM(Sales)  FOR [YEAR] IN ([2011], [2012], [2013]) 
)
 AS PivotResults

-----------------------------------------------
--pivot the sales by quarter
-----------------------------------------------
SELECT PivotResults.*
FROM 
( SELECT StoreID
  , CONVERT(char(4), [Year]) + ' Q' + CONVERT(char(2), [Quarter]) AS Quarter_Text
  , Sales
  FROM [dbo].[3ColPivot]
) AS RawData
PIVOT
 ( SUM(Sales)  FOR [Quarter_Text] 
     IN ([2011 Q1], [2011 Q2], [2011 Q3], [2011 Q4],
         [2012 Q1], [2012 Q2], [2012 Q3], [2012 Q4],
         [2013 Q1], [2013 Q2], [2013 Q3], [2013 Q4]
   ) 
 ) AS PivotResults

------------------------------------------
--- A 4-column pivot?
------------------------------------------

-- Be careful adding unnecessary data, one additional column can change results

SELECT PivotResults.*
FROM 
( SELECT StoreID
  , CONVERT(char(4), [Year]) + ' Q' + CONVERT(char(2), [Quarter]) AS Quarter_Text
  , Sales
  , [DataEnteredBy]  --by adding this column, the result pivot becomes almost unreadable
  FROM [dbo].[3ColPivot]
) AS RawData
PIVOT
 ( SUM(Sales)  FOR [Quarter_Text] 
     IN ([2011 Q1], [2011 Q2], [2011 Q3], [2011 Q4],
         [2012 Q1], [2012 Q2], [2012 Q3], [2012 Q4],
         [2013 Q1], [2013 Q2], [2013 Q3], [2013 Q4]
   )
 ) AS PivotResults

