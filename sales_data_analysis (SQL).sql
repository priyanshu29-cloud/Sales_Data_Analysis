create database Retail_Sales_Data;
use Retail_Sales_Data;

create table Sales_Data_Transaction (
customer_id varchar(100),
trans_date varchar(100),
trans_amount int
);

load data infile 'C:/Retail_Data_Transactions.csv'
into table Sales_Data_Transaction
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;



create table Sales_Data_Response(
customer_id varchar(100) primary key,
response int
);

load data infile 'C:/Retail_Data_Response.csv'
into table Sales_Data_Response
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;

## Data Cleaning
delete from sales_data_transaction
where customer_id is null or trans_date is null or trans_amount is null;

select count(*) from sales_data_transaction
where customer_id = '' or trans_amount = '';

update sales_data_transaction set trans_date_clean = str_to_date(trans_date , '%d-%b-%y');

/*NO NEED TO REMOVE DUPLICATES FROM THE DATA 
BECAUSE EACH CUSTOMER ID HAS TRANSACTION AMOUNT WITH DIFFRENT DATES */

-- CHANGING DATA TYPE DATE
alter table sales_data_transaction 
add column trans_date_clean date;

-- cleaning dates
update sales_data_transaction set trans_date_clean = 
case
	when trans_date like '%-%' then str_to_date(trans_date , '%d-%m-%y')
    when trans_date like '%/%' then str_to_date(trans_date , '%d-%m-%y')
    when trans_date like '% %' then str_to_date(trans_date , '%d-%m-%y')
    else null
    end;
 

## PHASE 1 (DATA EXPLOREATION EDA)
-- TOTAL CUSTOMERS
create view total_customer as (select count(distinct customer_id) as total_customer
from sales_data_transaction);

-- TOTAL REVENUE
select sum(trans_amount) as revenue from sales_data_transaction;

-- DATE RANGE OF TRANSACTION
select min(trans_date) , max(trans_date) from sales_data_transaction;

## PHASE 2 CUSTOMER & CAMPAIGN ANALYSIS
-- total matching customer_id in both tables
create view matching_IDs as (select count(distinct t.customer_id) as matched_customers
from sales_data_transaction as t
join sales_data_response as r
on t.customer_id = r.customer_id);

-- Finding customer those gave responses is spending more or not
create view responders_spend as (select r.response ,count(r.customer_id) as total_customer, sum(t.trans_amount) as revenue , avg(t.trans_amount) as avg_trans_amount
from sales_data_response as r
join sales_data_transaction as t
on r.customer_id = t.customer_id
group by r.response); 

-- EACH CUSTOMER LIFTIME VALUE (CLV ANALYSIS)
create view total_spend as (select customer_id , count(customer_id) as num_orders , sum(trans_amount) as total_spend
from sales_data_transaction
group by customer_id); 

-- YEARLY REVENUE TREND
create view yearly_trend as (select year(trans_date_clean) as ord_year , count(year(trans_date_clean)) as total_orders , sum(trans_amount) as total_revenue
from sales_data_transaction
group by ord_year
order by ord_year);

-- MONTHLY REVENUE TREND
create view monthly_trend as (select year(trans_date_clean) as ord_year , monthname(trans_date_clean) as ord_month , 
count(month(trans_date_clean)) as total_orders , sum(trans_amount) as total_revenue
from sales_data_transaction
group by ord_year ,ord_month, month(trans_date_clean)
order by ord_year , month(trans_date_clean));

 -- RESPONDERR VS NON-RESPONDERS
 create view responder_vs_non_responsers as (select r.response , round(avg(customer_spend),2) as avg_customer_spending
 from
	(select t.customer_id, sum(t.trans_amount) as customer_spend
    from sales_data_transaction as t
    group by t.customer_id) c 
join sales_data_response as r
on c.customer_id = r.customer_id
group by r.response);

-- PHASE 3 
## Customer Sagmentation
create view customer_sagments as  select customer_id , count(*) as total_ord , sum(trans_amount) as total_spend, max(trans_date_clean) as last_order,
case
	when count(*) > 15 and sum(trans_amount) > 1000 and max(year(trans_date_clean)) >= 2015 then 'Prime'
    when count(*) <= 15 and sum(trans_amount) <= 1000 then 'Mid'
    else 'Low'
    end as Sagmentation
from sales_data_transaction
group by customer_id;

drop view customer_sagments;



select * from customer_sagments;






explain select * from Sales_Data_Transaction where customer_id = 'CS5295';
create index idx_id on Sales_Data_Transaction (customer_id);
explain select * from Sales_Data_Transaction where customer_id = 'CS5295';
