# fintrust-data-analytics-Week1
Week 1 report: business understanding, data profiling, 8 KPIs, dashboard wireframe, Week 2–4 plan
## Week 2 — Analyse & Prepare

**Status:** Complete

Moved from Week 1 planning into hands-on analysis using the full FinTrust datasets 
(1,500 customers, 12,000 transactions).

### What's in this folder
- `FinTrust_Week2_DataQuality_Report.pdf` — data quality findings report
- `FinTrust_Week2_DataCleaning_Log.xlsx` — row-by-row record of every cleaning action taken
- `FinTrust_Week2_SQL_Analysis.sql` — 8 business questions answered in SQL, with interpretations
- `FinTrust_Week2_Data_Analysis.ipynb` — Python EDA with 5 visualisations
- `FinTrust_Week2_Analytics_Dashboard.pbix` — Power BI dashboard (KPI cards, trend, channel, risk and geographic views)
- `FinTrust_Week2_Documentation.docx` — full write-up: tools used, dashboard build notes, business insights, testing evidence, Week 2 summary

### Key findings
- Overall transaction success rate: **90.47%**
- USSD has the lowest transaction volume of any channel but the **highest average transaction value**
- International transactions are flagged for risk review at **~2x** the domestic rate (36.88% vs 18.88%)
- Lagos accounts for a large share of transaction activity by customer residence
- Several top-value customers are labelled "Everyday," not "Premium"

### Tools used
Microsoft Excel · SQLite · Python (Pandas, Matplotlib, Seaborn) · Power BI Desktop

---

## Week 3 — Develop & Integrate

**Status:** Complete

Built directly on Week 2: extended the SQL and Python analysis with more advanced techniques, 
expanded the dashboard, and — critically — went back and validated every major Week 2 finding 
against fresh evidence rather than assuming it was correct.

### What's in this folder
- `FinTrust_Week3_Advanced_SQL_Analysis.sql` — 8 additional queries using window functions, CTEs, subqueries and CASE logic
- `FinTrust_Week3_Advanced_Analysis.ipynb` — 5 additional analyses: weekly trend, Pareto/value-concentration, customer segmentation, comparative risk trend, correlation check
- `FinTrust_Week3_Analytics_Dashboard.pbix` — extended dashboard with trend analysis, customer analysis, and tested cross-filtering
- `FinTrust_Week3_Documentation.docx` — gap review, 5 validated findings, 5 recommendations, validation/refinement evidence, updated limitations, Week 3 summary

### Key findings
- **Caught and corrected a methodological error** from Week 2: the original "Lagos dominates transaction value" finding was based on customer home city, not actual transaction location — re-validated using the correct field, value is spread almost evenly across all 8 cities
- **Top 10% of transactions account for 56% of total transaction value** (decile/Pareto analysis)
- Refined the channel-reliability finding: **Web**, not USSD, has the highest share of value lost to failed/reversed transactions
- International risk rate remains higher than domestic in every month, though the gap is narrowing
- High-value customers exist within every customer segment, not just "Premium"

### Tools used
SQLite (window functions, CTEs) · Python (Pandas, Matplotlib, Seaborn) · Power BI Desktop
## Week 4: Test, Refine & Present

**Status:** Complete

The final stage of the FinTrust project. Instead of adding more analysis, I went back and
re-tested every finding from Weeks 2-3 using statistical checks, recalculated every headline
figure from the source data, and corrected what did not hold up. The final dashboard,
SQL, notebook and report all reflect the corrected results.

### What's in this folder
- `FinTrust_Week4_Analytics_Dashboard.pbix` - final Power BI dashboard (plus a PDF export)
- `FinTrust_Week4_Final_SQL_Analysis.sql` - 9 final queries (joins, CTEs, window functions), each run and interpreted
- `FinTrust_Week4_Final_Analysis.ipynb` - reproducible notebook: data-quality checks, three-way KPI reconciliation, statistical tests, 7 charts
- `FinTrust_Week4_Final_Documentation.docx` - final report: corrections log, KPI documentation, insights, validation, recommendations, limitations, lessons learned
- `FinTrust_Final_Presentation.pptx` - slides for my individual video presentation
- Video presentation: 

### Headline KPIs
| KPI | Value |
|---|---|
| Customers | 1,500 |
| Transactions | 12,000 |
| Total value | NGN 560,477,354.85 |
| Average / median transaction | NGN 46,706.45 / NGN 10,305.94 |
| Success rate | 90.47% |
| Failed + reversed | 7.97% of transactions (7.22% of value) |
| Risk-review rate | 19.60% |

### Findings that held up under testing
- Risk review is concentrated in **Transfers (28.5%)** and **Cash Withdrawals (25.3%)**, against 19.6% overall.
- **International** transactions are flagged about twice as often as domestic ones (36.9% vs 18.9%), and this holds within every transaction type.
- The **top 10% of transactions carry 56% of all value**, and transactions above about NGN 68,000 are also flagged most (26.8% vs 17.8%).
- Home city and transaction location are statistically unrelated: Lagos holds 32.5% of customers, but transaction value by location is spread evenly (11-15% per city).

### Findings that changed after validation
| Earlier claim | What testing showed |
|---|---|
| February dip in value | Calendar artefact. Per active day, volume is identical and value is 3.3% higher |
| International risk gap is narrowing | Not statistically significant (p = 0.107) |
| USSD has the highest average value | No real difference between channels (p = 0.39) |
| Web is the worst channel for failures | Not distinguishable from the others (p = 0.07) |
| Premium / Student segments are riskier | No difference between segments (p = 0.75) |
| Lagos 36.1% of value, Mobile App 45.7%, Everyday 49.6% | Arithmetic errors; corrected to 33.9%, 42.8%, 46.6% |

> The Week 2 and Week 3 sections above contain some of these earlier claims. They are
> superseded by this section; see the corrections log in the Week 4 report.

### How to reproduce
1. Put `FinTrust_Customer_Data` and `FinTrust_Transaction_Data` (`.csv` or `.xlsx`) next to the notebook.
2. Install the dependencies: `pip install pandas numpy scipy matplotlib seaborn openpyxl`
3. Open `FinTrust_Week4_Final_Analysis.ipynb` and choose Run all. It runs top to bottom with no hidden state.
4. For SQL, load the two tables as `customers` and `transactions` (SQLite was used; the file notes the MySQL/PostgreSQL date functions to swap) and run the `.sql` file.
5. For Power BI, import the cleaned CSVs, make sure `Customer_ID` links the two tables (one customer to many transactions), and check the KPI cards against the table above.

### Tools used
Microsoft Excel, SQLite, Python (pandas, NumPy, SciPy, Matplotlib, Seaborn), Power BI Desktop, Jupyter

### Limitations
- All data is synthetic and unusually uniform over time, so seasonal and time-of-day patterns cannot be studied.
- Results are associations, not causes.
- There is no failure-reason field, so the data shows how often transactions fail but not why.
- `Risk_Review_Flag` is a synthetic educational label, not a fraud determination.
- No integration with other tracks is claimed; no other track's output was used.

### Lessons learned
1. A pattern in a chart is a hypothesis, not a finding. Check it before reporting it.
2. Normalise before comparing (per day, not per month).
3. Never type a computed number by hand; generate it from the query.
