CREATE OR REPLACE FUNCTION consistency_checks
(
)
RETURNS INT AS
$$
DECLARE rc int;
DECLARE row_count int;
BEGIN
 perform  * from acc_trans where trans_id in
 ( select trans_id from acc_trans  group by trans_id having sum(amount) <> 0 )
 order by trans_id,transdate;

 GET DIAGNOSTICS row_count = ROW_COUNT;
 if row_count > 0 then
  raise exception 'unbalanced transactions row_count=%',row_count;
 end if;

 rc=0;
 return rc;
END;
$$ LANGUAGE PLPGSQL;
--select consistency_checks from consistency_checks();

