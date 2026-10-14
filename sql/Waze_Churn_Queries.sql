CREATE DATABASE IF NOT EXISTS waze_churn;
USE waze_churn;
show tables;

-- Q1. Data check: how many waze_dataset, and how many have no label?
SELECT COUNT(*) AS total_waze_dataset,
       SUM(CASE WHEN label IS NULL THEN 1 ELSE 0 END) AS unlabeled,
       SUM(CASE WHEN label IS NOT NULL THEN 1 ELSE 0 END) AS labeled
FROM waze_dataset;

-- Q2. Overall churn rate (labeled waze_dataset only)
SELECT COUNT(*) AS labeled_waze_dataset,
       SUM(CASE WHEN label = 'churned' THEN 1 ELSE 0 END) AS churned,
       ROUND(100.0 * SUM(CASE WHEN label = 'churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_pct
FROM waze_dataset
WHERE label IS NOT NULL;

-- Q3. Churn rate by device
SELECT device, COUNT(*) AS waze_dataset,
       ROUND(100.0 * AVG(label = 'churned'), 2) AS churn_pct
FROM waze_dataset
WHERE label IS NOT NULL
GROUP BY device;

-- Q4. Churn rate by activity_days bucket
SELECT CASE WHEN activity_days <= 7  THEN '1) 0-7'
            WHEN activity_days <= 15 THEN '2) 8-15'
            WHEN activity_days <= 23 THEN '3) 16-23'
            ELSE '4) 24-31' END AS activity_bucket,
       COUNT(*) AS waze_dataset,
       ROUND(100.0 * AVG(label = 'churned'), 1) AS churn_pct
FROM waze_dataset
WHERE label IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- Q5. Churn rate by tenure bucket (n_days_after_onboarding)
SELECT CASE WHEN n_days_after_onboarding <= 365  THEN '1) under 1 yr'
            WHEN n_days_after_onboarding <= 1095 THEN '2) 1-3 yrs'
            WHEN n_days_after_onboarding <= 2190 THEN '3) 3-6 yrs'
            ELSE '4) over 6 yrs' END AS tenure_bucket,
       COUNT(*) AS waze_dataset,
       ROUND(100.0 * AVG(label = 'churned'), 1) AS churn_pct
FROM waze_dataset
WHERE label IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- Q6. Average behaviour of churned vs retained waze_dataset
SELECT label,
       ROUND(AVG(sessions), 1)        AS avg_sessions,
       ROUND(AVG(drives), 1)          AS avg_drives,
       ROUND(AVG(activity_days), 1)   AS avg_activity_days,
       ROUND(AVG(driving_days), 1)    AS avg_driving_days,
       ROUND(AVG(driven_km_drives), 0) AS avg_km
FROM waze_dataset
WHERE label IS NOT NULL
GROUP BY label;

-- Q7. Km per driving day (new feature) and churn by group, no-driving-days kept separate
WITH f AS (
  SELECT label,
         CASE WHEN driving_days = 0 THEN NULL
              ELSE driven_km_drives * 1.0 / driving_days END AS km_per_day
  FROM waze_dataset WHERE label IS NOT NULL
)
SELECT CASE WHEN km_per_day IS NULL THEN '0) no driving days'
            WHEN km_per_day < 150 THEN '1) under 150'
            WHEN km_per_day < 300 THEN '2) 150-299'
            WHEN km_per_day < 600 THEN '3) 300-599'
            ELSE '4) 600+' END AS km_group,
       COUNT(*) AS waze_dataset,
       ROUND(100.0 * AVG(label = 'churned'), 1) AS churn_pct
FROM f
GROUP BY 1
ORDER BY 1;

-- Q8. Top 10 highest-risk segments: device x activity bucket (min 100 waze_dataset)
WITH b AS (
  SELECT device, label,
         CASE WHEN activity_days <= 7 THEN '0-7'
              WHEN activity_days <= 15 THEN '8-15'
              WHEN activity_days <= 23 THEN '16-23'
              ELSE '24-31' END AS act
  FROM waze_dataset WHERE label IS NOT NULL
)
SELECT device, act, COUNT(*) AS waze_dataset,
       ROUND(100.0 * AVG(label = 'churned'), 1) AS churn_pct
FROM b
GROUP BY device, act
HAVING COUNT(*) >= 100
ORDER BY churn_pct DESC
LIMIT 10;

-- Q9. Rank waze_dataset by drives within each device (window function), show top 3 each
SELECT * FROM (
  SELECT ID, device, drives, label,
         RANK() OVER (PARTITION BY device ORDER BY drives DESC) AS rnk
  FROM waze_dataset
) AS ranked
WHERE rnk <= 3
ORDER BY device, rnk;

-- Q10. Outliers: waze_dataset who drove more than 20,000 km
SELECT ID, label, driven_km_drives, driving_days, device
FROM waze_dataset
WHERE driven_km_drives > 20000;

-- Q11. Do the unlabeled waze_dataset look like the labeled ones?
SELECT CASE WHEN label IS NULL THEN 'unlabeled' ELSE 'labeled' END AS grp,
       COUNT(*) AS waze_dataset,
       ROUND(AVG(sessions), 1) AS avg_sessions,
       ROUND(AVG(activity_days), 1) AS avg_activity_days,
       ROUND(AVG(n_days_after_onboarding), 0) AS avg_tenure_days
FROM waze_dataset
GROUP BY 1;

-- Q12. Share of all churners that sit in the 0-7 activity-day group
WITH c AS (
  SELECT activity_days <= 7 AS low_act
  FROM waze_dataset WHERE label = 'churned'
)
SELECT ROUND(100.0 * SUM(low_act) / COUNT(*), 1) AS pct_of_churners_in_low_activity
FROM c;
