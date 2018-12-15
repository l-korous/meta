
    
use meta3
GO

CREATE TABLE dbo.[Table]
(
    
        [table_name] nvarchar(255) NOT NULL,
    
    branch_id NVARCHAR(50),
    PRIMARY KEY (
        
            [table_name],
        
    branch_id
    )
)

CREATE TABLE dbo.hist_Table
(
    
        [table_name] nvarchar(255),
    
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_Table
(
    merge_version_id NVARCHAR(50),
    
        [table_name] nvarchar(255),
    
    is_del_master BIT,
    is_del_branch BIT,
    
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[Table] ADD CONSTRAINT FK_Table_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Table ADD CONSTRAINT FK_hist_Table_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Table ADD CONSTRAINT FK_hist_Table_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Table ADD CONSTRAINT FK_conflicts_Table_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Table ADD CONSTRAINT FK_conflicts_Table_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

CREATE TABLE dbo.[Column]
(
    
        [column_name] nvarchar(255) NOT NULL,
    
        [table_name] nvarchar(255) NOT NULL,
    
        [datatype] nvarchar(255) NOT NULL,
    
        [is_primary_key] BIT NOT NULL,
    
        [is_unique] BIT NOT NULL,
    
        [is_nullable] BIT NOT NULL,
    
    branch_id NVARCHAR(50),
    PRIMARY KEY (
        
            [column_name],
        
            [table_name],
        
    branch_id
    )
)

CREATE TABLE dbo.hist_Column
(
    
        [column_name] nvarchar(255),
    
        [table_name] nvarchar(255),
    
        [datatype] nvarchar(255),
    
        [is_primary_key] BIT,
    
        [is_unique] BIT,
    
        [is_nullable] BIT,
    
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_Column
(
    merge_version_id NVARCHAR(50),
    
        [column_name] nvarchar(255),
    
        [table_name] nvarchar(255),
    
    is_del_master BIT,
    is_del_branch BIT,
    datatype_master   nvarchar(255),
    is_primary_key_master   BIT,
    is_unique_master   BIT,
    is_nullable_master   BIT,
    datatype_branch   nvarchar(255),
    is_primary_key_branch   BIT,
    is_unique_branch   BIT,
    is_nullable_branch   BIT,
    
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[Column] ADD CONSTRAINT FK_Column_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Column ADD CONSTRAINT FK_hist_Column_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Column ADD CONSTRAINT FK_hist_Column_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Column ADD CONSTRAINT FK_conflicts_Column_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Column ADD CONSTRAINT FK_conflicts_Column_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

CREATE TABLE dbo.[Reference]
(
    
        [reference_name] nvarchar(255) NOT NULL,
    
        [src_table_name] nvarchar(255) NOT NULL,
    
        [dest_table_name] nvarchar(255) NOT NULL,
    
        [on_delete] nvarchar(255),
    
    branch_id NVARCHAR(50),
    PRIMARY KEY (
        
            [reference_name],
        
    branch_id
    )
)

CREATE TABLE dbo.hist_Reference
(
    
        [reference_name] nvarchar(255),
    
        [src_table_name] nvarchar(255),
    
        [dest_table_name] nvarchar(255),
    
        [on_delete] nvarchar(255),
    
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_Reference
(
    merge_version_id NVARCHAR(50),
    
        [reference_name] nvarchar(255),
    
    is_del_master BIT,
    is_del_branch BIT,
    src_table_name_master   nvarchar(255),
    dest_table_name_master   nvarchar(255),
    on_delete_master   nvarchar(255),
    src_table_name_branch   nvarchar(255),
    dest_table_name_branch   nvarchar(255),
    on_delete_branch   nvarchar(255),
    
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[Reference] ADD CONSTRAINT FK_Reference_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Reference ADD CONSTRAINT FK_hist_Reference_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_Reference ADD CONSTRAINT FK_hist_Reference_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Reference ADD CONSTRAINT FK_conflicts_Reference_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_Reference ADD CONSTRAINT FK_conflicts_Reference_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

CREATE TABLE dbo.[ReferenceDetail]
(
    
        [reference_name] nvarchar(255) NOT NULL,
    
        [src_table_name] nvarchar(255) NOT NULL,
    
        [src_column_name] nvarchar(255) NOT NULL,
    
        [dest_table_name] nvarchar(255) NOT NULL,
    
        [dest_column_name] nvarchar(255) NOT NULL,
    
    branch_id NVARCHAR(50),
    PRIMARY KEY (
        
            [reference_name],
        
            [src_column_name],
        
    branch_id
    )
)

CREATE TABLE dbo.hist_ReferenceDetail
(
    
        [reference_name] nvarchar(255),
    
        [src_table_name] nvarchar(255),
    
        [src_column_name] nvarchar(255),
    
        [dest_table_name] nvarchar(255),
    
        [dest_column_name] nvarchar(255),
    
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_ReferenceDetail
(
    merge_version_id NVARCHAR(50),
    
        [reference_name] nvarchar(255),
    
        [src_column_name] nvarchar(255),
    
    is_del_master BIT,
    is_del_branch BIT,
    src_table_name_master   nvarchar(255),
    dest_table_name_master   nvarchar(255),
    dest_column_name_master   nvarchar(255),
    src_table_name_branch   nvarchar(255),
    dest_table_name_branch   nvarchar(255),
    dest_column_name_branch   nvarchar(255),
    
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[ReferenceDetail] ADD CONSTRAINT FK_ReferenceDetail_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_ReferenceDetail ADD CONSTRAINT FK_hist_ReferenceDetail_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_ReferenceDetail ADD CONSTRAINT FK_hist_ReferenceDetail_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_ReferenceDetail ADD CONSTRAINT FK_conflicts_ReferenceDetail_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_ReferenceDetail ADD CONSTRAINT FK_conflicts_ReferenceDetail_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)
