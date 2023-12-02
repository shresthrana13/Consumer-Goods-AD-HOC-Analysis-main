#1
SELECT  distinct market from dim_customer
where customer like '%Atliq Exclusive%' and region = 'APAC';

#2  
with
 table_2020  as (SELECT count(distinct(product_Code))as unique_products_2020 FROM gdb023.fact_sales_monthly where fiscal_year=2020),
 table_2021 as (SELECT count(distinct(product_Code)) as unique_products_2021 FROM gdb023.fact_sales_monthly where fiscal_year=2021)
select *,(unique_products_2021 - unique_products_2020)*100/(unique_products_2020) as percentage_chg from table_2020,table_2021;
 
#3 
select segment,count(product_Code) as product_count from dim_product
group by segment 
order by product_count desc;

#4
with
 table_2020  as 
 (SELECT segment, count(distinct(product_Code))as unique_products_2020 FROM gdb023.fact_sales_monthly
 join dim_product using(product_code) where fiscal_year=2020
 group by segment),
 table_2021 as (
 SELECT segment, count(distinct(product_Code))as unique_products_2021 FROM gdb023.fact_sales_monthly
 join dim_product using(product_code) where fiscal_year=2021
 group by segment)
select segment,unique_products_2020,unique_products_2021,(unique_products_2021-unique_products_2020) as difference from table_2020 join table_2021
using(segment) order by difference desc;

#5
SELECT product_code,product,manufacturing_cost FROM gdb023.fact_manufacturing_cost mc 
join dim_product using(product_code) where manufacturing_cost
in ((select max(manufacturing_cost) from fact_manufacturing_cost),(select min(manufacturing_cost) from fact_manufacturing_cost)) 
order by manufacturing_cost desc;

#6
SELECT customer_code,dc.customer,round(
    avg(pre_invoice_discount_pct)*100, 
    2) as average_discount_percentage  FROM fact_pre_invoice_deductions fp
join
dim_customer dc using(customer_Code)
where fiscal_year =2021
and market ="India" 
group by customer_Code
order by pre_invoice_discount_pct desc limit 5;

#7
with cte_1 as (SELECT customer_Code,date,product_Code,sold_quantity,fiscal_year FROM gdb023.fact_sales_monthly join 
dim_Customer using(customer_Code)
where customer = 'Atliq Exclusive')

select CONCAT(MONTHNAME(date),',' , YEAR(date)) as Month,ct.fiscal_year,sum((sold_quantity*gross_price))as gross_Sales_amount from cte_1 ct join
fact_gross_price gp on ct.product_Code = gp.product_code 
group by date,ct.fiscal_year
order by DATE;

#8
with cte_1 as (SELECT month(DATE)AS Month,sum(sold_quantity) AS total_sold_quantity FROM gdb023.fact_sales_monthly
where fiscal_year=2020
group by date),
cte_2 as (select case 
when Month in (9,10,11) then "QTR1"
WHEN MONTH IN (12,1,2) then "QTR2"
WHEN MONTH IN (3,4,5) then "QTR3"
ELSE "QTR4"
END AS QUATER ,total_sold_quantity from cte_1)
select QUATER,SUM(total_Sold_quantity) as TOTAL_SOLD_QUANTITY from cte_2 group by quater order by TOTAL_SOLD_QUANTITY desc;

#9
with cte_1 as (SELECT channel,round(sum(sold_quantity*gross_price)/1000000,2) as total_gross_price_mln FROM gdb023.fact_sales_monthly fs
JOIN fact_gross_price gp on fs.product_Code = gp.product_code
join dim_Customer c on fs.customer_code=c.customer_code
where fs.fiscal_year=2021
group by channel)

select * ,round(( total_gross_price_mln)*100/sum( total_gross_price_mln) over(),2) as percentage from cte_1 order by percentage desc;

#10
with cte_1 as (SELECT division,fs.product_Code,product,sum(sold_quantity) as total_Sold_quantity FROM gdb023.fact_sales_monthly fs
join dim_product dp on fs.product_code=dp.product_Code
where fs.fiscal_year=2021
group by fs.product_code),
cte_2 as (select *,dense_rank() over(partition by division order by total_Sold_quantity desc ) as rank_order from cte_1 )
select * from cte_2 where rank_order<=3