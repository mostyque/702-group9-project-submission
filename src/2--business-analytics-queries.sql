----------------------------------------------------------------------
/*
RQ1: How have changes in national internet usage between 2005 and 2021 affected year-on-year trends in female enrolment 
and graduation rates in STEM fields across Australia, Canada, Germany, and the United States, and to what extent 
does greater technological access shape women's participation in STEM within these countries?
*/ 
----------------------------------------------------------------------

-- 1. The agg CTE (Common Table Expression)  

WITH agg AS ( 
  SELECT CountryCode, TimeID,  
         AVG(FemaleEnrolRate) AS avg_enrol, - Calculating average female enrol rate 
         AVG(FemaleGradRate) AS avg_grad – Calculating average female graduation rate  
  FROM fact_representation 
  GROUP BY CountryCode, TimeID 
) -- This simplifies the dataset so downstream queries only require one row per country per year instead of one row per STEM Field. 

-- 2. Main SELECT Query  

SELECT 
  dc.Name AS country, 
  dt.Year AS year, -- dc.Name / dt.Year extracts the country name and the year from the dimension tables  
ROUND(MAX(s.InternetUsage)*100, 2) AS InternetUsage, 
-- Takes the maximum InternetUsage value from dim_score for that country/year. 
ROUND (AVG (agg.avg_enrol) *100, 2)   AS AvgFemaleEnrolment, 
ROUND (AVG (agg.avg_grad) *100, 2)    AS AvgFemaleGrad -- Multiplies by 100 and rounds to 2 decimal places  
FROM agg 
JOIN dim_country dc USING (CountryCode) -- Maps CountryCode to Name (India as 'IND')  
JOIN dim_time    dt USING (TimeID) -- maps TimeID to Year (Year is 2005) 
LEFT JOIN dim_scores 
       ON s.CountryCode = dc.CountryCode 
      AND s.TimeID      = dt.TimeID  -- LEFT JOIN ensures missing rows won't disrupt the function. 
WHERE dc.CountryCode = 'IND' -- or 'USA',' AUS',' CAN', 'CHN', 'DEU', filter to one country at a time (e.g. 'IND'). 
GROUP BY dc.CountryCode, dt.Year -- ensures one row per (Country,Year) in the final table. 
ORDER BY dt.Year; -- arranges by year sequentially


----------------------------------------------------------------------
/*
RQ2: Between 2005 and 2021, how do year-on-year changes in gender inequality (GII) 
relate to the growth rates of female enrolment and graduation in STEM across Australia, 
Canada, China, Germany, India, and the USA? 
*/
----------------------------------------------------------------------

-- 1. Calculate the average GII score, the average Female Enrol in proportion, the average Female Grad Proportion for each country in each year
DROP TABLE IF EXISTS agg2;
CREATE TEMP TABLE agg2 AS
SELECT c.Name AS CountryName, --Take the Name in the dim_country
    t.Year AS 'Year', -- Take the Year in the dim_time
    AVG(f.GIIScore) AS GIIScore, -- Calculate average GIIScore for each country in each year
    AVG(f.FemaleEnrolRate) AS FemaleEnrolProp, -- Calculate average Female Enrol Proportion for each country in each year
    AVG(f.FemaleGradRate) AS FemaleGradProp -- Calculate average Female Grad Proportion for each country in each year
FROM fact_representation AS f -- Extract data from fact_representation
JOIN dim_country AS c -- Join with dim_country to take the Name
ON c.CountryCode = f.CountryCode
JOIN dim_time AS t -- Join with dim_time to take the Time
  	ON t.TimeID = f.TimeID
WHERE t.Year BETWEEN 2005 AND 2021 -- Take years from 2005 to 2021
  	AND c.Name IN ('Australia', 'Canada', 'China', 'Germany', 'India', 'United States') -- Focus on 6 target countries
GROUP BY c.Name, t.Year; -- Makes sure the output table has one row for each country in each year, with averages across all STEM fields.

-- 2. Compute the differences in GII Score, Female Enrol Prop, and Female Grad Prop between year t and year t-1
DROP TABLE IF EXISTS yoy;
CREATE TEMP TABLE yoy AS
SELECT CountryName, Year, GIIScore,
                 GIIScore - LAG(GIIScore)
							OVER (PARTITION BY CountryName ORDER BY Year) AS DeltaGenderInequalityIndex, -- pulls the previous year'ss GII within the same country
				 100.0 * (FemaleEnrolProp - LAG(FemaleEnrolProp) 
							OVER (PARTITION BY CountryName ORDER BY Year)) AS DeltaFemaleEnrolProp, -- Subtract last year's enrol value to get the delta in proportion, then multiply by 100 to convert to percentage
				 100.0 * (FemaleGradProp - LAG(FemaleGradProp)
							OVER (PARTITION BY CountryName ORDER BY Year)) AS DeltaFemaleGradProp -- Subtract last year's grad value to get the delta in proportion, then multiply by 100 to convert to percentage
