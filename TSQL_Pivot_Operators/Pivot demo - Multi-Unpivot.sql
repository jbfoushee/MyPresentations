CREATE TABLE [dbo].[MultiUnpivot](
	[ServerName] [varchar](16) NOT NULL,
	[Contact1_FName] [varchar](15) NOT NULL,
	[Contact1_LName] [varchar](15) NOT NULL,
	[Contact1_Phone] [varchar](15) NOT NULL,
	[Contact2_FName] [varchar](15) NOT NULL,
	[Contact2_LName] [varchar](15) NOT NULL,
	[Contact2_Phone] [varchar](15) NOT NULL
)

INSERT INTO dbo.MultiUnpivot (ServerName, Contact1_FName, Contact1_LName, Contact1_Phone, Contact2_FName, Contact2_LName, Contact2_Phone)
VALUES ('LOUSISWPS130', 'Kevin', 'Herndon', '502-555-KEVN', 'Jeff', 'Foushee', '502-555-JEFF')

SELECT *
FROM
(	SELECT [ServerName]
		,[Contact1_FName],[Contact1_LName],[Contact1_Phone]
		,[Contact2_FName],[Contact2_LName],[Contact2_Phone]
		, '|' AS '|'
	FROM [PivotDemo].[dbo].[MultiUnpivot]
) RawData

UNPIVOT
  ( FName FOR element1 IN ([Contact1_FName], [Contact2_FName]) ) transform1

UNPIVOT
  ( LName FOR element2 IN ([Contact1_LName], [Contact2_LName]) ) transform2

UNPIVOT
  ( Phone FOR element3 IN ([Contact1_Phone], [Contact2_Phone]) ) transform3

WHERE Left(element1, 8) = Left(element2, 8)
  AND Left(element2, 8) = Left(element3, 8)