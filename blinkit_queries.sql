-- 1. What percentage of orders are delayed, and what are the most common reasons for the delays?
select (select 
count (case when delivery_status != 'On Time' then 1 end)*100/count(*) as 'percentage of delayed order',
from blinkit_delivery_performance
) as '% of delayed orders' ,

reasons_if_delayed as 'most common reason'

from blinkit_delivery_performance
where delivery_status != 'On Time'
group by reasons_if_delayed
order by count(reasons_if_delayed) desc
limit 1

-- 2. Do delayed orders get lower customer ratings than on-time orders? Show the average rating and the number of orders for each delivery status.
select
p.delivery_status,
count(p.order_id),
round(avg(f.rating),2)
from blinkit_delivery_performance as p
inner join blinkit_customer_feedback as f
on p.order_id = f.order_id
group by p.delivery_status

-- 3. Does delivery distance affect the delay rate? Group orders into distance ranges and show the number of orders and the percentage delayed for each range.
select 
    case 
        when distance_km <= 1 then '0 - 1 km'
        when distance_km > 1 and distance_km <= 3 then '1 - 3 km'
        when distance_km > 3 and distance_km <= 5 then '3 - 5 km'
        else '10+ km'
    end as distance_range,
    count(*) as total_orders,
    count(case when delivery_status != 'On Time' then 1 end) as 'delayed_order',
    round(count(case when delivery_status != 'On Time' then 1 end)*100/count(*),2) as '% delayed orders'
from blinkit_delivery_performance
group by distance_range
order by min(distance_km);



-- 4. Which hours of the day have the highest delay rate? Show the number of orders and the percentage delayed for each hour of the order.
select  
hour(promised_time) as 'Hour',
count(case when delivery_status != 'On Time' then 1 end) as 'delayed_order_count',
count(*) as 'total_order_count',

round(count(case when delivery_status != 'On Time' then 1 end)*100/
count(*),2) as '% of delayed orders'

from blinkit_delivery_performance
group by hour(promised_time)

-- 5. total order and total revenue for each customer segment
select
customer_segment,
sum(total_orders) as 'total orders',
round(sum(avg_order_value),2) as 'total revenue'
from blinkit_customers
group by customer_segment


-- 6. How has the business's daily order volume and total revenue changed over time? List each date chronologically, showing the total orders and revenue generated.
select 
date(order_date),
count(order_id) as 'total_orders',
round(sum(order_total),2) as 'total_revenue'
from 
blinkit_orders
group by date(order_date)
order by date(order_date)

-- 7 . Which product categories generate the highest revenue, and how do they compare in terms of total units sold? Rank the categories from highest to lowest revenue.

select p.category, 
round(sum(i.quantity*i.unit_price),2) as 'revenue',
count(i.order_id) as 'units_sold'
from blinkit_products as p
inner join blinkit_order_items as i
on p.product_id = i.product_id

group by p.category
order by sum(i.quantity*i.unit_price)


-- 8. Which products have generated the highest revenue despite having relatively low sales volume? Rank all products by revenue from highest to lowest and compare their total units sold.

select p.product_name, 
round(sum(i.quantity*i.unit_price),2) as 'revenue',
sum(i.quantity) as 'units_sold',
rank() over (order by sum(i.quantity*i.unit_price) desc ) as 'ranking as per revenue'
from blinkit_products as p
inner join blinkit_order_items as i
on p.product_id = i.product_id

group by p.product_name
order by sum(i.quantity), sum(i.quantity*i.unit_price) desc

-- 9. Which products have the highest damaged-stock rates compared to their total stock received? Rank all products from highest to lowest damaged-stock percentage.
select product_id,
sum(damaged_stock) as 'damaged', 
sum(stock_received) as 'received',
rank() over (order by sum(damaged_stock) desc) as 'ranking by damaged products'

from blinkit_inventory
group by product_id

-- 10. Which marketing campaigns generated the highest return on advertising spend (ROAS)? Rank campaigns from highest to lowest ROAS, and compare their total advertising spend and revenue generated.
select campaign_id, campaign_name,
revenue_generated,
spend,
round((revenue_generated/spend),2) as 'ROAS',
rank() over (order by (revenue_generated/spend) desc) as 'Ranking'
from blinkit_marketing_performance
order by ROAS desc

-- 11. Which customer segments have the highest average order value (AOV)? Compare their average order values and total number of orders, ranking segments from highest to lowest AOV.
select customer_segment,
round(sum(avg_order_value),2) as 'Average order value',
sum(total_orders) as 'Total order',
rank() over ( order by sum(avg_order_value) desc ) as 'Ranking'
from
blinkit_customers
group by customer_segment

-- 12. For each product category, identify its top 3 products by revenue. Rank products within each category from highest to lowest revenue.

with helper as (select p.category, p.product_name ,
round(sum(i.quantity*i.unit_price),2) as 'revenue',

rank() over (partition by p.category  order by sum(i.quantity*i.unit_price) desc ) as 'ranking as per revenue'
from blinkit_products as p
inner join blinkit_order_items as i
on p.product_id = i.product_id

group by p.category, p.product_name
--order by sum(i.quantity*i.unit_price) desc
order by p.category, p.product_name
)

select * from helper where "ranking as per revenue"<=3
