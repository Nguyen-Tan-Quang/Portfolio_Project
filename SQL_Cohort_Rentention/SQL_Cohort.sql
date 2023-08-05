;with online_retail AS
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [PortfolioProject].[dbo].[Retail]
	  WHERE CustomerID != 0
)
--SELECT * FROM online_retail
, quantity_unit_price AS 
(

	---397882 records with quantity and Unit price
	SELECT *
	FROM online_retail
	WHERE Quantity > 0 and UnitPrice > 0
)
--SELECT * FROM quantity_unit_price
, dup_check AS
(
	---duplicate check
	SELECT * , ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) AS dup_flag
	FROM quantity_unit_price

)
--SELECT * FROM dup_check

---392667 Clean Data
---4827 duplicate records
SELECT * 
INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1

SELECT * 
FROM #online_retail_main

--Unique Identifier (CustomerID)
--Initial Start Date (First Invoice Date)
--Revenue Data

SELECT	CustomerID, 
		MIN(InvoiceDate) First_Purchase_Date,
		DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) Cohort_Date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID


SELECT * FROM #cohort

select
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1
into #cohort_retention
from
	(
	select
		mm.*,
		Year_diff = Invoice_Year - Cohort_Year,
		Month_diff = Invoice_Month - Cohort_Month
	from
		(
			SELECT 
				m.*,
				c.Cohort_Date,
				YEAR(m.InvoiceDate)  Invoice_Year,
				MONTH(m.InvoiceDate) Invoice_Month,
				YEAR(c.Cohort_Date)  Cohort_Year,
				MONTH(c.Cohort_Date) Cohort_Month
			FROM #online_retail_main m
			LEFT JOIN #cohort c
				on m.CustomerID = c.CustomerID
			) mm
	)mmm
--where CustomerID = 14733

SELECT * FROM #cohort_retention

select distinct 
		CustomerID,
		Cohort_Date,
		cohort_index
	from #cohort_retention
order by 1, 3
--where CustomerID = 14733


---Pivot Data to see the cohort table


select 	*
into #cohort_pivot
from(
	select 
	distinct 
		CustomerID,
		Cohort_Date,
		cohort_index
	from #cohort_retention

)tbl
pivot(
	Count(CustomerID)
	for Cohort_Index In 
		(
		[1], 
        [2], 
        [3], 
        [4], 
        [5], 
        [6], 
        [7],
		[8], 
        [9], 
        [10], 
        [11], 
        [12],
		[13])

)as pivot_table

select *
from #cohort_pivot
order by Cohort_Date

select Cohort_Date ,
	(1.0 * [1]/[1] * 100) as [1], 
    1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot
order by Cohort_Date

--Trong truy vấn SQL của bạn, 
--việc nhân 1.0 với các số trong phép tính (1.0 * [1] / [1] * 100)
--là một cách để đảm bảo rằng kết quả của phép chia 
--là một số thực (float) chứ không phải là số nguyên (integer).

DECLARE 
    @columns NVARCHAR(MAX) = '',
	@sql     NVARCHAR(MAX) = '';

SELECT 
    @columns += QUOTENAME(cohort_index) + ','
FROM 
    (select distinct cohort_index from #cohort_retention) m
ORDER BY 
    cohort_index;

SET @columns = LEFT(@columns, LEN(@columns) - 1);

PRINT @columns;


-- construct dynamic SQL
SET @sql ='

---# Return number of unique elements in the object
SELECT * 
FROM   
(
	  select distinct
		Cohort_Date,
		cohort_index,
		CustomerID 
	  from #cohort_retention
) t 
PIVOT(
    COUNT(CustomerID) 
    FOR cohort_index IN ('+ @columns +')
) AS pivot_table
order by Cohort_Date


';

-- execute the dynamic SQL
EXECUTE sp_executesql @sql;