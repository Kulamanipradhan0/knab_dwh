drop table if exists stage_own.crm_a;

create table stage_own.crm_a(
batch_identifier integer not null,
source character varying(10),
customer_id	character varying,
first_name character varying,
last_name character varying,
lgl_housenumber character varying,
lgl_street character varying,
lgl_postcode character varying
);
