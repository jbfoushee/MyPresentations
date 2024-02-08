USE [PivotDemo]

CREATE TABLE [dbo].[3ColPivot]
(
[StoreID] [smallint] NOT NULL,
[Quarter] [smallint] NOT NULL,
[Year] [char](4) NOT NULL,
[Sales] [money] NULL,
[DataEnteredBy] [varchar](6) NULL
) ON [PRIMARY]

INSERT INTO [dbo].[3ColPivot] (StoreID, [Quarter], [Year], Sales, [DataEnteredBy])
VALUES (1, 1, '20XX', 10000, 'Mary')
, (1, 2, '20XX', 15000, 'Chris')
, (1, 3, '20XX', 17500, 'Mary')
, (1, 4, '20XX', 18000, 'Mary')
, (1, 1, '20XY', 22000, 'Chris')
, (1, 2, '20XY', 35000, 'Bob')
, (1, 3, '20XY', 40000, 'Chris')
, (1, 4, '20XY', 60000, 'Mary')

, (1, 1, '20XZ', 38000, 'Mary')
, (1, 2, '20XZ', 32000, 'Chris')
, (1, 3, '20XZ', 45000, 'Bob')
, (1, 4, '20XZ', 50000, 'Chris')

, (2, 1, '20XY', 20000, 'Kim')
, (2, 2, '20XY', 15000, 'Kim')
, (2, 3, '20XY', 30000, 'Kim')
, (2, 4, '20XY', 8000, 'Lee')
, (2, 1, '20XZ', -3000, NULL)

, (3, 2, '20XZ', 50000, 'Jerry')
, (3, 3, '20XZ', 30000, 'Jerry')
, (3, 4, '20XZ', 50000, 'Bill')

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
 ( SUM(Sales) FOR [YEAR] IN ([20XX], [20XY], [20XZ]) 
)
 AS PivotResults

 ----------------------------------------------------------
 --pivot the sales by year by store, add a "GrandTotal" row
 ----------------------------------------------------------
  SELECT PivotResults.* 
  FROM
  (  SELECT Convert(varchar,StoreID) AS StoreID, [Year], Sales
     FROM [dbo].[3ColPivot]
  ) AS RawData
  PIVOT
  ( SUM(Sales)  
    FOR [YEAR] IN ([20XX], [20XY], [20XZ]) 
  ) AS PivotResults
UNION ALL
  SELECT 'ALL' AS StoreID, PivotResults.* 
  FROM
  ( SELECT [Year], Sales --StoreID is missing from this predicate
    FROM [dbo].[3ColPivot]
  ) AS RawData
  PIVOT
  ( SUM(Sales)  
    FOR [YEAR] IN ([20XX], [20XY], [20XZ])
  ) AS PivotResults

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
 ( SUM(Sales)  
   FOR [Quarter_Text] 
     IN ([20XX Q1], [20XX Q2], [20XX Q3], [20XX Q4],
         [20XY Q1], [20XY Q2], [20XY Q3], [20XY Q4],
         [20XZ Q1], [20XZ Q2], [20XZ Q3], [20XZ Q4]
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
( SUM(Sales)  
   FOR [Quarter_Text] 
     IN ([20XX Q1], [20XX Q2], [20XX Q3], [20XX Q4],
         [20XY Q1], [20XY Q2], [20XY Q3], [20XY Q4],
         [20XZ Q1], [20XZ Q2], [20XZ Q3], [20XZ Q4]
   )
 ) AS PivotResults

