# 702-group-project

This project was completed by Group 9 of class BUSINFO 702, Cohort 6.

## Final Written report
To access the final written report, see the file *702 final report.pdf*

## Codebase
The codebase of the project is in the folder 'src' from this root directory.

You may manually execute the ETL code to recreate the data warehouse from scratch, following these steps:
1. Open *1--ETL.sql* in DB Browser
2. Execute line 1-111
3. For each raw staging table, use DB Browser's IMPORT function and import the corresponding dataset (e.g. internet_usage.csv to stg_internet_usage_raw).
-- Go to 'Browse Data' & select the corresponding raw staging table, then File > Import > Table from CSV file..., check "Column names in first line" in the import wizard
4. Execute the rest of the SQL script

NOTE1: Alternatively, uncomment line 20, 39, 87, 99 and run the SQL script in a SQLite CLI

NOTE2: Another method is to load the *702-group-pj.db* file directly into DB Browser or SQLite CLI for a pre-built data warehouse.

Once the data warehouse is loaded, queries in the script *2--business-analytics-queries.sql* may be performed.