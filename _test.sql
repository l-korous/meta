use metaSimple2;

EXEC truncate_repository
GO
EXEC create_version 'master', 'some-v'
EXEC ins_B 'master', 1, '1'
EXEC ins_B 'master', 13, 'a1'
EXEC ins_A 'master', 100, 'aaa', 1, NULL
EXEC ins_A 'master', 200, 'bbb', 1, NULL
EXEC ins_A 'master', 300, 'ccc', 1, NULL
EXEC close_version 'some-v'

EXEC create_branch 'b-1', 'v-1'
EXEC create_branch 'b-2', 'v-2'

EXEC ins_B 'b-1', 2, '2'
EXEC upd_B 'b-1', 13, 'A'
EXEC ins_C 'b-1', '2', '2'
EXEC upd_B 'b-1', 2, 'B'

EXEC merge_branch 'b-1', 'merge-b-1'

EXEC ins_B 'b-2', 3, 'C'
EXEC ins_C 'b-2', 'C', 'C'
EXEC ins_AtC 'b-2', 100, 'C'
exec del_B 'b-2', 1
exec ins_C 'b-2', '2', 'C'

EXEC merge_branch 'b-2', 'merge-b-2'

DECLARE @json NVARCHAR(4000) = N'{"SortBy":{"cA": "ASC", "B_id": "desc"}, "Filter":{"B_id":"%"}}'
EXEC dbo.get 'A', 'master', @json
 
select * from dbo.A order by branch_id;
select * from dbo.hist_A order by branch_id;
select * from dbo.AtC order by branch_id;
select * from dbo.hist_AtC order by branch_id;
select * from dbo.B order by branch_id;
select * from dbo.hist_B order by branch_id;
select * from dbo.B order by branch_id;
select * from dbo.C order by branch_id;
select * from dbo.hist_C order by branch_id;
select * from dbo.conflicts_A;
select * from dbo.conflicts_B;
select * from dbo.conflicts_C;
select * from dbo.conflicts_AtC;
select * from dbo.hist_A order by branch_id, valid_from;
select * from branch;
select * from version;
