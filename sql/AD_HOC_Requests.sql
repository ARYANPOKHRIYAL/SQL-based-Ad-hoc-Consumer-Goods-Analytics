/*
=========================================================
AD-HOC REQUEST #1: APAC MARKET IDENTIFICATION
=========================================================

Business Request:
Identify all markets where Atliq Exclusive operates
within the APAC region.

Business Objective:
Determine the geographical presence of Atliq Exclusive
across Asia-Pacific markets.

Table Used:
dim_customer

SQL Concepts:
SELECT, DISTINCT, WHERE, AND
=========================================================
*/
SELECT DISTINCT(market)
FROM dim_customer
WHERE customer='Atliq Exclusive'
AND region='APAC';



/*
=========================================================
AD-HOC REQUEST #2: UNIQUE PRODUCT GROWTH
=========================================================

Business Request:
Calculate the percentage increase in unique products
in FY2021 compared with FY2020.

Business Objective:
Measure the growth in the company's product portfolio
between the two fiscal years.

Table Used:
fact_sales_monthly

SQL Concepts:
CTEs, COUNT(DISTINCT), CROSS JOIN, ROUND()
=========================================================
*/
with cte1 as(
	SELECT 
			COUNT(DISTINCT s.product_code) as unique_products_2020
	FROM fact_sales_monthly s
	WHERE fiscal_year= 2020
),
cte2 as(
	SELECT 
			COUNT(DISTINCT s.product_code) as unique_products_2021
	FROM fact_sales_monthly s
	WHERE fiscal_year= 2021
)
SELECT 
		unique_products_2020,
        unique_products_2021,
        ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100, 2) as percentage_chg
FROM cte1
CROSS JOIN cte2;



/*
=========================================================
AD-HOC REQUEST #3: UNIQUE PRODUCTS BY SEGMENT
=========================================================

Business Request:
Provide the unique product count for each segment,
sorted in descending order of product count.

Business Objective:
Understand the distribution of the company's product
portfolio across different segments.

Table Used:
dim_product

SQL Concepts:
COUNT, DISTINCT, GROUP BY, ORDER BY
=========================================================
*/
SELECT
		DISTINCT segment,
        COUNT(product) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;



/*
=========================================================
AD-HOC REQUEST #4: PRODUCT GROWTH BY SEGMENT
=========================================================

Business Request:
Identify which segment had the highest increase in
unique products sold in FY2021 compared with FY2020.

Business Objective:
Compare product growth across segments to identify
the segments experiencing the greatest expansion.

Tables Used:
fact_sales_monthly
dim_product

SQL Concepts:
CTEs, COUNT(DISTINCT), JOIN, GROUP BY, ORDER BY
=========================================================
*/
with cte1 as (
	SELECT 
			segment,
			COUNT(DISTINCT s.product_code) as product_count_2020
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2020
	GROUP BY segment
),
cte2 as (
	SELECT 
			segment,
			COUNT(DISTINCT s.product_code) as product_count_2021
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2021
	GROUP BY segment
)
SELECT 
		*,
		(product_count_2021-product_count_2020) as difference
FROM cte1
JOIN cte2
USING (segment)
ORDER BY difference DESC;



/*
=========================================================
AD-HOC REQUEST #5: HIGHEST AND LOWEST MANUFACTURING COST
=========================================================

Business Request:
Identify the products with the highest and lowest
manufacturing costs.

Business Objective:
Understand the range of manufacturing costs across
the company's product portfolio.

Tables Used:
dim_product
fact_manufacturing_cost

SQL Concepts:
Subqueries, MAX(), MIN(), JOIN, UNION
=========================================================
*/
-- Products with the highest manufacturing cost
SELECT 
		product_code,
        product,
        manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
USING (product_code)
WHERE manufacturing_cost= (
		SELECT MAX(manufacturing_cost) from fact_manufacturing_cost
)
    
UNION

-- Products with the lowest manufacturing cost
SELECT 
		product_code,
        product,
        manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
USING (product_code)
WHERE manufacturing_cost= (
		SELECT MIN(manufacturing_cost) from fact_manufacturing_cost
);



/*
=========================================================
AD-HOC REQUEST #6: TOP 5 CUSTOMERS BY AVERAGE DISCOUNT
=========================================================

Business Request:
Identify the top 5 customers receiving the highest
average pre-invoice discount in India during FY2021.

Business Objective:
Analyze customer-level discount distribution and
identify customers receiving the highest discounts.

Tables Used:
dim_customer
fact_pre_invoice_deductions

SQL Concepts:
INNER JOIN, WHERE, AVG(), GROUP BY, ORDER BY,
LIMIT, ROUND()
=========================================================
*/
SELECT 
		DISTINCT(customer_code),
        customer,
        ROUND(AVG(pre_invoice_discount_pct)*100,2) as avg_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
