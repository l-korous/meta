
    
use meta3
    CREATE TABLE dbo.A
    (
         id INT,
         cA NVARCHAR(255),
         B_id INT,
         this_is_my_column_name FLOAT,
        
        branch_id NVARCHAR(50),
        PRIMARY KEY (
         id,
        
            branch_id
        )
    )

    ALTER TABLE dbo.A ADD CONSTRAINT FK_A_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_A ADD CONSTRAINT FK_hist_A_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_A ADD CONSTRAINT FK_hist_A_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_A ADD CONSTRAINT FK_conflicts_A_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_A ADD CONSTRAINT FK_conflicts_A_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

    CREATE TABLE dbo.AtC
    (
         A_sru INT,
         Cid NVARCHAR(255),
        
        branch_id NVARCHAR(50),
        PRIMARY KEY (
         A_sru,
         Cid,
        
            branch_id
        )
    )

    ALTER TABLE dbo.AtC ADD CONSTRAINT FK_AtC_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_AtC ADD CONSTRAINT FK_hist_AtC_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_AtC ADD CONSTRAINT FK_hist_AtC_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_AtC ADD CONSTRAINT FK_conflicts_AtC_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_AtC ADD CONSTRAINT FK_conflicts_AtC_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

    CREATE TABLE dbo.B
    (
         id INT,
         select NVARCHAR(255),
        
        branch_id NVARCHAR(50),
        PRIMARY KEY (
         id,
        
            branch_id
        )
    )

    ALTER TABLE dbo.B ADD CONSTRAINT FK_B_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_B ADD CONSTRAINT FK_hist_B_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_B ADD CONSTRAINT FK_hist_B_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_B ADD CONSTRAINT FK_conflicts_B_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_B ADD CONSTRAINT FK_conflicts_B_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)

    CREATE TABLE dbo.C
    (
         _123 NVARCHAR(255),
         _4 NVARCHAR(255),
        
        branch_id NVARCHAR(50),
        PRIMARY KEY (
         _123,
        
            branch_id
        )
    )

    ALTER TABLE dbo.C ADD CONSTRAINT FK_C_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_C ADD CONSTRAINT FK_hist_C_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_C ADD CONSTRAINT FK_hist_C_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_C ADD CONSTRAINT FK_conflicts_C_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_C ADD CONSTRAINT FK_conflicts_C_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)
