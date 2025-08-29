PRAGMA foreign_keys = ON;

-- =========================================================
-- A) RAW TABLES (create empty, then import CSVs into them)
--    Mapping CSV headers to these exact column names.
-- =========================================================

/* 1)	Creating a table for Women_in_STEM Dataset */
DROP TABLE IF EXISTS stg_women_stem_raw;
CREATE TABLE stg_women_stem_raw (
  Country TEXT,
  Year INTEGER,
  "Female Enrollment (%)" REAL,
  "Female Graduation Rate (%)" REAL,
  "STEM Fields" TEXT,
  "Gender Gap Index" REAL
);

-- import stg_women_stem_raw.csv into this table via DB Browser import function or execute the command below in SQLiteCLI
-- .import --csv --skip 1 stg_women_stem_raw.csv stg_women_stem_raw

/* 2)	Creating a table for the World_Happiness Dataset */
DROP TABLE IF EXISTS stg_world_happiness_raw;
CREATE TABLE stg_world_happiness_raw (
 "Country name"						TEXT,
  year									INTEGER,
  "Life Ladder"							REAL,
  "Log GDP per capita"					REAL,
  "Social support"						REAL,
  "Healthy life expectancy at birth"	REAL,
  "Freedom to make life choices"		REAL,
  "Generosity"							REAL,
  "Perceptions of corruption"			REAL,
  "Positive affect"						REAL,
  "Negative affect"						REAL
);
 
-- import stg_world_happiness_raw.csv into this table via DB Browser import function or execute the command below in SQLiteCLI
-- .import --csv --skip 1 stg_world_happiness_raw.csv stg_world_happiness_raw

/* 3)	Creating a table for the Gender_Inequality_Index Dataset */
DROP TABLE IF EXISTS stg_gender_inequality_raw;
CREATE TABLE stg_gender_inequality_raw (
  ISO3 TEXT,
  Country TEXT,
  Continent TEXT,
  Hemisphere TEXT,
  "Human Development Groups" TEXT,
  "UNDP Developing Regions" TEXT,
  "HDI Rank (2021)" INTEGER,
  "GII Rank (2021)" INTEGER,
	"Gender Inequality Index (1990)" REAL,
	"Gender Inequality Index (1991)" REAL,
	"Gender Inequality Index (1992)" REAL,
	"Gender Inequality Index (1993)" REAL,
	"Gender Inequality Index (1994)" REAL,
	"Gender Inequality Index (1995)" REAL,
	"Gender Inequality Index (1996)" REAL,
	"Gender Inequality Index (1997)" REAL,
	"Gender Inequality Index (1998)" REAL,
	"Gender Inequality Index (1999)" REAL,
	"Gender Inequality Index (2000)" REAL,
	"Gender Inequality Index (2001)" REAL,
	"Gender Inequality Index (2002)" REAL,
	"Gender Inequality Index (2003)" REAL,
	"Gender Inequality Index (2004)" REAL,
  "Gender Inequality Index (2005)" REAL,
  "Gender Inequality Index (2006)" REAL,
  "Gender Inequality Index (2007)" REAL,
  "Gender Inequality Index (2008)" REAL,
  "Gender Inequality Index (2009)" REAL,
  "Gender Inequality Index (2010)" REAL,
  "Gender Inequality Index (2011)" REAL,
  "Gender Inequality Index (2012)" REAL,
  "Gender Inequality Index (2013)" REAL,
  "Gender Inequality Index (2014)" REAL,
  "Gender Inequality Index (2015)" REAL,
  "Gender Inequality Index (2016)" REAL,
  "Gender Inequality Index (2017)" REAL,
  "Gender Inequality Index (2018)" REAL,
  "Gender Inequality Index (2019)" REAL,
  "Gender Inequality Index (2020)" REAL,
  "Gender Inequality Index (2021)" REAL
  );
  
-- import stg_gender_inequality_raw.csv into this table via DB Browser import function or execute the command below in SQLiteCLI
-- .import --csv --skip 1 stg_gender_inequality_raw.csv stg_gender_inequality_raw

/* 4)	Creating a table for the Internet_Usage Dataset */
DROP TABLE IF EXISTS stg_internet_usage_raw;
CREATE TABLE stg_internet_usage_raw (
  Entity TEXT,           -- country name
  Code   TEXT,           -- ISO3
  Year   INTEGER,
  "Individuals using the Internet (% of population)" REAL
);

