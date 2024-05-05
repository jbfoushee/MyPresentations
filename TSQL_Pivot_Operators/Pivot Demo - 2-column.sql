 USE [PivotDemo]

CREATE TABLE [dbo].[2ColPivot]
(
[ID] [varchar](8) NOT NULL,
[Col1] [smallint] NOT NULL
) ON [PRIMARY]

INSERT INTO [dbo].[2ColPivot] (ID, Col1)
VALUES
  ('Circle', 1)
  , ('Triangle', 3)
  , ('Square', 5)
  , ('Circle', 3)
  , ('Square', 2)
  , ('Triangle', 0)
  , ('Triangle', 6)

---------------------------------------------------------------------------------------------

SELECT * FROM [dbo].[2ColPivot]

SELECT DISTINCT [ID] FROM [dbo].[2ColPivot] 

SELECT PivotResults.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot]
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square]) 
                -- ^       ^        ^   the values from the DISTINCT query above
  ) AS PivotResults

--the same statement, but attempting to retreive the RawData dataset
SELECT PivotResults.*, RawData.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot]
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square]) 
  ) AS PivotResults


--the same statement with the FOR [ID] clause re-ordered
SELECT PivotResults.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot]) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Square], [Circle], [Triangle]) -- re-ordered list
  ) AS PivotResults


--the same statement with an explicit order; Intellisense
SELECT PivotResults.Circle
	, PivotResults.Triangle
	, PivotResults.[Square]
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot]
    WHERE ID IN ('Circle', 'Triangle', 'Square')
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square])
  ) AS PivotResults


-- the Square data is requested in the RawData section and pivoted, but not in the SELECT statement
SELECT PivotResults.Circle
	, PivotResults.Triangle
	--, PivotResults.[Square]
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot] 
    WHERE ID IN ('Circle', 'Triangle', 'Square')
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square])
  ) AS PivotResults


-- the Square data is requested in the RawData section, but not pivoted
SELECT PivotResults.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot] 
    WHERE ID IN ('Circle', 'Triangle', 'Square')
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle])	-- but Square is not pivoted
  ) AS PivotResults


-- the RawData is filtered to avoid Square data
SELECT PivotResults.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot] 
    WHERE ID IN ('Circle', 'Triangle') -- 'Square' is removed from RawData
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square])
  ) AS PivotResults




--the same statement with a new unmentioned shape
SELECT PivotResults.*
FROM
  ( SELECT ID, Col1 FROM [dbo].[2ColPivot]
  ) AS RawData
PIVOT
  ( SUM(Col1)
    FOR [ID] IN ([Circle], [Triangle], [Square], [Hexagon] ) -- introduced a new shape
  ) AS PivotResults

--add some data and re-run above statement
INSERT INTO [dbo].[2ColPivot] (ID, Col1) VALUES ('Hexagon', -1) -- new row
