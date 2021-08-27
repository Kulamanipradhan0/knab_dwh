

create table dwh_own.fac_fin_transaction(
customer_key	bigint REFERENCES dwh_own.dim_customer,
txn_date integer REFERENCES dwh_own.dim_calendar_date,
credit_debit_key integer ,
batch_identifier integer not null,
insert_datetime timestamp without time zone default To_char(CURRENT_TIMESTAMP, 'yyyy-mm-dd hh:mi:ss.ms') ::timestamp not null,
current_balance numeric, 
CONSTRAINT fac_fin_transaction_pkey PRIMARY KEY (customer_key,txn_date,credit_debit_key)
);

create index fac_fin_transaction_ix_01 on dwh_own.fac_fin_transaction (batch_identifier);

--select dwh_own.fn_create_yearmonth_auto_partition('dwh_own','fac_fin_transaction','txn_date','pg_default');
