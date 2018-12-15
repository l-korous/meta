<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
IF OBJECT_ID ('dbo.merge_branch') IS NOT NULL 
     DROP PROCEDURE dbo.merge_branch
GO
CREATE PROCEDURE dbo.merge_branch
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @force_merge bit = 0)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        BEGIN TRANSACTION
        -- SANITY CHECKS
       -- Branch exists
       IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
          set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
          THROW 50000, @msg, 1
       END
       -- Merge version does not exist
       IF EXISTS (select * from dbo.version where version_id = @merge_version_id and branch_id = 'master') BEGIN
          set @msg = 'ERROR: Merge version ' + @merge_version_id + ' already exists in master (has been merged)';
          THROW 50000, @msg, 1
       END
       -- Master has no open versions
       IF (SELECT version_status from dbo.branch b inner join dbo.version v on current_version_id = v.version_id and b.branch_id = 'master') = 'open' BEGIN
          set @msg = 'ERROR: Master has an open version ' + (SELECT current_version_id from dbo.branch where branch_id = 'master');
          THROW 50000, @msg, 1
       END

       -- The version on the branch being merged is on the top of the branch or the last closed one
       IF EXISTS (
          select *
          from
             dbo.version _v
             INNER JOIN dbo.branch _b
                ON
                    _v.version_id = @merge_version_id
                    and _v.branch_id = @branch_id
                    AND _v.branch_id = _b.branch_id
                    and (
                          (_b.current_version_id IS NULL AND _v.version_id &lt;&gt; _b.last_closed_version_id)
                          OR
                          (_b.current_version_id IS NOT NULL AND _v.version_id &lt;&gt; _b.current_version_id)
                       )
       ) BEGIN
          set @msg = 'ERROR: The version ' + @merge_version_id + ' exists and is not on the top of ' + @branch_id;
          THROW 50000, @msg, 1
       END

       DECLARE @min_version_order_master int = (SELECT version_order from dbo.[version] where version_id = (SELECT start_master_version_id FROM dbo.[branch] where branch_id = @branch_id))
       
       -- Create the version in the branch if it does not exist.
       IF NOT EXISTS (select * from dbo.version where version_id = @merge_version_id and branch_id = @branch_id) BEGIN
          declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.version) + 1
          declare @previous_version_id NVARCHAR(50) = (select ISNULL(current_version_id, last_closed_version_id) from dbo.branch where branch_id = @branch_id)
          INSERT INTO dbo.[version] VALUES (@merge_version_id, @branch_id, @previous_version_id, @max_version_order_plus_one, 'merging')
          UPDATE dbo.branch SET current_version_id = @merge_version_id where branch_id = @branch_id
          -- NOTE: This closes the previous version
          UPDATE dbo.version SET version_status = 'closed' where version_id = @previous_version_id
          UPDATE dbo.branch SET last_closed_version_id = @previous_version_id where branch_id = @branch_id
       END
       -- If the version does exist, make its status 'merging'
       ELSE BEGIN
          IF (select version_status from dbo.version where version_id = @merge_version_id and branch_id = @branch_id) &lt;&gt; 'merging'
          BEGIN
             UPDATE dbo.version SET version_status = 'merging' where version_id = @merge_version_id
             UPDATE dbo.branch SET current_version_id = @merge_version_id where branch_id = @branch_id
          END
       END
       -- Put the version to master
       UPDATE dbo.branch
          SET current_version_id = @merge_version_id
          WHERE branch_id = 'master' 

       -- Conflict check
        <xsl:for-each select="//table" >
            TRUNCATE TABLE dbo.conflicts_<xsl:value-of select="@table_name" />
        </xsl:for-each>
        IF @force_merge = 0 BEGIN
        DECLARE @number_of_conflicts int = 0, @number_of_conflicts_util int
        <xsl:for-each select="//table" >
            EXEC dbo.identify_conflicts_<xsl:value-of select="@table_name" /> @branch_id, @merge_version_id, @min_version_order_master, @number_of_conflicts_util output
            set @number_of_conflicts = @number_of_conflicts + @number_of_conflicts_util
        </xsl:for-each>     
        COMMIT TRANSACTION
             
          BEGIN TRANSACTION
          IF @number_of_conflicts > 0 BEGIN
             set @msg = 'Conflicts present. Check conflicts_* tables. Resolve conflicts by setting desired resulting values, and perform a force merge';
             THROW 60000, @msg, 1
          END
       END
       -- No conflicts / forced, put all changes to master
       declare @current_datetime datetime = getdate()
       EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        <xsl:for-each select="//table" >
            EXEC dbo.perform_merge_<xsl:value-of select="@table_name" /> @branch_id, @merge_version_id, @current_datetime
        </xsl:for-each>   
       exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
    
       -- Only now the version goes to master
       declare @previous_version_id_master nvarchar(50) = (select last_closed_version_id from dbo.branch where branch_id = 'master')
       UPDATE dbo.version
          SET branch_id = 'master',
             previous_version_id = @previous_version_id_master,
             version_status = 'closed'
          WHERE
             version_id = @merge_version_id

       -- Move the last version of master
       UPDATE dbo.branch
          SET last_closed_version_id = @merge_version_id,
          current_version_id = NULL
          WHERE branch_id = 'master'

       UPDATE dbo.branch
          SET current_version_id = NULL
          WHERE branch_id = @branch_id

       COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
       IF ERROR_NUMBER() &lt;&gt; 60000
          ROLLBACK TRANSACTION;
       THROW
    END CATCH
END
</xsl:template>
</xsl:stylesheet>
