select [table].[Table name] table_name,
	(
		select [Column name] column_name,
		case
		  when [Foreign key   DQ Requirement] is null then ''
		  else replace(left([Foreign key   DQ Requirement], charindex('.', [Foreign key   DQ Requirement])), '.','')
		end referenced_table_name,
		case
		  when [Foreign key   DQ Requirement] is null then ''
		  else replace(right([Foreign key   DQ Requirement], len([Foreign key   DQ Requirement]) - charindex('.', [Foreign key   DQ Requirement])), '.','')
		end referenced_column_name,
		case [Domain type]
		  when 'D_KEY' then 'int'
		  when 'D_AMOUNT' then 'float'
		  when 'D_COUNT' then 'int'
		  when 'D_DATE' then 'date'
		  when 'D_FLAG' then 'boolean'
		  when 'D_LONG_STRING' then 'long_string'
		  when 'D_SHORT_STRING' then 'string'
	     end datatype,
		case [Nullable]
		  when 'N' then '1'
		  when 'Y' then '0'
	     end is_required,
		case [PK]
		  when 'N' then '0'
		  when 'Y' then '1'
	     end is_primary_key
		from dbo.[model] [column]
		where
			[column].[Table name] = [table].[Table name]
		for xml auto, type, root('columns')
	)
from
	(select distinct [Table name] from dbo.[model]) [table]
for xml auto, root ('tables')