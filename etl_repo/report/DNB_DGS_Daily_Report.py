import pandas as pd,sys,datetime
from config import connection
import pandas.io.sql as psql
as_of_date=sys.argv[1]

cursor = connection.stage.cursor()
dwh=connection.stage
report_name='DNB_Deposito Garantie Stelsel_'+as_of_date
report_query='''SELECT as_of_date AS "As Of", 
       c.bsn_number AS "Social Security Number", 
       c.full_name                   AS "Customer name", 
       Sum(closing_balance)          "Closing Balance", 
       CASE 
         WHEN ( Sum(closing_balance) ) >= 100000 THEN 100000 
         ELSE Sum(closing_balance) 
       END                           "Pay Out Amount" ,
       'EUR' AS "Currency"
FROM   dwh_own.fac_dwh_eod_position p 
       JOIN dwh_own.dim_account a 
         ON a.account_key = p.account_key 
       JOIN dwh_own.dim_customer c 
         ON p.customer_key = c.customer_key 
where p.as_of_date='''+"'"+as_of_date+"'"+'''
GROUP  BY as_of_date, 
          c.bsn_number, 
          c.full_name 
ORDER  BY Extract(year FROM as_of_date), 
          c.bsn_number, 
          c.full_name ASC ;'''

now = datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S")
dataframe = psql.read_sql(report_query, dwh)
total_customer=str(dataframe["Social Security Number"].count())
total_closing_balance=str(dataframe["Closing Balance"].sum())
total_pay_out_amount=str(dataframe["Pay Out Amount"].sum())

summary_dataframe=pd.DataFrame([['Report Generation Time : ',now],['Total Customer : ',total_customer],['Total Closing Balance :',total_closing_balance],['Total Pay Out Amount :',total_pay_out_amount]])

dataframe.to_csv(report_name+'.csv', sep='\t', mode='w', header=True, index=False)

#Set destination directory to save excel.
xlsFilepath = report_name+'.xlsx'


#Write excel to file using pandas to_excel

writer = pd.ExcelWriter(xlsFilepath, engine='xlsxwriter')
dataframe.to_excel(writer, startrow = 12, sheet_name='KNAB_DSL', index=False)

#Indicate workbook and worksheet for formatting
workbook = writer.book
worksheet = writer.sheets['KNAB_DSL']

#Iterate through each column and set the width == the max length in that column. A padding length of 2 is also added.
for i, col in enumerate(dataframe.columns):
    column_len = dataframe[col].astype(str).str.len().max()
    column_len = max(column_len, len(col)) + 2
    worksheet.set_column(i, i, column_len)

summary_dataframe.to_excel(writer, startrow = 5,  sheet_name='KNAB_DSL', index=False)
#Iterate through each column and set the width == the max length in that column. A padding length of 2 is also added.
for i, col in enumerate(summary_dataframe.columns):
    column_len = summary_dataframe[col].astype(str).str.len().max()
    column_len = max(column_len, len(str(col))) + 2
    worksheet.set_column(i, i, column_len)


#Format for Merged Cells
worksheet.set_column('B:B', 25)

# Create a format to use in the merged range.
merge_format = workbook.add_format({
    'bold': 1,
    'border': 1,
    'align': 'center',
    'valign': 'vcenter',
    'fg_color': '#32a89d'})
merge_format.set_font_color('white')
worksheet.merge_range('A1:F2', 'KNAB - DNB Deposito Garantie Stelsel Report', merge_format)



writer.save()

print('Report Successfully Generated for Year : ',as_of_date)
