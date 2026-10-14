# Waze User Churn Analysis

I took one dataset of Waze app users (14,999 rows) and worked through it in Excel, SQL, Python and Power BI to find out which users are likely to leave, and how well a model can predict it.

## Table of Contents

* [Overview](#overview)
* [Problem Statement](#problem-statement)
* [Tools and Technologies](#tools-and-technologies)
* [Project Structure](#project-structure)
* [Key Insights](#key-insights)
* [Output](#output)
* [How to Run This Project?](#how-to-run-this-project)
* [Results & Conclusion](#results--conclusion)
* [Future Work](#future-work)
* [Author & Contact](#author--contact)

---

## Overview

The data is the Waze user churn dataset, which I downloaded from [add your download link here]. It has 14,999 users and 13 columns: sessions, drives, kilometres driven, days active, days driven, how long the user has had the app, how often they navigated to saved places, device type, and a `label` column that says whether the user churned or stayed. As far as I know this is synthetic data made for a training course, so the numbers show patterns but shouldn't be read as real Waze statistics.

I used the same data in four tools, one after another:

1. Excel, to check the data and build pivot tables and charts
2. SQL, to answer the same questions with queries
3. Python, to build features and train two prediction models
4. Power BI, for a dashboard with filters

700 users have no label, so I left them out of the analysis. That leaves 14,299 users: 2,536 churned and 11,763 retained. I checked the unlabeled group and it looks the same as the labeled one (about 80.8 sessions against 80.6, and 15.4 active days against 15.5), so dropping it shouldn't bias anything.

## Problem Statement

A churned user is lost for good, and a retention message costs very little. So the questions were:

- What behaviour separates users who leave from users who stay?
- How well can a model predict who will leave?
- If a team can only contact some of the users, how should it choose them?

## Tools and Technologies

- Excel: helper columns, pivot tables, charts
- SQL (MySQL): `CASE` buckets, aggregations, CTEs, window functions
- Python: pandas, NumPy, scikit-learn, matplotlib, seaborn, Jupyter
- Power BI Desktop: DAX measures, slicers, conditional colours
- Git and GitHub

## Project Structure

```
waze-churn-analysis/
├── README.md
├── data/
│   └── README.md                       how to get the dataset
├── excel/
│   └── Waze_Churn.xlsx                 data, pivots, charts, findings
├── sql/
│   └── Waze_Churn_Queries.sql          12 queries
├── python/
│   ├── Waze_Churn_Python.ipynb         features, both models, comparison
│   └── waze_dataset.csv
├── powerbi/
│   └── Waze_Churn_Dashboard.pbix       the dashboard
├── images/                             screenshots and plots used below
│   ├── Dashboard 1.png
│   └── Dashboard 2.png                      
```

## Key Insights

Overall, 17.74% of labeled users churned (2,536 out of 14,299).

- **Activity is the clearest signal.** Users who were active 0-7 days in the month churned at 35.5%. For users active 24-31 days it was 5.1%. Almost half of all churners (48.9%) sit in that lowest group.
- **Driving days tell the same story.** 32.2% churn for 0-7 days driven, 3.9% for 24-31 days.
- **Newer users leave more.** Under 1 year on the app: 25.9%. Over 6 years: 12.5%.
- **Kilometres per driving day is odd.** Users who never drove at all that month (983 of them) churned at 40.0%, and users driving 600+ km on the days they did drive churned at 29.3%. The lowest churn, 7.7%, was in the group driving under 150 km per day.
- **Device doesn't matter.** Android 17.6%, iPhone 17.8%. The pattern with activity looks the same on both.
- **Number of sessions doesn't matter much either.** Every group sat between 16.6% and 19.3%.
- The strongest correlation with churn is `activity_days` at -0.30. Nothing else is close.
- Two users drove over 20,000 km in a month. Both are retained, and they look like outliers.

## Output

### Dashboard

The Power BI dashboard has three KPI cards (total users, churned users, churn rate), four bar charts and three slicers (device, tenure, activity) that filter the whole page. Bars with a churn rate of 20% or more are red.

![Dashboard, no filters](D:\Waze_Churn_Project\images\Dashboard 1.png)

![Dashboard, one slicer selected](D:\Waze_Churn_Project\images\Dashboard 2.png)


### Models

I trained Logistic Regression and Random Forest, both with `class_weight='balanced'` because of the imbalance, on an 80/20 split (2,860 test users, 507 of them churners). I also created a few features myself: km per driving day, km per drive, drives per driving day, the share of all sessions that happened this month, favourite-place navigations, and a heavy-driver flag.

| Model | Accuracy | Churn recall | Churn precision | ROC-AUC |
|---|---|---|---|---|
| Logistic Regression | 67.1% | 70.4% | 31.1% | 0.744 |
| Random Forest | 69.1% | 66.3% | 32.0% | 0.740 |

## How to Run This Project?

1. Clone the repo.
   ```
   [git clone](https://github.com/Tejaspakhale/waze-churn-analysis.git)
   cd waze-churn-analysis
   ```
2. Download the dataset from [kaggle](https://www.kaggle.com/datasets/mostafamohammednouh/waze-synthetic-user-churn-data) and save it as `waze_dataset.csv`. .
3. Excel: open `excel/Waze_Churn_Phase1.xlsx`. The Findings, Summary and Data sheets are ready to read.
4. SQL: the queries expect a table called `users`. Import `waze_dataset.csv` into MySQL with that table name. The import tool saves the 700 blank labels as empty text instead of NULL, so run this once afterwards:
   ```sql
   SET SQL_SAFE_UPDATES = 0;
   UPDATE users SET label = NULL WHERE label = '';
   ```
   Then run `sql/waze_churn_queries.sql`. The window-function query needs MySQL 8 or newer.
5. Python:
   ```
   pip install pandas numpy scikit-learn matplotlib seaborn jupyter
   jupyter notebook python/Waze_Churn_Phase3.ipynb
   ```
6. Power BI: open `powerbi/Waze_Churn_Dashboard.pbix` in Power BI Desktop (it's free). If it asks where the data is, point it to the Excel workbook or the CSV.

## Results & Conclusion

Churn here is mostly about how often people use the app. A user who was active about a week or less in the month is several times more likely to leave than one who was active most days, and that holds on both Android and iPhone. Tenure adds a smaller effect on top.

Both models reach about 0.74 ROC-AUC. That is acceptable but not high, and I don't think it can go much higher with this data: it only has usage counts, with nothing about why people stopped. When I added my own ratio features the score barely moved, which tells me the raw columns already hold most of the signal. I would be suspicious of a much higher number.

I would ship Logistic Regression. The AUC is the same as the Random Forest, it catches slightly more churners (70% against 66%), and its coefficients are easy to explain. Activity days has the largest coefficient at -0.76, then tenure at -0.41.

Precision is only about 31%, so most users the model flags would have stayed anyway. That is a trade I accepted on purpose, since a retention message costs little. The cut-off matters a lot: at a threshold of 0.3 the Logistic Regression catches about 90% of churners but flags 1,867 of the 2,860 test users, while at 0.7 it flags only 462 and catches 37%. The right choice depends on what a message costs against what a lost user is worth.

If I had to give one recommendation: contact users who were active 7 days or fewer first, along with users who didn't drive at all. Together they hold most of the churn.

## Future Work

- Try XGBoost or LightGBM and see if they beat the Logistic Regression.
- Pick the threshold with real costs for a message and for a lost user, rather than 0.5.
- Look at why users who never drove churn so much. It could be a real group, or a data issue.
- Add data this set doesn't have, such as how the month trended, support issues or app version.
- Use SHAP values to explain individual predictions.
- Publish the dashboard online.

## Author & Contact

Tejas Pakhale

- LinkedIn: https://www.linkedin.com/in/tejas-pakhale-411785264/
- GitHub: https://github.com/Tejaspakhale
- Email: pakhaletejas539@gmail.com
