use metaSimple2

CREATE TABLE dbo.B
(
    id INT NOT NULL,
    [select] NVARCHAR(255) NOT NULL,
    branch_id NVARCHAR(50),
    PRIMARY KEY (id, branch_id)
)

CREATE TABLE dbo.hist_B
(
    id INT,
    [select] NVARCHAR(255),
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_B
(
    merge_version_id NVARCHAR(50),
    id INT,
    is_del_master BIT,
    is_del_branch BIT,
    select_master NVARCHAR(255),
    select_branch NVARCHAR(255),
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)

ALTER TABLE dbo.B ADD CONSTRAINT FK_B_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.B ADD CONSTRAINT UC_B_select UNIQUE NONCLUSTERED ([select], branch_id)
ALTER TABLE dbo.hist_B ADD CONSTRAINT FK_hist_B_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_B ADD CONSTRAINT FK_hist_B_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_B ADD CONSTRAINT FK_conflicts_B_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_B ADD CONSTRAINT FK_conflicts_B_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)