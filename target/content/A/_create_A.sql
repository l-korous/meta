use metaSimple2

CREATE TABLE dbo.A
(
    id INT NOT NULL,
    cA NVARCHAR(255),
    B_id INT NOT NULL,
    this_is_my_column_name FLOAT,
    branch_id NVARCHAR(50),
    PRIMARY KEY (id, branch_id)
)

CREATE TABLE dbo.hist_A
(
    id INT,
    cA NVARCHAR(255),
    B_id INT,
    this_is_my_column_name FLOAT,
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_A
(
    merge_version_id NVARCHAR(50),
    id INT,
    is_del_master BIT,
    is_del_branch BIT,
    cA_master NVARCHAR(255),
    B_id_master INT,
    this_is_my_column_name_master FLOAT,
    cA_branch NVARCHAR(255),
    B_id_branch INT,
    this_is_my_column_name_branch FLOAT,
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)

ALTER TABLE dbo.A ADD CONSTRAINT FK_A_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_A ADD CONSTRAINT FK_hist_A_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_A ADD CONSTRAINT FK_hist_A_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_A ADD CONSTRAINT FK_conflicts_A_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_A ADD CONSTRAINT FK_conflicts_A_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)