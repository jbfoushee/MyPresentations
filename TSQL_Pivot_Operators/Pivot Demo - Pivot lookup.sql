-- Let's duplicate our 2-Column pivot table and
-- add a lookup column...

CREATE TABLE #Lookup
(
	[ID] [varchar](8) NOT NULL,
	[Col1] [smallint] NOT NULL,
	[Col2] char(1) NOT NULL
) ON [PRIMARY]

INSERT INTO #Lookup (ID, Col1, Col2)
VALUES
  ('Circle', 1, 'a')
  , ('Triangle', 3, 'b')
  , ('Square', 5, 'c')
  , ('Circle', 3, 'd')
  , ('Square', 2, 'e')
  , ('Triangle', 0, 'f')
  , ('Triangle', 6, 'g')

--------------------------------------------------------------------------

SELECT * FROM #Lookup

--------------------------------------------------------------------------
-- Our RawData potion has been modified to acquire the lookup (Col2)
-- after getting the MAX(Col1) per ID
-- We turn it into a caption to shove it into one cell before pivoting

SELECT PivotResults.*
FROM (
  SELECT orig.ID
   , CONCAT(orig.Col1, ':', orig.Col2)
        AS Caption
  FROM #Lookup orig
    INNER JOIN
     ( SELECT ID, MAX(Col1) AS Col1
       FROM #Lookup
       GROUP BY ID
     ) maxes
    ON orig.ID = maxes.ID
    AND orig.Col1 = maxes.Col1
) AS RawData  
PIVOT (
  MAX(Caption) 
  FOR [ID] 
    IN ([Circle],[Triangle],[Square])
) AS PivotResults

--------------------------------------------------------------------------
-- What happens if all the MAX values are the same?
-- In other words, more than one lookup is relevant?
-- (ie. 2 or more basketball players were MVPs for a team during a game)

UPDATE #Lookup
SET Col1 = 6
WHERE ID = 'Triangle'

SELECT * 
FROM #Lookup
WHERE ID = 'Triangle'

--------------------------------------------------------------------------

SELECT PivotResults.*
FROM (
  SELECT orig.ID
   , CONCAT(orig.Col1, ':', orig.Col2)
        AS Caption
  FROM #Lookup orig
    INNER JOIN
     ( SELECT ID, MAX(Col1) AS Col1
       FROM #Lookup
       GROUP BY ID
     ) maxes
    ON orig.ID = maxes.ID
    AND orig.Col1 = maxes.Col1
) AS RawData  
PIVOT (
  MAX(Caption) 
  FOR [ID] 
    IN ([Circle],[Triangle],[Square])
) AS PivotResults

-- The PIVOT only chooses the MAX caption alphabetically

--------------------------------------------------------------------------

SELECT * FROM #Lookup

--------------------------------------------------------------------------
-- Let's use the STRING_AGG function to 'PIVOT' the caption data
-- (as we learned in the alternate ways to PIVOT)
-- before we PIVOT the ID
-- Let's take a look at the RawData portion now...

  SELECT orig.ID
	, STRING_AGG( CONCAT(orig.Col1, ':', orig.Col2) , ',') AS Caption
  FROM #Lookup orig
    INNER JOIN
     ( SELECT ID, MAX(Col1) AS Col1
       FROM #Lookup
       GROUP BY ID
     ) maxes
    ON orig.ID = maxes.ID
    AND orig.Col1 = maxes.Col1
  GROUP BY orig.ID

--------------------------------------------------------------------------
-- And put it all together.... now we have a dataframe inside a table cell
--------------------------------------------------------------------------

SELECT PivotResults.*
FROM (
  SELECT orig.ID
	, STRING_AGG(CONCAT(orig.Col1, ':', orig.Col2), ',') AS Caption
  FROM #Lookup orig
    INNER JOIN
     ( SELECT ID, MAX(Col1) AS Col1
       FROM #Lookup
       GROUP BY ID
     ) maxes
    ON orig.ID = maxes.ID
    AND orig.Col1 = maxes.Col1
  GROUP BY orig.ID
) AS RawData  
PIVOT (
  MAX(Caption) 
  FOR [ID] 
    IN ([Circle],[Triangle],[Square])
) AS PivotResults
