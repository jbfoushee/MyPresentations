USE [JsonDemo]

TRUNCATE TABLE [dbo].[Persons]
GO

DROP TABLE IF EXISTS [dbo].[Persons_x_Parents];
GO

CREATE TABLE [dbo].[Persons_x_Parents](
	[ArbitraryID] [int] IDENTITY(1,1) NOT NULL,
	[PersonID] [int] NOT NULL,
	[name] [varchar](128) NOT NULL,
 CONSTRAINT [PK_Persons_x_Parents] PRIMARY KEY CLUSTERED 
(
	[ArbitraryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TRIGGER dbo.tr_Persons ON dbo.Persons
   FOR INSERT, DELETE, UPDATE
AS 
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
      DELETE affected
      FROM [dbo].[Persons_x_Parents] affected
        INNER JOIN deleted
            ON deleted.PersonID = affected.PersonID
    END
--ENDIF

  IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
      INSERT INTO [dbo].[Persons_x_Parents]
         (PersonID, [name])
        SELECT i.PersonID, JSON_VALUE(p.[value], '$.name')
        FROM inserted i
          CROSS APPLY OPENJSON(i.JsonData, '$.parents') p
    END
--ENDIF
END
GO

SELECT * FROM [dbo].[Persons]
SELECT * FROM [dbo].[Persons_x_Parents]
GO

INSERT INTO dbo.Persons (JsonData)
VALUES('{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}')
GO

SELECT * FROM [dbo].[Persons]
SELECT * FROM [dbo].[Persons_x_Parents]
GO

UPDATE [dbo].[Persons]
SET JsonData = JSON_MODIFY(JsonData, '$.json_expert', 'true')
WHERE PersonID = 1
GO

SELECT * FROM [dbo].[Persons]
SELECT * FROM [dbo].[Persons_x_Parents]
GO

TRUNCATE TABLE [dbo].[Persons]
TRUNCATE TABLE [dbo].[Persons_x_Parents]

GO

ALTER TRIGGER [dbo].[tr_Persons] ON [dbo].[Persons]
   FOR INSERT, DELETE, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @_ModType char(1)
    IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            IF EXISTS (SELECT 1 FROM deleted)
                SET @_ModType = 'U'
            ELSE
                SET @_ModType = 'I'
        END
    ELSE
        SET @_ModType = 'D'

    DECLARE @_PersonID int
    SELECT @_PersonID = ISNULL(i.PersonID, d.PersonID) FROM inserted i, deleted d

    IF @_ModType IN ('U', 'I')
        BEGIN
            SELECT i.PersonID, JSON_VALUE(p.[value], '$.name') AS '$.name'
            INTO #temp
            FROM inserted i
              CROSS APPLY OPENJSON(i.JsonData, '$.parents') p

            MERGE [dbo].[Persons_x_Parents] AS [target]
            USING #temp AS [source]
               ON [source].PersonID = [target].PersonID
               AND [source].[$.name] = [target].[name]
            WHEN NOT MATCHED BY TARGET THEN
               INSERT (PersonID, [name])
               VALUES ([source].PersonID, [source].[$.name])
            WHEN NOT MATCHED BY SOURCE
                AND [target].PersonID = @_PersonID
              THEN DELETE;
        END
    IF @_ModType = 'D'
        DELETE affected
        FROM [dbo].[Persons_x_Parents] affected
          INNER JOIN deleted
              ON deleted.PersonID = affected.PersonID
END

INSERT INTO dbo.Persons (JsonData)
VALUES('{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}')
GO

SELECT * FROM [dbo].[Persons]
SELECT * FROM [dbo].[Persons_x_Parents]
GO

UPDATE [dbo].[Persons]
SET JsonData = JSON_MODIFY(JsonData, '$.json_expert', 'true')
WHERE PersonID = 1
GO

SELECT * FROM [dbo].[Persons]
SELECT * FROM [dbo].[Persons_x_Parents]
GO
