---Inspecting Data
SELECT * FROM [PortfolioProject].[dbo].[sales_data]

--CHecking unique values
SELECT DISTINCT status FROM [PortfolioProject].[dbo].[sales_data] --Nice one to plot
SELECT DISTINCT year_id FROM [PortfolioProject].[dbo].[sales_data]
SELECT DISTINCT PRODUCTLINE FROM [PortfolioProject].[dbo].[sales_data] ---Nice to plot
SELECT DISTINCT COUNTRY FROM [PortfolioProject].[dbo].[sales_data] ---Nice to plot
SELECT DISTINCT DEALSIZE FROM [PortfolioProject].[dbo].[sales_data] ---Nice to plot
SELECT DISTINCT TERRITORY FROM [PortfolioProject].[dbo].[sales_data] ---Nice to plot

SELECT DISTINCT MONTH_ID FROM [PortfolioProject].[dbo].[sales_data]
WHERE year_id = 2003

---ANALYSIS
----Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

SELECT YEAR_ID, SUM(sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data]
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT  DEALSIZE,  SUM(sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data]
GROUP BY  DEALSIZE
ORDER BY 2 DESC

----What was the best month for sales in a specific year? How much was earned that month? 
SELECT  MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
FROM [PortfolioProject].[dbo].[sales_data]
WHERE YEAR_ID = 2004 --change year to see the rest
GROUP BY  MONTH_ID
ORDER BY 2 DESC

--November seems to be the month, what product do they sell in November, Classic I believe
SELECT  MONTH_ID, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER)Frequency
FROM [PortfolioProject].[dbo].[sales_data]
WHERE YEAR_ID = 2004 
AND MONTH_ID = 11 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

DROP TABLE IF EXISTS #rfm
;WITH rfm AS 
(
	SELECT 
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM [PortfolioProject].[dbo].[sales_data]) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [PortfolioProject].[dbo].[sales_data])) Recency
	FROM [PortfolioProject].[dbo].[sales_data]
	GROUP BY CUSTOMERNAME
),rfm_calc AS
(

	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM rfm r
)SELECT 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary  AS varchar)rfm_cell_string
into #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
		ELSE 'not_segmented'
	END AS rfm_segment
FROM #rfm