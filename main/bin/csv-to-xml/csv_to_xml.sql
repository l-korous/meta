CREATE TABLE #t (
    table_name nvarchar(max)
)
CREATE TABLE #c (
    column_name nvarchar(max), 
    table_name nvarchar(max), 
    datatype nvarchar(max), 
    is_primary_key nvarchar(max),
    is_unique nvarchar(max),
    is_required nvarchar(max)
)
CREATE TABLE #r (
    reference_name nvarchar(max),
    referencing_table_name nvarchar(max),
    referencing_column_name nvarchar(max),
    referenced_table_name nvarchar(max),
    referenced_column_name nvarchar(max),
    on_delete nvarchar(max) 
); 
CREATE TABLE #conf (
    [key] nvarchar(max),
    value nvarchar(max)
); 

BULK INSERT #t FROM tableCsv WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n'  );
BULK INSERT #c FROM colCsv WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
BULK INSERT #r FROM refCsv WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n'  );
BULK INSERT #conf FROM confCsv WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n'  );

UPDATE #t SET
    table_name = replace(trim(table_name), char(34), '');

UPDATE #c SET
    column_name = replace(trim(column_name), char(34), ''),
    table_name = replace(trim(table_name), char(34), ''),
    datatype =replace(trim(datatype), char(34), ''),
    is_primary_key = replace(trim(is_primary_key), char(34), ''),
    is_unique = replace(trim(is_unique), char(34), ''),
    is_required = replace(trim(is_required), char(34), '');

UPDATE #rd SET
    reference_name = replace(trim(reference_name), char(34), ''),
    referencing_column_name = replace(trim(referencing_column_name), char(34), ''),
    referenced_column_name = replace(trim(referenced_column_name), char(34), ''),
    referencing_table_name = replace(trim(referencing_table_name), char(34), ''),
    referenced_table_name = replace(trim(referenced_table_name), char(34), ''),
    on_delete = replace(trim(on_delete), char(34), '');

UPDATE #conf SET
    [key] = replace(trim([key]), char(34), ''),
    value = replace(trim(value), char(34), '');

SELECT
 ( select
	   *
    FROM 
        #conf [configuration]
    for xml auto, root ('configurations'), type
    ),
    (
    select 
    table_name, 
    ( select
	   column_name,
	   datatype,
	   is_primary_key,
	   is_unique,
	   is_required
    FROM 
        #c [column]
    where
	   [column].table_name = [table].table_name
    for xml auto, root ('columns'), type
    ), 
    ( select
	   reference_name,
	   referencing_column_name,
       referenced_column_name,
       referencing_table_name,
       referenced_table_name
	   on_delete
    FROM 
        #r [reference]
    where
	   [reference].referencing_table_name = [table].table_name
    for xml auto, root ('references'), type
    )
FROM
#t [table]
FOR XML auto, root ('tables'), type
)
FOR XML path('root'), type