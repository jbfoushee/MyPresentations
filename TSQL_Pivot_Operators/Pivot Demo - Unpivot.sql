USE [PivotDemo]

CREATE TABLE [dbo].[Unpivot]
(
[ID] [varchar](6) NOT NULL,
[Col1] [tinyint] NOT NULL,
[Col2] [tinyint] NULL,
[Col3] [tinyint] NULL,
[Col4] [char](1) NOT NULL
) ON [PRIMARY]

INSERT INTO dbo.[Unpivot] 
   (ID, Col1, Col2, Col3, Col4)
VALUES ('Blue', 1, 2, 3, 'F')
    , ('Green', 5, 6, 7, 'M')

---------------------------------------------------------------------------------------------

SELECT * FROM dbo.[Unpivot]

SELECT UnpivotResults.*
FROM (
  SELECT ID
    , Convert(char(3),Col1) AS Col1
    , Convert(char(3),Col2) AS Col2
    , Convert(char(3),Col3) AS Col3
    , Convert(char(3),Col4) AS Col4
  FROM dbo.[Unpivot] 
  ) AS RawData
UNPIVOT (
  PropertyValue
  FOR PropertyName IN (Col1, Col2, Col3, Col4)
 ) AS UnpivotResults

--this fails because the datatype of Col1 cannot handle the data of Col4
-- What happens if you remove Col4 from the FOR-IN clause?
SELECT UnpivotResults.*
FROM (
  SELECT ID
    , Col1
    , Col2
    , Col3
    , Col4
   FROM dbo.[Unpivot] 
  ) AS RawData
UNPIVOT (
  PropertyValue
  FOR PropertyName IN (Col1, Col2, Col3, Col4)
 ) AS UnpivotResults

UPDATE dbo.[Unpivot] SET Col3 = NULL WHERE ID = 'Blue'
UPDATE dbo.[Unpivot] SET Col2 = NULL WHERE ID = 'Green'
SELECT * FROM dbo.[Unpivot]

--Two rows disappear because the PropertyValue results in NULL
SELECT UnpivotResults.*
FROM (
  SELECT ID
    , Convert(char(3),Col1) AS Col1
    , Convert(char(3),Col2) AS Col2
    , Convert(char(3),Col3) AS Col3
    , Convert(char(3),Col4) AS Col4
   FROM dbo.[Unpivot] 
  ) AS RawData
UNPIVOT (
  PropertyValue
  FOR PropertyName
  IN (Col1, Col2, Col3, Col4)
 ) AS UnpivotResults

--The rows re-appear because I gave them alternate non-NULL values
SELECT UnpivotResults.*
FROM (
  SELECT ID
    , Convert(char(3),Col1) AS Col1
    , IsNull(Convert(char(3),Col2),'{}') AS Col2
    , IsNull(Convert(char(3),Col3),'{}') AS Col3
    , Convert(char(3),Col4) AS Col4
   FROM dbo.[Unpivot] 
  ) AS RawData
UNPIVOT (
  PropertyValue
  FOR PropertyName
  IN (Col1, Col2, Col3, Col4)
 ) AS UnpivotResults