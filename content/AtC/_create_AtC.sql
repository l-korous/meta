use metaSimple2
CREATE TABLE dbo.AtC
(
    A_sru INT NOT NULL,
    Cid NVARCHAR(255) NOT NULL,
    branch_id NVARCHAR(50),
    PRIMARY KEY (branch_id, A_sru, Cid)
)

CREATE TABLE dbo.hist_AtC
(
    A_sru INT,
    Cid NVARCHAR(255),
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_AtC
(
    merge_version_id NVARCHAR(50),
    A_sru INT,
    Cid NVARCHAR(255),
    is_del_master BIT,
    is_del_branch BIT,
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)

ALTER TABLE dbo.AtC ADD CONSTRAINT FK_AtC_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_AtC ADD CONSTRAINT FK_hist_AtC_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_AtC ADD CONSTRAINT FK_hist_AtC_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_AtC ADD CONSTRAINT FK_conflicts_AtC_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_AtC ADD CONSTRAINT FK_conflicts_AtC_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)