FROM agg2;

-- 3. Remove NULL values
DROP TABLE IF EXISTS cleaned_yoy;
CREATE TEMP TABLE cleaned_yoy AS
SELECT *
FROM yoy
WHERE DeltaGenderInequalityIndex IS NOT NULL
  AND DeltaFemaleEnrolProp IS NOT NULL
  AND DeltaFemaleGradProp IS NOT NULL;

-- 4. Calculate Enrol Statistics
DROP TABLE IF EXISTS stats_enrol;
CREATE TEMP TABLE stats_enrol AS
SELECT CountryName,
  COUNT(*) AS n,
  SUM(DeltaGenderInequalityIndex) AS sumdgii, --Adds up all the yearly ΔGII values (year-on-year changes in GII) for that country
  SUM(DeltaFemaleEnrolProp) AS sumdenrol, -- Adds up all the yearly changes in female STEM enrolment proportion for that country.
  SUM((DeltaGenderInequalityIndex)*(DeltaGenderInequalityIndex)) AS sumdgii_sumdgii, -- Squares each year's ΔGII value and then sums them for variance
  SUM((DeltaFemaleEnrolProp)*(DeltaFemaleEnrolProp)) AS sumdenrol_sumdenrol, -- Squares each year's enrolment change and then sums them for variance
  SUM((DeltaGenderInequalityIndex)*(DeltaFemaleEnrolProp)) AS sumdgii_sumdenrol -- Calculate covariance numerator to show how changes in GII and enrolment
FROM cleaned_yoy
GROUP BY CountryName;

-- 5. Calculate Grad 
DROP TABLE IF EXISTS stats_grad;
CREATE TEMP TABLE stats_grad AS
SELECT CountryName,
  COUNT(*) AS n,
  SUM(DeltaGenderInequalityIndex) AS sumdgii,
  SUM(DeltaFemaleGradProp) AS sumdgrad, -- Adds up all the yearly changes in female STEM graduation proportion for that country.
  SUM((DeltaGenderInequalityIndex)*(DeltaGenderInequalityIndex)) AS sumdgii_sumdgii,
  SUM((DeltaFemaleGradProp)*(DeltaFemaleGradProp)) AS sumdgrad_sumdgrad, -- Squares each year's graduation change and then sums them for variance
  SUM((DeltaGenderInequalityIndex)*(DeltaFemaleGradProp)) AS sumdgii_sumdgrad --Calculate covariance numerator to show how changes in GII and graduation
FROM cleaned_yoy
GROUP BY CountryName;

-- 6. Calculate correlation and slope
SELECT e.CountryName AS "Country Name",
  ROUND((e.n*e.sumdgii_sumdenrol - e.sumdgii*e.sumdenrol) /
        NULLIF(SQRT((e.n*e.sumdgii_sumdgii - e.sumdgii*e.sumdgii) * (e.n*e.sumdenrol_sumdenrol - e.sumdenrol*e.sumdenrol)), 0), 3) 
        AS "Correlation ΔGII vs ΔFemale Enrolment", -- Correlation for Female Enrolment
  ROUND((g.n*g.sumdgii_sumdgrad - g.sumdgii*g.sumdgrad) /
        NULLIF(SQRT((g.n*g.sumdgii_sumdgii - g.sumdgii*g.sumdgii) * (g.n*g.sumdgrad_sumdgrad - g.sumdgrad*g.sumdgrad)), 0), 3) 
        AS "Correlation ΔGII vs ΔFemale Graduation" -- Correlation for Female Graduation
FROM stats_enrol e
JOIN stats_grad  g ON g.CountryName= e.CountryName
ORDER BY e.CountryName;


----------------------------------------------------------------------
/*
RQ3: What is the relationship between freedom of expression and female 
STEM enrolment rate in Asia and America over time? 
What are the differences between the two continents?
*/
----------------------------------------------------------------------

SELECT dc.Continent Continent, dt.Year Year, f.Freedom, ROUND(AVG(f.FemaleEnrolRate),2) AvgFemaleEnrolment -- Select the relevant attributes to the question
FROM fact_representation f -- from fact_representation, joined with dim_country and dim_time 
JOIN dim_country dc USING(CountryCode) 
JOIN dim_time dt USING(TimeID) 
WHERE UPPER (dc.Continent) IN ('AMERICA',' ASIA') -- filtering by continent name (America and Asia),
GROUP BY Continent, Year -- grouping the results by Continent and Year
ORDER BY f.TimeID; --ordering by year in chronological order. 