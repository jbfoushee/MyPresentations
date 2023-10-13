IF IS_SRVROLEMEMBER('sysadmin') = 0
	BEGIN
		RAISERROR('Run as sa!', 20, 1) WITH LOG
	END
GO

USE [NewDatabase]
GO

CREATE TABLE [dbo].[Measurements](
	[ArbitraryID] [int] IDENTITY(1,1) NOT NULL,
	[LocationCode] [smallint] NOT NULL,
	[Measurement] [varchar](10) NOT NULL,
	[Value] [int] NOT NULL,
	[RecordDate_UTC] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo.Measurements] PRIMARY KEY CLUSTERED 
(
	[ArbitraryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_dbo.Measurements] UNIQUE NONCLUSTERED 
(
	[LocationCode] ASC,
	[Measurement] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE TYPE [dbo].[Type_Measurements] AS TABLE(
	[Measurement] [varchar](10) NOT NULL,
	[Value] [int] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[Measurement] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

CREATE PROCEDURE [dbo].[usp_Measurements_Upsert]
	@LocationCode smallint
	, @dt_Measurements [dbo].[Type_Measurements] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @_ErrorMessage nvarchar(4000);
	DECLARE @_ErrorSeverity int;
	DECLARE @_ErrorState int;

	DECLARE @_UTCNow datetime = getutcdate()

	BEGIN TRY

		MERGE dbo.Measurements AS tgt
		USING @dt_Measurements AS src
		ON (tgt.LocationCode = @LocationCode
			AND tgt.Measurement = src.Measurement)
		WHEN MATCHED THEN
			UPDATE
				SET [Value] = src.[Value]
				, RecordDate_UTC = @_UTCNow
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (LocationCode, Measurement, [Value], RecordDate_UTC)
			VALUES (@LocationCode, src.Measurement, src.[Value], @_UTCNow)
		WHEN NOT MATCHED BY SOURCE 
				AND tgt.LocationCode = @LocationCode
			THEN DELETE;

	END TRY

	BEGIN CATCH

		SELECT
			@_ErrorMessage = CONCAT('[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']: ', ERROR_MESSAGE()),
			@_ErrorSeverity = ERROR_SEVERITY(),
			@_ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0 ROLLBACK TRAN

		RAISERROR(@_ErrorMessage, @_ErrorSeverity, @_ErrorState);
		RETURN(-1)

	END CATCH

END



-- Now, using SSMS, go create the Database Role "MeasureProc_Executor" and assign it ability to EXECUTE proc
/ *
GRANT EXECUTE ON [dbo].[usp_Measurements_Upsert] TO [MeasureProc_Executor]
*/


DECLARE @_dt [dbo].[Type_Measurements]

EXEC [dbo].[usp_Measurements_Upsert] @LocationCode = NULL, @dt_Measurements = @_dt

-- create a SQL-login named "app" (password "P@$$w0rd") and assign it the same Database Role.

CREATE LOGIN [app] WITH PASSWORD=N'P@$$w0rd', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE USER app FOR LOGIN app
ALTER ROLE [MeasureProc_Executor] ADD MEMBER [app]

-- Generate a new session using this login/password. Can it run the proc? Why not?
-- Can you alter the Database Role such that the "app" login can execute the proc?
-- (Continue reading the presentation to find out how)