USING (customer_code)
WHERE fiscal_year= 2021
AND market= "India"
GROUP BY customer_code, customer
ORDER BY avg_discount_pct desc
LIMIT 5;



/*
=========================================================
AD-HOC REQUEST #7: MONTHLY GROSS SALES ANALYSIS
=========================================================

Business Request:
Generate a monthly gross sales report for Atliq Exclusive.

Business Objective:
Identify high-performing and low-performing months
to support strategic sales decisions.

Tables Used:
fact_sales_monthly
fact_gross_price
dim_customer

SQL Concepts:
INNER JOIN, MONTHNAME(), MONTH(), SUM(),
GROUP BY, ORDER BY, ROUND()

Note:
Gross sales are presented in millions.
=========================================================
*/
SELECT 
		MONTHNAME(s.date) as Month,
        s.fiscal_year,
        CONCAT(ROUND(SUM((g.gross_price*s.sold_quantity)/1000000),2),"M") as gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code = g.product_code
AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE customer= "Atliq Exclusive"
GROUP BY Month, fiscal_year
ORDER BY fiscal_year;



/*
=========================================================
AD-HOC REQUEST #8: QUARTERLY SALES QUANTITY ANALYSIS
=========================================================

Business Request:
Identify the quarter with the highest total sold
quantity during FY2020.

Business Objective:
Analyze quarterly sales volume to identify the
highest-performing quarter.

Table Used:
fact_sales_monthly

SQL Concepts:
CTEs, CASE WHEN, MONTH(), SUM(), GROUP BY, ORDER BY

Fiscal Calendar:
Q1: September - November
Q2: December - February
Q3: March - May
Q4: June - August
=========================================================
*/
with cte1 as (
	SELECT 
			MONTH(date) as Month,
			case
				when MONTH(date) in (9,10,11) then "Q1"
				when MONTH(date) in (12,1,2) then "Q2"
				when MONTH(date) in (3,4,5) then "Q3"
				when MONTH(date) in (6,7,8) then "Q4"		
			end as quarter,
			sold_quantity
	FROM fact_sales_monthly s
	where fiscal_year= 2020
),
cte2 as (
	SELECT 
			quarter,
            ROUND(SUM(sold_quantity)/1000000,2) as total_sold_quantity
	FROM cte1
    GROUP BY quarter
)

SELECT * FROM cte2
ORDER BY total_sold_quantity DESC;



/*
=========================================================
AD-HOC REQUEST #9: GROSS SALES BY CHANNEL
=========================================================

Business Request:
Identify which sales channel generated the highest
gross sales in FY2021 and calculate its percentage
contribution to total gross sales.

Business Objective:
Evaluate the contribution of different sales channels
to the company's overall gross sales.

Tables Used:
fact_sales_monthly
fact_gross_price
dim_customer

SQL Concepts:
CTEs, INNER JOIN, SUM(), GROUP BY,
Window Functions, ROUND(), ORDER BY

Note:
Gross sales are presented in millions.
=========================================================
*/
with cte1 as (
	SELECT 
			c.channel,
			SUM(g.gross_price * s.sold_quantity) as gross_sales_mln
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
	ON s.product_code = g.product_code
	JOIN dim_customer c
	ON s.customer_code = c.customer_code
    WHERE s.fiscal_year= 2021
	GROUP BY channel
    ORDER BY gross_sales_mln DESC
)
SELECT
		channel,
        CONCAT(ROUND(gross_sales_mln/1000000,2),"M") as gross_sales_mln,
        CONCAT(ROUND((gross_sales_mln/SUM(gross_sales_mln) OVER()) *100, 2), "%") as percentage
FROM cte1;



/*
=========================================================
AD-HOC REQUEST #10: TOP 3 PRODUCTS BY DIVISION
=========================================================

Business Request:
Identify the top 3 products in each division based
on total sold quantity during FY2021.

Business Objective:
Identify the best-selling products within each division
to understand product demand and sales contribution.

Tables Used:
fact_sales_monthly
dim_product

SQL Concepts:
CTEs, INNER JOIN, SUM(), GROUP BY,
RANK(), PARTITION BY, ORDER BY

Fiscal Year:
2021
=========================================================
*/
with cte1 as (
	SELECT
			p.division,
			p.product_code,
			p.product,
			SUM(s.sold_quantity) as sold_quantity,
            RANK() OVER(PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) as rank_order
	FROM fact_sales_monthly s
	JOIN dim_product p
	USING (product_code)
    WHERE s.fiscal_year= 2021
    GROUP BY p.division, p.product_code, p.product
)

SELECT *
FROM cte1
WHERE rank_order <=3
ORDER BY division, rank_order;
