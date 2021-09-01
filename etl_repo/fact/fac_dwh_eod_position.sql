BEGIN ; 

--Load Fac Account Balance daily Snapshot table

-- 1. Find EOD Position from today's transactions
drop table if exists today_position;

create temp table today_position as
SELECT 
       account_key, 
	customer_key, 
       txn_date                                                          AS 
       as_of_date, 
       SUM(CASE 
             WHEN txn_rank_asc = 1 THEN opening_balance 
             ELSE 0 
           END) 
       opening_balance, 
       SUM(CASE 
             WHEN txn_rank_desc = 1 THEN current_balance 
             ELSE 0 
           END) 
       closing_balance, 
       batch_identifier, 
       To_char(current_timestamp, 'yyyy-mm-dd hh:mi:ss.ms') :: timestamp AS 
       insert_datetime 
FROM   ((SELECT da.account_key, 
                dc.customer_key, 
                t.txn_date, 
                t.credited_amount, 
                t.debited_amount, 
                current_balance, 
                CASE 
                  WHEN credited_amount = 0 THEN 
                  t.current_balance + debited_amount 
                  ELSE t.current_balance - credited_amount 
                END                                    opening_balance, 
                t.txn_datetime_full, 
                Rank() 
                  over( 
                    PARTITION BY t.customer_key, t.account_key 
                    ORDER BY t.txn_datetime_full)      AS txn_rank_asc, 
                Rank() 
                  over( 
                    PARTITION BY t.customer_key, t.account_key 
                    ORDER BY t.txn_datetime_full DESC) AS txn_rank_desc, 
                t.batch_identifier 
         FROM   dwh_own.fac_fin_transaction t 
                left join dwh_own.dim_account da 
                       ON t.account_key = da.account_key 
                          AND da.active_flag = 'Y' 
                left join dwh_own.dim_customer dc 
                       ON t.customer_key = dc.customer_key 
                          AND dc.active_flag = 'Y' 
	where t.txn_date=:p_bsdate --Variable from script
         ORDER  BY t.customer_key, 
                   t.account_key, 
                   t.txn_datetime_full ASC))main 
WHERE  ( txn_rank_asc = 1 
          OR txn_rank_desc = 1 ) 
GROUP  BY customer_key, 
          account_key, 
          txn_date, 
          batch_identifier 
ORDER  BY 
          account_key, customer_key, 
          txn_date; 

--2. Insert Today's updated positions
INSERT INTO dwh_own.fac_dwh_eod_position 
            (account_key, 
             customer_key, 
             as_of_date, 
             opening_balance, 
             closing_balance, 
             batch_identifier, 
             insert_datetime) 
(SELECT * FROM   today_position);


--2. Insert Previous day's active customers and accounts , who didn't perform any transaction today

INSERT INTO dwh_own.fac_dwh_eod_position 
            (account_key, 
             customer_key, 
             as_of_date, 
             opening_balance, 
             closing_balance, 
             batch_identifier, 
             insert_datetime) 
WITH src 
     AS (SELECT * 
         FROM   today_position), 
     tgt 
     AS (SELECT p.customer_key, 
                p.account_key, 
                c.customer_id, 
                a.account_no, 
                :p_bsdate:: DATE as_of_date, --Variable from script
                opening_balance, 
                closing_balance, 
                p.batch_identifier 
         FROM   dwh_own.fac_dwh_eod_position p 
                join dwh_own.dim_customer c 
                  ON c.customer_key = p.customer_key 
                join dwh_own.dim_account a 
                  ON a.account_key = p.account_key 
         WHERE  as_of_date = ((SELECT Max(date_key) previous_bsdate 
                               FROM   dwh_own.dim_calendar_date 
                               WHERE  date_key < :p_bsdate --Variable from script
                                      AND week_end = 'Weekday' 
                                      AND holiday = 'No holiday'))) 
SELECT a.account_key, 
       c.customer_key, 
       tgt.as_of_date, 
       tgt.closing_balance, 
       tgt.closing_balance, 
       tgt.batch_identifier, 
       To_char(current_timestamp, 'yyyy-mm-dd hh:mi:ss.ms') :: timestamp AS 
       insert_datetime 
FROM   src 
       full outer join tgt 
                    ON src.customer_key = tgt.customer_key 
                       AND src.account_key = tgt.account_key 
       join dwh_own.dim_customer c 
         ON c.customer_id = tgt.customer_id 
            AND c.active_flag = 'Y' 
       join dwh_own.dim_account a 
         ON a.account_no = tgt.account_no 
            AND a.active_flag = 'Y' 
WHERE  src.customer_key IS NULL; 

END;
