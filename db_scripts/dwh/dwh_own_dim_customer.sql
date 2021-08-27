drop table if exists dwh_own.dim_customer CASCADE;

create table dwh_own.dim_customer(
customer_key	bigserial not null,
batch_identifier integer not null,
effective_start_date date not null ,
effective_end_date date default '9999-12-31'::date not null,
insert_datetime timestamp without time zone  not null,
last_update_datetime timestamp without time zone  not null,
active_flag char(1) default 'Y' not null,
customer_id character varying(100) not null,
full_name character varying(500),
address character varying,
CONSTRAINT dim_customer_pkey PRIMARY KEY (customer_key)
);

create index dim_customer_ix_01 on dwh_own.dim_customer (active_flag,customer_id);

create index dim_customer_ix_02 on dwh_own.dim_customer (effective_start_date,effective_end_date,customer_id);
