create database data_bank_query;
use data_bank_query;
-- How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS Unique_Nodes
FROM customer_nodes;

-- What is the number of nodes per region?
SELECT r.region_name,COUNT(DISTINCT cn.node_id) AS Nodes
FROM customer_nodes cn JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name;

-- How many customers are allocated to each region?
SELECT r.region_name,COUNT(DISTINCT cn.customer_id) AS Customers
FROM customer_nodes cn JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name;

-- How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(DAY, start_date, end_date)) AS Avg_Days
FROM customer_nodes;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT DISTINCT
    r.region_name,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY DATEDIFF(DAY, start_date, end_date))
        OVER (PARTITION BY r.region_name) AS Median,
    PERCENTILE_CONT(0.80)
        WITHIN GROUP (ORDER BY DATEDIFF(DAY, start_date, end_date))
        OVER (PARTITION BY r.region_name) AS P80,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY DATEDIFF(DAY, start_date, end_date))
        OVER (PARTITION BY r.region_name) AS P95

FROM customer_nodes cn JOIN regions r
ON cn.region_id = r.region_id;

-- What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) AS transaction_count, SUM(txn_amount) AS total_amount
FROM Customer_Transactions
GROUP BY txn_type;

-- What is the average total historical deposit counts and amounts for all customers?
SELECT
    AVG(deposit_count * 1.0) AS Avg_Deposit_Count,
    AVG(total_deposit * 1.0) AS Avg_Deposit_Amount
FROM
(
    SELECT
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS total_deposit
    FROM Customer_Transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
) AS deposits;

--  For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_activity AS
(
    SELECT
        customer_id,
        YEAR(txn_date) AS yr,
        MONTH(txn_date) AS mn,

        SUM(CASE
                WHEN txn_type='deposit'
                THEN 1 ELSE 0
            END) AS deposit_count,

        SUM(CASE
                WHEN txn_type IN ('purchase','withdrawal')
                THEN 1 ELSE 0
            END) AS other_count
    FROM Customer_Transactions
    GROUP BY
        customer_id,
        YEAR(txn_date),
        MONTH(txn_date)
)

SELECT yr,mn,COUNT(*) AS customer_count
FROM monthly_activity
WHERE deposit_count > 1
AND other_count >= 1
GROUP BY yr,mn;
