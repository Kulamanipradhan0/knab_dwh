-- DNB Report Query from EOD Position Table using as_of_date=(last day of the year﻿)
SELECT Extract(year FROM as_of_date) AS "Year", 
       c.bsn_number, 
       c.full_name                   AS "Customer name", 
       Sum(closing_balance)          "Closing Balance", 
       CASE 
         WHEN ( Sum(closing_balance) ) >= 100000 THEN 100000 
         ELSE Sum(closing_balance) 
       END                           "Pay Out Amount" 
FROM   dwh_own.fac_dwh_eod_position p 
       JOIN dwh_own.dim_account a 
         ON a.account_key = p.account_key 
       JOIN dwh_own.dim_customer c 
         ON p.customer_key = c.customer_key 
where p.as_of_date=
(select max(date_key) from dwh_own.dim_calendar_date where year=(select Extract(year from now())-1) and week_end='Weekday' and holiday='No holiday')
GROUP  BY Extract(year FROM as_of_date), 
          c.bsn_number, 
          c.full_name 
ORDER  BY Extract(year FROM as_of_date), 
          c.bsn_number, 
          c.full_name ASC ;


-- DNB Control Report Query from Account Balance sent by Source to compare with Above result query. Both should match as it is.


SELECT Extract(year FROM as_of_date) AS "Year", 
       c.bsn_number, 
       c.full_name                   AS "Customer name", 
       Sum(closing_balance)          "Closing Balance", 
       CASE 
         WHEN ( Sum(closing_balance) ) >= 100000 THEN 100000 
         ELSE Sum(closing_balance) 
       END                           "Pay Out Amount" 
FROM   dwh_own.fac_acc_balance b
       JOIN dwh_own.dim_account a 
         ON a.account_key = b.account_key 
       JOIN dwh_own.dim_customer c 
         ON b.customer_key = c.customer_key 
where b.as_of_date=
(select max(date_key) from dwh_own.dim_calendar_date where year=(select Extract(year from now())-1) and week_end='Weekday' and holiday='No holiday')
GROUP  BY Extract(year FROM as_of_date), 
          c.bsn_number, 
          c.full_name 
ORDER  BY Extract(year FROM as_of_date), 
          c.bsn_number, 
          c.full_name ASC ;

                
