drop table if exists stage_own.fin_txn_b;

create table stage_own.fin_txn_b(
batch_identifier integer not null,
source character varying(10),
customer_id	character varying,
txn_date date,
credit_debit_ind char(1),
txn_amount numeric
);
