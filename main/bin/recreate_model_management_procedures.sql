use meta3
GO
IF OBJECT_ID ('meta.model_upload') IS NOT NULL 
     DROP PROCEDURE meta.model_upload
GO
CREATE PROCEDURE meta.model_upload
(@xml_model_file NVARCHAR(255))
AS
BEGIN
END

use meta3
GO
IF OBJECT_ID ('meta.model_diff_migration_generator') IS NOT NULL 
     DROP PROCEDURE meta.model_diff_migration_generator
GO
CREATE PROCEDURE meta.model_diff_migration_generator
(@xml_model_file NVARCHAR(255))
AS
BEGIN
END

