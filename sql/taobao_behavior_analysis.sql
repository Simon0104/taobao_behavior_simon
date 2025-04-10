
-- 01_create_table.sql
-- Create the base table and load raw CSV into Hive

DROP TABLE IF EXISTS user_behavior;
CREATE TABLE user_behavior (
  user_id STRING,
  item_id STRING,
  category_id STRING,
  behavior_type STRING,
  timestamp INT,
  datetime STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

LOAD DATA LOCAL INPATH '/path/to/UserBehavior.csv'
OVERWRITE INTO TABLE user_behavior;

-- 02_data_cleaning.sql
-- Deduplicate, convert timestamps, and filter date range

INSERT OVERWRITE TABLE user_behavior
SELECT user_id, item_id, category_id, behavior_type, timestamp, datetime
FROM user_behavior
GROUP BY user_id, item_id, category_id, behavior_type, timestamp, datetime;

INSERT OVERWRITE TABLE user_behavior
SELECT user_id, item_id, category_id, behavior_type, timestamp,
       FROM_UNIXTIME(timestamp, 'yyyy-MM-dd HH:mm:ss') AS datetime
FROM user_behavior;

INSERT OVERWRITE TABLE user_behavior
SELECT *
FROM user_behavior
WHERE CAST(datetime AS DATE) BETWEEN '2017-11-25' AND '2017-12-03';

-- 03_kpi_metrics.sql
-- Calculate PV/UV and repurchase rate

SELECT SUM(CASE WHEN behavior_type = 'pv' THEN 1 ELSE 0 END) AS pv,
       COUNT(DISTINCT user_id) AS uv
FROM user_behavior;

CREATE TABLE user_behavior_count AS
SELECT user_id,
       SUM(CASE WHEN behavior_type = 'pv' THEN 1 ELSE 0 END) AS pv,
       SUM(CASE WHEN behavior_type = 'fav' THEN 1 ELSE 0 END) AS fav,
       SUM(CASE WHEN behavior_type = 'cart' THEN 1 ELSE 0 END) AS cart,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy
FROM user_behavior
GROUP BY user_id;

SELECT SUM(CASE WHEN buy > 1 THEN 1 ELSE 0 END) / SUM(CASE WHEN buy > 0 THEN 1 ELSE 0 END)
FROM user_behavior_count;

-- 04_conversion_funnel.sql
-- Compute conversion stages and rates

SELECT a.pv, a.fav, a.cart, a.fav + a.cart AS fav_cart, a.buy,
       ROUND((a.fav + a.cart) / a.pv, 4) AS pv2favcart,
       ROUND(a.buy / (a.fav + a.cart), 4) AS favcart2buy,
       ROUND(a.buy / a.pv, 4) AS pv2buy
FROM (
  SELECT SUM(pv) AS pv, SUM(fav) AS fav, SUM(cart) AS cart, SUM(buy) AS buy
  FROM user_behavior_count
) AS a;

-- 05_user_activity.sql
-- Analyze hourly and weekly behavior patterns

SELECT HOUR(datetime) AS hour,
       SUM(CASE WHEN behavior_type = 'pv' THEN 1 ELSE 0 END) AS pv,
       SUM(CASE WHEN behavior_type = 'fav' THEN 1 ELSE 0 END) AS fav,
       SUM(CASE WHEN behavior_type = 'cart' THEN 1 ELSE 0 END) AS cart,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy
FROM user_behavior
GROUP BY HOUR(datetime)
ORDER BY hour;

SELECT PMOD(DATEDIFF(datetime, '1920-01-01') - 3, 7) AS weekday,
       SUM(CASE WHEN behavior_type = 'pv' THEN 1 ELSE 0 END) AS pv,
       SUM(CASE WHEN behavior_type = 'fav' THEN 1 ELSE 0 END) AS fav,
       SUM(CASE WHEN behavior_type = 'cart' THEN 1 ELSE 0 END) AS cart,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy
FROM user_behavior
WHERE DATE(datetime) BETWEEN '2017-11-27' AND '2017-12-03'
GROUP BY PMOD(DATEDIFF(datetime, '1920-01-01') - 3, 7)
ORDER BY weekday;

-- 06_rfm_analysis.sql
-- Generate Recency and Frequency score

WITH cte AS (
  SELECT user_id,
         DATEDIFF('2017-12-04', MAX(datetime)) AS R,
         DENSE_RANK() OVER (ORDER BY DATEDIFF('2017-12-04', MAX(datetime))) AS R_rank,
         COUNT(1) AS F,
         DENSE_RANK() OVER (ORDER BY COUNT(1) DESC) AS F_rank
  FROM user_behavior
  WHERE behavior_type = 'buy'
  GROUP BY user_id
)
SELECT user_id, R, R_rank, F, F_rank,
       NTILE(5) OVER (ORDER BY R_rank) AS R_score,
       NTILE(5) OVER (ORDER BY F_rank) AS F_score,
       NTILE(5) OVER (ORDER BY R_rank) + NTILE(5) OVER (ORDER BY F_rank) AS total_score
FROM cte
ORDER BY total_score DESC
LIMIT 20;

-- 07_top_products.sql
-- Top-selling items and categories

SELECT item_id,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy
FROM user_behavior
GROUP BY item_id
ORDER BY buy DESC
LIMIT 10;

SELECT category_id,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy
FROM user_behavior
GROUP BY category_id
ORDER BY buy DESC
LIMIT 10;
