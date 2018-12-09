
    
use meta3
GO

IF OBJECT_ID ('dbo.identify_conflicts_Column') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_Column
GO
CREATE PROCEDURE dbo.identify_conflicts_Column
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
          FROM dbo.hist_Column h_master
             INNER JOIN dbo.hist_Column h_branch ON
                
                    h_master.[name] = h_branch.[name] AND
                
                    h_master.[table_name] = h_branch.[table_name] AND
                
                h_master.branch_id = 'master'
                AND h_branch.branch_id = @branch_id
                AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                AND h_master.valid_to IS NULL
                AND h_branch.valid_to IS NULL
                AND (
                        (0 = 1)
                        
                        OR
                            (
                              (h_master.[is_primary_key] IS NULL AND h_branch.[is_primary_key] IS NOT NULL)
                              OR
                              (h_master.[is_primary_key] IS NOT NULL AND h_branch.[is_primary_key] IS NULL)
                              OR
                              (h_master.[is_primary_key] <> h_branch.[is_primary_key])
                           )
                        
                        OR
                            (
                              (h_master.[is_unique] IS NULL AND h_branch.[is_unique] IS NOT NULL)
                              OR
                              (h_master.[is_unique] IS NOT NULL AND h_branch.[is_unique] IS NULL)
                              OR
                              (h_master.[is_unique] <> h_branch.[is_unique])
                           )
                        
                        OR
                            (
                              (h_master.[datatype] IS NULL AND h_branch.[datatype] IS NOT NULL)
                              OR
                              (h_master.[datatype] IS NOT NULL AND h_branch.[datatype] IS NULL)
                              OR
                              (h_master.[datatype] <> h_branch.[datatype])
                           )
                        
                        OR
                            (
                              (h_master.[is_nullable] IS NULL AND h_branch.[is_nullable] IS NOT NULL)
                              OR
                              (h_master.[is_nullable] IS NOT NULL AND h_branch.[is_nullable] IS NULL)
                              OR
                              (h_master.[is_nullable] <> h_branch.[is_nullable])
                           )
                        
                    )

       )
       IF @number_of_conflicts > 0 BEGIN
          INSERT INTO dbo.conflicts_Column
          SELECT @merge_version_id,
          
            h_master.[name],
        
            h_master.[table_name],
        
          h_master.is_delete, h_branch.is_delete,
          
            h_master.[is_primary_key],
        
            h_master.[is_unique],
        
            h_master.[datatype],
        
            h_master.[is_nullable],
        
            h_branch.[is_primary_key],
        
            h_branch.[is_unique],
        
            h_branch.[datatype],
        
            h_branch.[is_nullable],
        
          h_master.author, h_master.version_id, h_master.valid_from
          FROM
             dbo.hist_Column h_master
             INNER JOIN dbo.hist_Column h_branch
                ON
                    
                        h_master.[name] = h_branch.[name] AND
                    
                        h_master.[table_name] = h_branch.[table_name] AND
                    
                    h_master.branch_id = 'master'
                    AND h_branch.branch_id = @branch_id
                    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                    AND h_master.valid_to IS NULL
                    AND h_branch.valid_to IS NULL
                    AND (
                        0 = 1
                        
                            OR
                            (
                              (h_master.[is_primary_key] IS NULL AND h_branch.[is_primary_key] IS NOT NULL)
                              OR
                              (h_master.[is_primary_key] IS NOT NULL AND h_branch.[is_primary_key] IS NULL)
                              OR
                              (h_master.[is_primary_key] <> h_branch.[is_primary_key])
                           )
                        
                            OR
                            (
                              (h_master.[is_unique] IS NULL AND h_branch.[is_unique] IS NOT NULL)
                              OR
                              (h_master.[is_unique] IS NOT NULL AND h_branch.[is_unique] IS NULL)
                              OR
                              (h_master.[is_unique] <> h_branch.[is_unique])
                           )
                        
                            OR
                            (
                              (h_master.[datatype] IS NULL AND h_branch.[datatype] IS NOT NULL)
                              OR
                              (h_master.[datatype] IS NOT NULL AND h_branch.[datatype] IS NULL)
                              OR
                              (h_master.[datatype] <> h_branch.[datatype])
                           )
                        
                            OR
                            (
                              (h_master.[is_nullable] IS NULL AND h_branch.[is_nullable] IS NOT NULL)
                              OR
                              (h_master.[is_nullable] IS NOT NULL AND h_branch.[is_nullable] IS NULL)
                              OR
                              (h_master.[is_nullable] <> h_branch.[is_nullable])
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

IF OBJECT_ID ('dbo.identify_conflicts_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_Reference
GO
CREATE PROCEDURE dbo.identify_conflicts_Reference
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
          FROM dbo.hist_Reference h_master
             INNER JOIN dbo.hist_Reference h_branch ON
                
                    h_master.[name] = h_branch.[name] AND
                
                h_master.branch_id = 'master'
                AND h_branch.branch_id = @branch_id
                AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                AND h_master.valid_to IS NULL
                AND h_branch.valid_to IS NULL
                AND (
                        (0 = 1)
                        
                        OR
                            (
                              (h_master.[src_table] IS NULL AND h_branch.[src_table] IS NOT NULL)
                              OR
                              (h_master.[src_table] IS NOT NULL AND h_branch.[src_table] IS NULL)
                              OR
                              (h_master.[src_table] <> h_branch.[src_table])
                           )
                        
                        OR
                            (
                              (h_master.[src_column] IS NULL AND h_branch.[src_column] IS NOT NULL)
                              OR
                              (h_master.[src_column] IS NOT NULL AND h_branch.[src_column] IS NULL)
                              OR
                              (h_master.[src_column] <> h_branch.[src_column])
                           )
                        
                        OR
                            (
                              (h_master.[dest_table] IS NULL AND h_branch.[dest_table] IS NOT NULL)
                              OR
                              (h_master.[dest_table] IS NOT NULL AND h_branch.[dest_table] IS NULL)
                              OR
                              (h_master.[dest_table] <> h_branch.[dest_table])
                           )
                        
                        OR
                            (
                              (h_master.[dest_column] IS NULL AND h_branch.[dest_column] IS NOT NULL)
                              OR
                              (h_master.[dest_column] IS NOT NULL AND h_branch.[dest_column] IS NULL)
                              OR
                              (h_master.[dest_column] <> h_branch.[dest_column])
                           )
                        
                        OR
                            (
                              (h_master.[on_delete] IS NULL AND h_branch.[on_delete] IS NOT NULL)
                              OR
                              (h_master.[on_delete] IS NOT NULL AND h_branch.[on_delete] IS NULL)
                              OR
                              (h_master.[on_delete] <> h_branch.[on_delete])
                           )
                        
                    )

       )
       IF @number_of_conflicts > 0 BEGIN
          INSERT INTO dbo.conflicts_Reference
          SELECT @merge_version_id,
          
            h_master.[name],
        
          h_master.is_delete, h_branch.is_delete,
          
            h_master.[src_table],
        
            h_master.[src_column],
        
            h_master.[dest_table],
        
            h_master.[dest_column],
        
            h_master.[on_delete],
        
            h_branch.[src_table],
        
            h_branch.[src_column],
        
            h_branch.[dest_table],
        
            h_branch.[dest_column],
        
            h_branch.[on_delete],
        
          h_master.author, h_master.version_id, h_master.valid_from
          FROM
             dbo.hist_Reference h_master
             INNER JOIN dbo.hist_Reference h_branch
                ON
                    
                        h_master.[name] = h_branch.[name] AND
                    
                    h_master.branch_id = 'master'
                    AND h_branch.branch_id = @branch_id
                    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                    AND h_master.valid_to IS NULL
                    AND h_branch.valid_to IS NULL
                    AND (
                        0 = 1
                        
                            OR
                            (
                              (h_master.[src_table] IS NULL AND h_branch.[src_table] IS NOT NULL)
                              OR
                              (h_master.[src_table] IS NOT NULL AND h_branch.[src_table] IS NULL)
                              OR
                              (h_master.[src_table] <> h_branch.[src_table])
                           )
                        
                            OR
                            (
                              (h_master.[src_column] IS NULL AND h_branch.[src_column] IS NOT NULL)
                              OR
                              (h_master.[src_column] IS NOT NULL AND h_branch.[src_column] IS NULL)
                              OR
                              (h_master.[src_column] <> h_branch.[src_column])
                           )
                        
                            OR
                            (
                              (h_master.[dest_table] IS NULL AND h_branch.[dest_table] IS NOT NULL)
                              OR
                              (h_master.[dest_table] IS NOT NULL AND h_branch.[dest_table] IS NULL)
                              OR
                              (h_master.[dest_table] <> h_branch.[dest_table])
                           )
                        
                            OR
                            (
                              (h_master.[dest_column] IS NULL AND h_branch.[dest_column] IS NOT NULL)
                              OR
                              (h_master.[dest_column] IS NOT NULL AND h_branch.[dest_column] IS NULL)
                              OR
                              (h_master.[dest_column] <> h_branch.[dest_column])
                           )
                        
                            OR
                            (
                              (h_master.[on_delete] IS NULL AND h_branch.[on_delete] IS NOT NULL)
                              OR
                              (h_master.[on_delete] IS NOT NULL AND h_branch.[on_delete] IS NULL)
                              OR
                              (h_master.[on_delete] <> h_branch.[on_delete])
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

IF OBJECT_ID ('dbo.identify_conflicts_Table') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_Table
GO
CREATE PROCEDURE dbo.identify_conflicts_Table
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
          FROM dbo.hist_Table h_master
             INNER JOIN dbo.hist_Table h_branch ON
                
                    h_master.[name] = h_branch.[name] AND
                
                h_master.branch_id = 'master'
                AND h_branch.branch_id = @branch_id
                AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                AND h_master.valid_to IS NULL
                AND h_branch.valid_to IS NULL
                AND (
                        (0 = 1)
                        
                    )

       )
       IF @number_of_conflicts > 0 BEGIN
          INSERT INTO dbo.conflicts_Table
          SELECT @merge_version_id,
          
            h_master.[name],
        
          h_master.is_delete, h_branch.is_delete,
          
          h_master.author, h_master.version_id, h_master.valid_from
          FROM
             dbo.hist_Table h_master
             INNER JOIN dbo.hist_Table h_branch
                ON
                    
                        h_master.[name] = h_branch.[name] AND
                    
                    h_master.branch_id = 'master'
                    AND h_branch.branch_id = @branch_id
                    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
                    AND h_master.valid_to IS NULL
                    AND h_branch.valid_to IS NULL
                    AND (
                        0 = 1
                        
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