-- import stg_internet_usage_raw.csv into this table via DB Browser import function or execute the command below in SQLiteCLI
-- .import --csv --skip 1 stg_internet_usage_raw.csv stg_internet_usage_raw


/* Whitelist of 6 countries for the study */
DROP TABLE IF EXISTS country_whitelist;
CREATE TABLE country_whitelist(iso3 TEXT PRIMARY KEY, std_name TEXT);
INSERT OR REPLACE INTO country_whitelist VALUES
 ('AUS','Australia'),
 ('CAN','Canada'),
 ('CHN','China'),
 ('DEU','Germany'),
 ('IND','India'),
 ('USA','United States');

 -- =========================================================
-- B) STAGING (tidy/standardize)
-- =========================================================

-- Women in STEM → tidy & normalize (% → 0–1)
DROP TABLE IF EXISTS stg_women_stem;
CREATE TABLE stg_women_stem AS
SELECT
  TRIM("Country") AS country,
  CAST("Year" AS INT) AS year,
  TRIM("STEM Fields") AS field,
  CAST("Female Enrollment (%)"      AS REAL)/100.0 AS female_enrol_rate,
  CAST("Female Graduation Rate (%)" AS REAL)/100.0 AS female_grad_rate,
  CAST("Gender Gap Index" AS REAL)/100.0 AS gender_gap_index 
FROM stg_women_stem_raw;

-- World Happiness (2024) → keep only required columns
DROP TABLE IF EXISTS stg_world_happiness;
CREATE TABLE stg_world_happiness AS
SELECT
  TRIM("Country name") AS country,
  CAST(year AS INT) AS year,
  CAST("Life Ladder"        			AS REAL) AS happiness_score,
  CAST("Social support"        			AS REAL) AS social_support,
  CAST("Perceptions of corruption" 		AS REAL) AS corruption_perception,
  CAST("Freedom to make life choices"   AS REAL) AS freedom,
  CAST("Log GDP per capita"       		AS REAL) AS log_gdp_per_capita
FROM stg_world_happiness_raw;


-- Internet Usage (Kaggle) → tidy (% → 0–1)
DROP TABLE IF EXISTS stg_internet_usage;
CREATE TABLE stg_internet_usage AS
SELECT
  TRIM(Code)   AS iso3,
  TRIM(Entity) AS country_name,
  CAST(Year AS INT) AS year,
  CAST("Individuals using the Internet (% of population)" AS REAL)/100.0 AS internet_usage
FROM stg_internet_usage_raw
WHERE Year BETWEEN 2005 AND 2021;

-- GII (wide) → long for 2005–2021
DROP TABLE IF EXISTS stg_gender_inequality_long;
CREATE TABLE stg_gender_inequality_long AS
SELECT TRIM(Country) AS country, TRIM(ISO3) AS iso3, TRIM(Continent) AS continent,
       TRIM("Human Development Groups") AS human_dev_zone,
       TRIM("UNDP Developing Regions")  AS undp_dev_region,
       2005 AS year, CAST("Gender Inequality Index (2005)" AS REAL) AS gii_score
FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2006,CAST("Gender Inequality Index (2006)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2007,CAST("Gender Inequality Index (2007)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2008,CAST("Gender Inequality Index (2008)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2009,CAST("Gender Inequality Index (2009)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2010,CAST("Gender Inequality Index (2010)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2011,CAST("Gender Inequality Index (2011)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2012,CAST("Gender Inequality Index (2012)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2013,CAST("Gender Inequality Index (2013)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2014,CAST("Gender Inequality Index (2014)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2015,CAST("Gender Inequality Index (2015)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2016,CAST("Gender Inequality Index (2016)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2017,CAST("Gender Inequality Index (2017)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2018,CAST("Gender Inequality Index (2018)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2019,CAST("Gender Inequality Index (2019)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2020,CAST("Gender Inequality Index (2020)" AS REAL) FROM stg_gender_inequality_raw
UNION ALL SELECT TRIM(Country),TRIM(ISO3),TRIM(Continent),TRIM("Human Development Groups"),TRIM("UNDP Developing Regions"),2021,CAST("Gender Inequality Index (2021)" AS REAL) FROM stg_gender_inequality_raw;


-- =========================================================
-- C) COUNTRY MAP + FILTERED STAGING (only 6 countries; 2005–2021)
-- =========================================================

-- Build a robust name→ISO3 map from GII (plus common US variants)
DROP TABLE IF EXISTS country_map;
CREATE TABLE country_map AS
SELECT DISTINCT TRIM(country) AS raw_name,
       TRIM(iso3) AS iso3,
       CASE WHEN TRIM(iso3)='USA' THEN 'United States' ELSE TRIM(country) END AS std_name
FROM stg_gender_inequality_long;
INSERT OR IGNORE INTO country_map (raw_name, iso3, std_name) VALUES
 ('United States','USA','United States'),
 ('United States of America','USA','United States'),
 ('USA','USA','United States');

 -- Women in STEM (6 countries 2005–2021)
DROP TABLE IF EXISTS stg_women_stem_norm;
CREATE TABLE stg_women_stem_norm AS
SELECT m.iso3, m.std_name AS country_name,
       s.year, s.field,
       s.female_enrol_rate, s.female_grad_rate, s.gender_gap_index
FROM stg_women_stem s
JOIN country_map m       ON s.country = m.raw_name
JOIN country_whitelist w ON w.iso3    = m.iso3
WHERE s.year BETWEEN 2005 AND 2021;

-- World Happiness (6 countries 2005–2021)
DROP TABLE IF EXISTS stg_world_happiness_norm;
CREATE TABLE stg_world_happiness_norm AS
SELECT m.iso3, m.std_name AS country_name,
       h.year,
	   h.happiness_score,
       h.social_support,
       h.corruption_perception,
       h.freedom,
       h.log_gdp_per_capita
FROM stg_world_happiness h
JOIN country_map m       ON h.country = m.raw_name
JOIN country_whitelist w ON w.iso3    = m.iso3
WHERE h.year BETWEEN 2005 AND 2021;

-- Internet usage (already ISO3) → keep only 6 countries
DROP TABLE IF EXISTS stg_internet_usage_norm;
CREATE TABLE stg_internet_usage_norm AS
SELECT iu.iso3, iu.country_name, iu.year, iu.internet_usage
FROM stg_internet_usage iu
JOIN country_whitelist w ON w.iso3 = iu.iso3
WHERE iu.year BETWEEN 2005 AND 2021;

-- GII (6 countries 2005–2021)
DROP TABLE IF EXISTS stg_gender_inequality_norm;
CREATE TABLE stg_gender_inequality_norm AS
SELECT g.iso3, g.country AS country_name,
       g.year, g.gii_score,
       g.continent, g.human_dev_zone, g.undp_dev_region
FROM stg_gender_inequality_long g
JOIN country_whitelist w ON w.iso3 = g.iso3
WHERE g.year BETWEEN 2005 AND 2021;


-- =========================================================
-- D) STAR SCHEMA DDL
-- =========================================================
--dim_country
DROP TABLE IF EXISTS dim_country;
CREATE TABLE dim_country (
  CountryCode   TEXT PRIMARY KEY,
  Name          TEXT,
  Continent     TEXT,
  HumanDevZone  TEXT,
  UNDPDevRegion TEXT
);

--dim_time
DROP TABLE IF EXISTS dim_time;
CREATE TABLE dim_time (
  TimeID INTEGER PRIMARY KEY,
  Year   INTEGER UNIQUE
);

--dim_field
DROP TABLE IF EXISTS dim_field;
CREATE TABLE dim_field (
  FieldID INTEGER PRIMARY KEY,
  Name    TEXT UNIQUE
);

--fact_representation
DROP TABLE IF EXISTS fact_representation;
CREATE TABLE fact_representation (
  CountryCode     TEXT    NOT NULL,
  TimeID          INTEGER NOT NULL,
  FieldID         INTEGER NOT NULL,  
  FemaleEnrolRate REAL,
  FemaleGradRate  REAL,
  GenderGapIndex  REAL,
  HappinessScore  REAL,
  InternetUsage         REAL,
  SocialSupport         REAL,
  CorruptionPerception  REAL,
  Freedom               REAL,
  LogGDPPerCapita          REAL,
  GIIScore              REAL,
  PRIMARY KEY (CountryCode, TimeID, FieldID),
  FOREIGN KEY (CountryCode)    REFERENCES dim_country(CountryCode),
  FOREIGN KEY (TimeID)         REFERENCES dim_time(TimeID),
  FOREIGN KEY (FieldID)        REFERENCES dim_field(FieldID)
);


-- =========================================================
-- E) LOAD DIMENSIONS
-- =========================================================

-- dim_country from GII descriptors (authoritative ISO3 + geo)
INSERT OR IGNORE INTO dim_country (CountryCode, Name, Continent, HumanDevZone, UNDPDevRegion)
SELECT DISTINCT iso3, country_name, continent, human_dev_zone, undp_dev_region
FROM stg_gender_inequality_norm;

-- dim_time from years present across study (use women_stem as anchor)
INSERT OR IGNORE INTO dim_time (Year)
SELECT DISTINCT year
FROM stg_women_stem_norm
ORDER BY year;

-- dim_field from STEM fields
INSERT OR IGNORE INTO dim_field (Name)
SELECT DISTINCT field
FROM stg_women_stem_norm
WHERE field IS NOT NULL;

-- =========================================================
-- F) LOAD FACT (Country × Year × Field)
-- =========================================================
INSERT OR IGNORE INTO fact_representation (
  CountryCode, TimeID, FieldID,
  FemaleEnrolRate, FemaleGradRate, 
  GenderGapIndex, HappinessScore,
  InternetUsage, SocialSupport, CorruptionPerception, Freedom,
  LogGDPPerCapita, GIIScore
)
SELECT DISTINCT
  c.CountryCode,
  tt.TimeID,
  f.FieldID,
  ws.female_enrol_rate,
  ws.female_grad_rate,
  ws.gender_gap_index,
  wh.happiness_score,
  iu.internet_usage           AS InternetUsage,
  wh.social_support           AS SocialSupport,
  wh.corruption_perception    AS CorruptionPerception,
  wh.freedom                  AS Freedom,
  wh.log_gdp_per_capita       AS LogGDPPerCapita,
  g.gii_score                 AS GIIScore
FROM stg_women_stem_norm ws
JOIN dim_country c ON c.CountryCode = ws.iso3
JOIN dim_time    tt ON tt.Year      = ws.year
JOIN dim_field   f  ON f.Name       = ws.field
LEFT JOIN stg_gender_inequality_norm g
       ON g.iso3 = ws.iso3      AND g.year      = ws.year
LEFT JOIN stg_world_happiness_norm wh
		ON wh.iso3 = ws.iso3 AND wh.year = ws.year
LEFT JOIN stg_internet_usage_norm iu
		ON iu.iso3 = ws.iso3 AND iu.year = ws.year;
	  
-- =========================================================
-- G) QA — quick integrity checks
-- =========================================================

-- Expect only the 6 countries
SELECT COUNT(DISTINCT CountryCode) AS countries_in_dim_country FROM dim_country;

-- Year range present
SELECT MIN(Year) AS min_year, MAX(Year) AS max_year FROM dim_time;

-- Foreign key orphan checks (should all be zero rows)
SELECT 'country_fk_missing' AS issue, COUNT(*) AS n
FROM fact_representation f
LEFT JOIN dim_country d ON d.CountryCode = f.CountryCode
WHERE d.CountryCode IS NULL

UNION ALL
SELECT 'time_fk_missing', COUNT(*)
FROM fact_representation f
LEFT JOIN dim_time t ON t.TimeID = f.TimeID
WHERE t.TimeID IS NULL

UNION ALL
SELECT 'field_fk_missing', COUNT(*)
FROM fact_representation f
LEFT JOIN dim_field x ON x.FieldID = f.FieldID
WHERE x.FieldID IS NULL;

-- Drop raw staging tables
DROP TABLE IF EXISTS stg_women_stem_raw;
DROP TABLE IF EXISTS stg_world_happiness_raw;
DROP TABLE IF EXISTS stg_gender_inequality_raw;
DROP TABLE IF EXISTS stg_internet_usage_raw;

-- Drop intermediate cleaned staging
DROP TABLE IF EXISTS stg_women_stem;
DROP TABLE IF EXISTS stg_world_happiness;
DROP TABLE IF EXISTS stg_internet_usage;
DROP TABLE IF EXISTS stg_gender_inequality_long;

-- Drop normalized staging
DROP TABLE IF EXISTS stg_women_stem_norm;
DROP TABLE IF EXISTS stg_world_happiness_norm;
DROP TABLE IF EXISTS stg_internet_usage_norm;
DROP TABLE IF EXISTS stg_gender_inequality_norm;

-- Drop helper maps
DROP TABLE IF EXISTS country_map;
DROP TABLE IF EXISTS country_whitelist;

