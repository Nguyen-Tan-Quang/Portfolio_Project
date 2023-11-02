;WITH online_retail AS
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

SELECT
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1
INTO #cohort_retention
FROM
	(
	SELECT
		mm.*,
		Year_diff = Invoice_Year - Cohort_Year,
		Month_diff = Invoice_Month - Cohort_Month
	FROM
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
				ON m.CustomerID = c.CustomerID
			) mm
	)mmm
--where CustomerID = 14733

SELECT * FROM #cohort_retention

SELECT DISTINCT 
		CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohort_retention
ORDER BY 1, 3
--where CustomerID = 14733


---Pivot Data to see the cohort table


SELECT 	*
INTO #cohort_pivot
FROM(
	SELECT 
	DISTINCT 
		CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohort_retention

)tbl
PIVOT(
	COUNT(CustomerID)
	FOR Cohort_Index IN 
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

)AS pivot_table

SELECT *
FROM #cohort_pivot
ORDER BY Cohort_Date

SELECT Cohort_Date ,
	(1.0 * [1]/[1] * 100) AS [1], 
    1.0 * [2]/[1] * 100 AS [2], 
    1.0 * [3]/[1] * 100 AS [3],  
    1.0 * [4]/[1] * 100 AS [4],  
    1.0 * [5]/[1] * 100 AS [5], 
    1.0 * [6]/[1] * 100 AS [6], 
    1.0 * [7]/[1] * 100 AS [7], 
	1.0 * [8]/[1] * 100 AS [8], 
    1.0 * [9]/[1] * 100 AS [9], 
    1.0 * [10]/[1] * 100 AS [10],   
    1.0 * [11]/[1] * 100 AS [11],  
    1.0 * [12]/[1] * 100 AS [12],  
	1.0 * [13]/[1] * 100 AS [13]
FROM #cohort_pivot
ORDER BY Cohort_Date


DECLARE 
    @columns NVARCHAR(MAX) = '',
	@sql     NVARCHAR(MAX) = '';

SELECT 
    @columns += QUOTENAME(cohort_index) + ','
FROM 
    (SELECT DISTINCT cohort_index FROM #cohort_retention) m
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
	  SELECT DISTINCT
		Cohort_Date,
		cohort_index,
		CustomerID 
	  FROM #cohort_retention
) t 
PIVOT(
    COUNT(CustomerID) 
    FOR cohort_index IN ('+ @columns +')
) AS pivot_table
ORDER BY Cohort_Date


';

-- execute the dynamic SQL
EXECUTE sp_executesql @sql;