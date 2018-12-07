use metaSimple2

CREATE TABLE dbo.C
(
    _123 NVARCHAR(255) NOT NULL,
    _4 NVARCHAR(255) NOT NULL,
    branch_id NVARCHAR(50),
    PRIMARY KEY (_123, branch_id)
)

CREATE TABLE dbo.hist_C
(
    _123 NVARCHAR(255),
    _4 NVARCHAR(255),
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_C
(
    merge_version_id NVARCHAR(50),
    _123 NVARCHAR(255),
    is_del_master BIT,
    is_del_branch BIT,
    _4_master NVARCHAR(255),
    _4_branch NVARCHAR(255),
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)

ALTER TABLE dbo.C ADD CONSTRAINT FK_C_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_C ADD CONSTRAINT FK_hist_C_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_C ADD CONSTRAINT FK_hist_C_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_C ADD CONSTRAINT FK_conflicts_C_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_C ADD CONSTRAINT FK_conflicts_C_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)