import pandas as pd,sys
from config import connection
import pandas.io.sql as psql
as_of_date=sys.argv[1]

cursor = connection.stage.cursor()
dwh=connection.stage
report_name='DNB_Deposito Garantie Stelsel_'+as_of_date[:4]
report_query='''select txn_year as "Year", bsn_number as "Social Security Number",full_name as "Customer name",sum(current_balance) "Closing Balance" ,
                case when sum(current_balance)>=100000 then 100000 else sum(current_balance) end "Pay Out Amount" 
                from (
                    select txn_datetime_full,rank() over (partition by t.account_key,t.customer_key order by txn_datetime_full desc),a.account_no, extract (year from t.txn_date) txn_year,
                    c.bsn_number,c.full_name,t.current_balance 
                    from dwh_own.fac_fin_transaction t
                    join dwh_own.dim_account a on a.account_key=t.account_key
                    join dwh_own.dim_customer c on t.customer_key=c.customer_key
                    where t.txn_date='''+"'"+as_of_date+"'"+'''
                )main where rank=1
                group by main.txn_year,main.bsn_number,main.full_name
                order by main.txn_year,main.bsn_number,main.full_name'''

dataframe = psql.read_sql(report_query, dwh)
total_customer=str(dataframe["Social Security Number"].count())
total_closing_balance=str(dataframe["Closing Balance"].sum())
total_pay_out_amount=str(dataframe["Pay Out Amount"].sum())

summary_dataframe=pd.DataFrame([['Total Customer : ',total_customer],['Total Closing Balance :',total_closing_balance],['Total Pay Out Amount :',total_pay_out_amount]])

dataframe.to_csv(report_name+'.csv', sep='\t', mode='a', header=True, index=False)

#Set destination directory to save excel.
xlsFilepath = report_name+'.xlsx'


#Write excel to file using pandas to_excel

writer = pd.ExcelWriter(xlsFilepath, engine='xlsxwriter')
dataframe.to_excel(writer, startrow = 6, sheet_name='KNAB_DSL', index=False)

#Indicate workbook and worksheet for formatting
workbook = writer.book
worksheet = writer.sheets['KNAB_DSL']

#Iterate through each column and set the width == the max length in that column. A padding length of 2 is also added.
for i, col in enumerate(dataframe.columns):
    column_len = dataframe[col].astype(str).str.len().max()
    column_len = max(column_len, len(col)) + 2
    worksheet.set_column(i, i, column_len)

summary_dataframe.to_excel(writer, startrow = 1, sheet_name='KNAB_DSL', index=False)
#Iterate through each column and set the width == the max length in that column. A padding length of 2 is also added.
for i, col in enumerate(summary_dataframe.columns):
    column_len = summary_dataframe[col].astype(str).str.len().max()
    column_len = max(column_len, len(str(col))) + 2
    worksheet.set_column(i, i, column_len)

writer.save()

print('Report Successfully Generated for As Of Date : ',as_of_date)
