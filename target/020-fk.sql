
use meta3
GO

ALTER TABLE dbo.[Column] ADD CONSTRAINT FK_col_to_table_Column_Table FOREIGN KEY (
    
        [table_name],
    
    [branch_id])
    REFERENCES dbo.[Table] (
    
        [table_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE CASCADE
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_ref_to_src_table_Reference_Table FOREIGN KEY (
    
        [src_table_name],
    
    [branch_id])
    REFERENCES dbo.[Table] (
    
        [table_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_ref_to_dest_table_Reference_Table FOREIGN KEY (
    
        [dest_table_name],
    
    [branch_id])
    REFERENCES dbo.[Table] (
    
        [table_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[ReferenceDetail] ADD CONSTRAINT FK_ref_detail_to_src_ReferenceDetail_Column FOREIGN KEY (
    
        [src_column_name],
    
        [src_table_name],
    
    [branch_id])
    REFERENCES dbo.[Column] (
    
        [column_name],
    
        [table_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[ReferenceDetail] ADD CONSTRAINT FK_ref_detail_to_dest_ReferenceDetail_Column FOREIGN KEY (
    
        [dest_column_name],
    
        [dest_table_name],
    
    [branch_id])
    REFERENCES dbo.[Column] (
    
        [column_name],
    
        [table_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[ReferenceDetail] ADD CONSTRAINT FK_ref_detail_to_ref_ReferenceDetail_Reference FOREIGN KEY (
    
        [reference_name],
    
    [branch_id])
    REFERENCES dbo.[Reference] (
    
        [reference_name],
    
    [branch_id])
    ON UPDATE NO ACTION ON DELETE NO ACTION