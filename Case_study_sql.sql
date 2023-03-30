--total orders and total sales 
SELECT COUNT(DISTINCT Customer_ID) AS Total_Customers, 
       COUNT(DISTINCT Invoice) AS Total_Orders, 
       ROUND(SUM(Price*quantity), 2) AS Total_Sales 
FROM Retail;
---------------------
--------------------------------
-- top 10 customer pursches
select *
 from(
        SELECT CUSTOMER_ID, total ,RANK() OVER (ORDER BY total DESC) AS ORD_Of_Customers FROM
               (

select DISTINCT(customer_id),sum(price*quantity) over( partition by customer_id order by price rows between unbounded preceding and unbounded following )  as total 
from retail  )
)
where ORD_Of_Customers <=10
order by  total desc;
-----------------------
--highest sales per date and customers
SELECT DISTINCT customer_id,
       invoicedate,
       ROUND(SUM(price*quantity) OVER(PARTITION BY customer_id, invoicedate),0) AS total
FROM retail
ORDER BY total DESC;

-----------

-- num of customers,and num of orders and the avg purcash per country 
SELECT DISTINCT country,
                COUNT(DISTINCT invoice) OVER(PARTITION BY country) AS Num_Of_Orders,
                COUNT(DISTINCT customer_id) OVER(PARTITION BY country) AS Num_Of_Customers,
                ROUND(AVG(price*quantity) OVER(PARTITION BY country),2) AS Avg_purcash
FROM retail
ORDER BY Num_Of_Orders DESC;

------------------
--highest sales  per year 

SELECT Distinct 
    Years, Round(SUM(price*QUANTITY)) AS total 
FROM 
(
select INVOICE, STOCKCODE, QUANTITY, INVOICEDATE, PRICE, CUSTOMER_ID, COUNTRY, to_char(to_date(invoicedate,'mm/dd/yyyy hh24:mi'),'yyyy') AS Years 
FROM retail 
) 
Group by  Years
Order by total DESC;
-----------------

----highest sales per month
SELECT Distinct 
   months, Round(max(price*QUANTITY)) AS total 
FROM 
(
select INVOICE, STOCKCODE, QUANTITY, INVOICEDATE, PRICE, CUSTOMER_ID, COUNTRY, to_char(to_date(invoicedate,'mm/dd/yyyy hh24:mi'),'mm') AS months
FROM retail 
) 
Group by months
Order by total DESC,months desc;
---------
-- highest stock code purchased
SELECT 
 
    Distinct (StockCode), 
    SUM(Quantity) AS TotalPurchased
FROM 
    Retail
WHERE 
    Quantity > 0
GROUP BY StockCode
  
ORDER BY 
    TotalPurchased DESC;
-----------------

------
SELECT 
    StockCode, 
    COUNT(DISTINCT Customer_ID) AS TotalCustomers, 
    SUM(Quantity * Price) AS TotalRevenue
FROM 
  Retail
GROUP BY 
   StockCode
ORDER BY 
    TotalRevenue DESC;
    --------------------------------------------
    
    
    
    
    with Segmentation as 
(
    select customer_id, Recency, Frequency, Monetary, r_score,
            round((f_score + m_score) / 2) fm_score
    from (
            select customer_id, Recency, Frequency, Monetary,
                    ntile (5) over (order by Recency desc) r_score,
                    ntile (5) over (order by Frequency) f_score,
                    ntile (5) over (order by Monetary) m_score
            from (
                    select customer_id,
                            round(((select max(to_date(invoicedate, 'mm/dd/yyyy hh24:mi')) from retail) - max(to_date(invoicedate, 'mm/dd/yyyy hh24:mi'))))  Recency,
                            count(invoice) Frequency,
                            sum(price*quantity) Monetary
                    from retail
                    group by customer_id
            )
    )
    order by customer_id
)
select customer_id, Recency, Frequency, Monetary, r_score, fm_score,
        case when r_score =  5 and fm_score = 5 then 'Champions'
               when r_score =  5 and fm_score = 4 then 'Champions'
               when r_score =  4 and fm_score = 5 then 'Champions'
               when r_score =  5 and fm_score = 2 then 'Potential Loyalists'
               when r_score =  4 and fm_score = 2 then 'Potential Loyalists'
               when r_score =  3 and fm_score = 3 then 'Potential Loyalists'
               when r_score =  4 and fm_score = 3 then 'Potential Loyalists'
               when r_score =  5 and fm_score = 3 then 'Loyal Customers'
               when r_score =  4 and fm_score = 4 then 'Loyal Customers'
               when r_score =  3 and fm_score = 5 then 'Loyal Customers'
               when r_score =  3 and fm_score = 4 then 'Loyal Customers'
               when r_score =  5 and fm_score = 1 then 'Recent Customers'
               when r_score =  4 and fm_score = 1 then 'Promising'
               when r_score =  3 and fm_score = 1 then 'Promising'
               when r_score =  3 and fm_score = 2 then 'Customers Needing Attention'
               when r_score =  2 and fm_score = 3 then 'Customers Needing Attention'
               when r_score =  2 and fm_score = 2 then 'Customers Needing Attention'
               when r_score =  2 and fm_score = 5 then 'At Risk'
               when r_score =  2 and fm_score = 4 then 'At Risk'
               when r_score =  2 and fm_score = 1 then 'At Risk'
               when r_score =  1 and fm_score = 3 then 'At Risk'
               when r_score =  1 and fm_score = 5 then 'Cannot Lose Them'
               when r_score =  1 and fm_score = 4 then 'Cannott Lose Them'
               when r_score =  1 and fm_score = 2 then 'Hibernating'
               when r_score =  1 and fm_score = 1 then 'Lost'
        end as "customer_segment"  
from Segmentation ;