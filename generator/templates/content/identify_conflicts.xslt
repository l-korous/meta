<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />

IF OBJECT_ID ('dbo.identify_conflicts_A') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_A
GO

CREATE PROCEDURE dbo.identify_conflicts_A
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @min_version_order_master int, @number_of_conflicts int output)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
	   
	   set @number_of_conflicts = (
		  SELECT COUNT(*)
		  FROM dbo.hist_A h_master
			 INNER JOIN dbo.hist_A h_branch ON
				h_master.id = h_branch.id
				AND h_master.branch_id = 'master'
				AND h_branch.branch_id = @branch_id
				AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				AND h_master.valid_to IS NULL
				AND h_branch.valid_to IS NULL
				AND (
					   (
						  (h_master.cA IS NULL AND h_branch.cA IS NOT NULL)
						  OR
						  (h_master.cA IS NOT NULL AND h_branch.cA IS NULL)
						  OR
						  (h_master.cA <> h_branch.cA)
					   )
					   OR
					   (
						  (h_master.B_id IS NULL AND h_branch.B_id IS NOT NULL)
						  OR
						  (h_master.B_id IS NOT NULL AND h_branch.B_id IS NULL)
						  OR
						  (h_master.B_id <> h_branch.B_id)
					   )
					   OR
					   (
						  (h_master.this_is_my_column_name IS NULL AND h_branch.this_is_my_column_name IS NOT NULL)
						  OR
						  (h_master.this_is_my_column_name IS NOT NULL AND h_branch.this_is_my_column_name IS NULL)
						  OR
						  (h_master.this_is_my_column_name <> h_branch.this_is_my_column_name)
					   )
				    )

	   )
	   IF @number_of_conflicts > 0 BEGIN
		  INSERT INTO dbo.conflicts_A
		  SELECT @merge_version_id, h_master.id, h_master.is_delete, h_branch.is_delete, h_master.cA, h_master.B_id, h_master.this_is_my_column_name, h_branch.cA, h_branch.B_id, h_branch.this_is_my_column_name, h_master.author, h_master.version_id, h_master.valid_from
		  FROM
			 dbo.hist_A h_master
			 INNER JOIN dbo.hist_A h_branch
				ON h_master.id = h_branch.id
				    AND h_master.branch_id = 'master'
				    AND h_branch.branch_id = @branch_id
				    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				    AND h_master.valid_to IS NULL
				    AND h_branch.valid_to IS NULL
				    AND (
					   (
						  (h_master.cA IS NULL AND h_branch.cA IS NOT NULL)
						  OR
						  (h_master.cA IS NOT NULL AND h_branch.cA IS NULL)
						  OR
						  (h_master.cA <> h_branch.cA)
					   )
					   OR
					   (
						  (h_master.B_id IS NULL AND h_branch.B_id IS NOT NULL)
						  OR
						  (h_master.B_id IS NOT NULL AND h_branch.B_id IS NULL)
						  OR
						  (h_master.B_id <> h_branch.B_id)
					   )
					   OR
					   (
						  (h_master.this_is_my_column_name IS NULL AND h_branch.this_is_my_column_name IS NOT NULL)
						  OR
						  (h_master.this_is_my_column_name IS NOT NULL AND h_branch.this_is_my_column_name IS NULL)
						  OR
						  (h_master.this_is_my_column_name <> h_branch.this_is_my_column_name)
					   )
				    )
	   END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
</xsl:template>
</xsl:stylesheet>
