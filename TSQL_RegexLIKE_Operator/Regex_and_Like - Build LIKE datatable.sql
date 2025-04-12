CREATE TABLE dbo.Table_1
( ArbitraryID int IDENTITY(1,1) NOT NULL
  , [value] varchar(3)
)

SET NOCOUNT ON
DECLARE @_value0 smallint = NULL
DECLARE @_value1 smallint = NULL
DECLARE @_value2 smallint = NULL

DECLARE @_value1_flag bit = 0
DECLARE @_value0_flag bit = 0

WHILE 1 = 1
	BEGIN
		SET @_value2 = IsNull(@_value2, 96) + 1

		IF @_value2 > 122
			BEGIN
				SET @_value1_flag = 1 
				SET @_value2 = NULL
			END
		ELSE
			BEGIN
				DECLARE @_text varchar(3) = 
					CONCAT(
						CHAR(@_value0), CHAR(@_value1), CHAR(@_value2)
						  )
				PRINT CONCAT(@_value0, ',', @_value1, ',', @_value2)
				INSERT INTO dbo.Table_1([value]) VALUES (@_text)
			END

		IF @_value1_flag = 1
			BEGIN
				SET @_value1 = IsNull(@_value1, 96) +  1
				SET @_value1_flag = 0
			END

		IF @_value1 > 122
			BEGIN
				SET @_value0_flag = 1
				SET @_value1 = 97
				SET @_value2 = NULL
			END

		IF @_value0_flag = 1
			BEGIN
				SET @_value0 = IsNull(@_value0, 96) + 1
				SET @_value0_flag = 0
			END

		IF @_value0 > 122
			BREAK

	END


