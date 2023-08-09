USE [NewDatabase]
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

		BEGIN TRAN

			SELECT incoming.LocationCode AS [incoming.LocationCode]
			  , incoming.Measurement AS [incoming.Measurement]
			  , incoming.[Value] AS [incoming.Value]
			  , '|' AS '|'
			  , existing.ArbitraryID AS [existing.ArbitraryID]
			  , existing.LocationCode AS [existing.LocationCode]
			  , existing.Measurement AS [existing.Measurement]
			  , existing.[Value] AS [existing.Value]
			INTO [#temp]
			FROM 
				(SELECT ArbitraryID
					, LocationCode
					, Measurement
					, [Value]
				 FROM dbo.Measurements existing
				 WHERE LocationCode = @LocationCode
				 ) existing
			  FULL OUTER JOIN 
				( SELECT @LocationCode AS LocationCode
				  , Measurement
				  , [Value]
				  FROM @dt_Measurements incoming
				) incoming
				  ON incoming.LocationCode = existing.LocationCode
				  AND incoming.Measurement = existing.Measurement

			SELECT * FROM [#temp]

			DELETE dbo.Measurements
			FROM [#temp] t
			WHERE dbo.Measurements.ArbitraryID = t.[existing.ArbitraryID]
			  AND t.[incoming.Measurement] IS NULL
			  AND t.[incoming.Value] IS NULL


			UPDATE existing
			  SET existing.[Value] = t.[incoming.Value]
				, existing.RecordDate_UTC = @_UTCNow
			FROM dbo.Measurements existing
			  INNER JOIN [#temp] t
				 ON existing.ArbitraryID = t.[existing.ArbitraryID]
			WHERE (
					CONCAT(existing.[Value],'') != CONCAT(t.[incoming.Value],'')
				-- OR other non-PK fields differ
				  )

			INSERT INTO dbo.Measurements
				(LocationCode
				, Measurement
				, [Value]
				, RecordDate_UTC
				)
			SELECT @LocationCode
				, [incoming.Measurement]
				, [incoming.Value]
				, @_UTCNow
			FROM [#temp]
			WHERE [existing.ArbitraryID] IS NULL

		COMMIT TRAN

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

DECLARE @_dt [dbo].[Type_Measurements]

EXEC [dbo].[usp_Measurements_Upsert] @LocationCode = NULL, @dt_Measurements = @_dt

-- create a SQL-login named "app" (password "P@$$w0rd") and assign it the same Database Role.

CREATE LOGIN [app] WITH PASSWORD=N'P@$$w0rd', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE USER app FOR LOGIN app
ALTER ROLE [MeasureProc_Executor] ADD MEMBER [app]

-- Generate a new session using this login/password. Can it run the proc? Why not?
-- Can you alter the Database Role such that the "app" login can execute the proc?
-- (Continue reading the presentation to find out how)