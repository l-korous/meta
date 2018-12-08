<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />

IF OBJECT_ID ('dbo.upd_A') IS NOT NULL 
     DROP PROCEDURE dbo.upd_A
GO

CREATE PROCEDURE dbo.upd_A(@branch_id NVARCHAR(50), @id int,
@cA nvarchar(255),
@B_id int,
@this_is_my_column_name float
)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
			 THROW 50000, @msg, 1
		  END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
			 THROW 50000, @msg, 1
		  END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open'
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
			 THROW 50000, @msg, 1
		  END
		  
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

	   IF EXISTS(SELECT id FROM dbo.A WHERE id = @id AND branch_id = @branch_id)
		  BEGIN
			 -- EQUALITY CHECK
			 declare @cA_same bit = (select IIF(cA = @cA,1,0) FROM dbo.A WHERE id = @id AND branch_id = @branch_id)
			 declare @B_id_same bit = (select IIF(B_id = @B_id,1,0) FROM dbo.A WHERE id = @id AND branch_id = @branch_id)
			 declare @this_is_my_column_name_same bit = (select IIF(this_is_my_column_name = @this_is_my_column_name,1,0) FROM dbo.A WHERE id = @id AND branch_id = @branch_id)

			 IF
				@cA_same = 1
				AND @B_id_same = 1
				AND @this_is_my_column_name_same = 1
				BEGIN
                    COMMIT TRANSACTION;
                    RETURN
                END

			 UPDATE dbo.A SET
				cA = @cA,
				B_id = @B_id,
				this_is_my_column_name = @this_is_my_column_name
			 WHERE id = @id
				AND branch_id = @branch_id

			 -- EXISTENCE of history record for this branch (always true for master)
			 IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_A WHERE id = @id AND branch_id = @branch_id)
				BEGIN
				    INSERT INTO dbo.hist_A
				    SELECT id,
				    cA,
				    B_id,
				    this_is_my_column_name,
				    @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
				    FROM dbo.hist_A WHERE id = @id AND branch_id = 'master' and valid_to is null
				END
			 ELSE
				BEGIN
				    UPDATE dbo.hist_A SET
					   valid_to = @current_datetime
				    WHERE id = @id
					   AND branch_id = @branch_id
					   AND valid_to IS NULL
				END

			 INSERT INTO dbo.hist_A VALUES (
				@id,
				@cA,
				@B_id,
				@this_is_my_column_name_same,
				@branch_id,
				@current_version,
				@current_datetime,
				NULL,
				0,
				CURRENT_USER
			 )
		  END
	   ELSE
		  BEGIN
			 set @msg = 'ERROR: A (id: ' + CAST(@id AS NVARCHAR(MAX)) + ') does not exist';
			 THROW 50000, @msg, 1
		  END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
</xsl:template>
</xsl:stylesheet>
