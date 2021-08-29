INSERT INTO auditing_own.batch_information(
            batch_identifier, batch_name, environment, business_date, batch_version, 
            batch_success_flag, batch_start_time, batch_end_time, batch_status, 
            monthly_batch_flag)
    VALUES ((select coalesce(max(batch_identifier),0)+1 from auditing_own.batch_information ), 'KNAB_DWH', 'PROD', 20210828, 
    (select coalesce(max(batch_version),0)+1 from auditing_own.batch_information where business_date= 20210828), 
            'S', now(), null, 'Started', 
            'N');