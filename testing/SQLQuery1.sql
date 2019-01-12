use meta3
exec meta.truncate_repository
exec meta.create_version 'asdf'
exec dbo.bulk_insert_csv_Table 'b:\sw\meta\testing\tables.csv'
exec dbo.bulk_insert_csv_Column 'b:\sw\meta\testing\cols.csv'