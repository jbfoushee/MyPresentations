PRINT ''
DECLARE @_myid varchar(36) = NEWID()
PRINT CONCAT('Original GUID:  ', @_myid)
PRINT ''
PRINT CONCAT('Dashes removed: ', REPLACE(@_myid, '-', ''))
PRINT 'Double-click the value, and notice the whole value is selected.'
PRINT ''

DECLARE @_beforemap char(7) = 'ABCDEF-'

PRINT 'For all the next values, we should be able to (but will not):'
PRINT ' - locate a value that is less that 36 characters'
PRINT ' - double-click the value to highlight the entire value'
PRINT ''

DECLARE @_smallint smallint = 0
WHILE @_smallint < 256
	BEGIN
		DECLARE @_aftermap char(7) = REPLICATE(CHAR(@_smallint), 7)

		DECLARE @_result varchar(36) = TRANSLATE(@_myid, @_beforemap, @_aftermap)

		DECLARE @_datalength int = DATALENGTH(@_result)

		PRINT CONCAT('CHAR(', @_smallint, ') ************', CHAR(13)
			, '   ', @_result, CHAR(9), @_datalength)

		IF @_datalength != 36 BREAK

		SET @_smallint += 1
	END


/*
-- CHAR(0) was omitted.
-- For added bonus, run the following and compare between the SELECT, and PRINT.
-- Copy the PRINT-results to a Notepad session.

DECLARE @_myid varchar(36) = NEWID()
PRINT CONCAT('Original GUID:  ', @_myid)
SELECT @_myid

DECLARE @_beforemap char(7) = 'ABCDEF-'
DECLARE @_aftermap char(7) = REPLICATE(CHAR(0), 7)

DECLARE @_result varchar(36) = TRANSLATE(@_myid, @_beforemap, @_aftermap)
DECLARE @_datalength int = DATALENGTH(@_result)


PRINT CONCAT('CHAR(0) ************', CHAR(13)
			, '   ', @_result, CHAR(9), @_datalength)
SELECT @_result

*/