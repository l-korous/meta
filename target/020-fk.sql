
use meta3
GO

ALTER TABLE dbo.[Column] ADD CONSTRAINT FK_Column_table_name_Table_name FOREIGN KEY ([table_name], [branch_id]) REFERENCES dbo.[Table]([name], [branch_id]) ON UPDATE NO ACTION ON DELETE CASCADE
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_Reference_src_table_Table_name FOREIGN KEY ([src_table], [branch_id]) REFERENCES dbo.[Table]([name], [branch_id]) ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_Reference_src_column_Column_name FOREIGN KEY ([src_column], [branch_id]) REFERENCES dbo.[Column]([name], [branch_id]) ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_Reference_dest_table_Table_name FOREIGN KEY ([dest_table], [branch_id]) REFERENCES dbo.[Table]([name], [branch_id]) ON UPDATE NO ACTION ON DELETE NO ACTION
ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_Reference_dest_column_Column_name FOREIGN KEY ([dest_column], [branch_id]) REFERENCES dbo.[Column]([name], [branch_id]) ON UPDATE NO ACTION ON DELETE NO ACTION