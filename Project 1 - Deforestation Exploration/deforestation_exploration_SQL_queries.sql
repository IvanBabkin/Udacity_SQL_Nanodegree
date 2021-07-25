-- Creating initial view.

/* Drop VIEW if it already exists */
DROP VIEW IF EXISTS forestation;

/* Creating the view */
CREATE VIEW forestation AS
SELECT fa.country_code, fa.country_name country,
  fa.year, fa.forest_area_sqkm forest_area,
  (la.total_area_sq_mi * 2.59) total_land_area,
  r.region, r.income_group income_group,
  100 * (fa.forest_area_sqkm /
  (la.total_area_sq_mi * 2.59)) AS foreset_land_percent
FROM forest_area fa
JOIN land_area la
ON fa.country_code = la.country_code AND fa.year = la.year
JOIN regions r
ON r.country_code = la.country_code;
/* Converted total area from miles to km for unit consistency */

/* Checking the results */
SELECT * FROM forestation;

-- Part 1 Global situation
-- a) The total forest area (in sq km) of the world in 1990.
SELECT forest_area
FROM forestation
WHERE year = 1990 AND region = 'World';

-- b) The total forest area (in sq km) of the world in 2016.
SELECT forest_area
FROM forestation
WHERE year = 2016 AND region = 'World';

-- c) The change (in sq km) in the forest area of the world from 1990 to 2016.
SELECT now.forest_area - prev.forest_area difference
FROM forestation now
JOIN forestation prev
ON (now.year = 2016 AND prev.year = 1990
  AND now.region = 'World' AND prev.region = 'World');

/* Additional query to check the calculation manually */
SELECT forest_area
FROM forestation
WHERE region = 'World' AND (year = 2016 OR year = 1990);

-- d) The percent change in forest area of the world between 1990 and 2016.
SELECT 100 * (now.forest_area - prev.forest_area) / prev.forest_area difference
FROM forestation now
JOIN forestation prev
ON (now.year = 2016 AND prev.year = 1990
  AND now.region = 'World' AND prev.region = 'World');

-- e) Comparing the amount of forest area lost between 1990 and 2016 to
-- total areas of countries in 2016.
/* Checking the closest value less than the lost area */
SELECT country, total_land_area
FROM forestation
WHERE year = 2016 AND (total_land_area <
  ABS((SELECT x.forest_area - y.forest_area difference
    FROM forestation x
    JOIN forestation y
    ON (x.year = 1990 AND y.year = 2016
      AND x.region = 'World' AND y.region = 'World'))))
ORDER BY 2 DESC
LIMIT 1;

/* Checking the closest value more than the lost area */
SELECT country, total_land_area
FROM forestation
WHERE year = 2016 AND (total_land_area >
  ABS((SELECT x.forest_area - y.forest_area difference
    FROM forestation x
    JOIN forestation y
    ON (x.year = 1990 AND y.year = 2016
      AND x.region = 'World' AND y.region = 'World'))))
ORDER BY 2
LIMIT 1;

/* Additional query to manually check area values */
SELECT country, total_land_area
FROM forestation
WHERE year = 2016
ORDER BY total_land_area;

-- Part 2 Regional Outlook
-- Creating a new table for regional outlook.

/* Drop TABLE if it already exists */
DROP TABLE IF EXISTS region_outlook;

/* Creating the table */
CREATE TABLE region_outlook AS
  SELECT region, year, ROUND(CAST(100 * (SUM(forest_area) / SUM(total_land_area))
  AS NUMERIC),2) AS region_forest_percent
FROM forestation
GROUP BY 1,2
ORDER BY 2;

/* Checking the results */
SELECT * FROM region_outlook;

-- a)
-- Forest land as a percentage of the entire world in 2016.
SELECT region_forest_percent
FROM region_outlook
WHERE year = 2016 AND region = 'World';

-- Region with the highest percent of forestation in 2016, and with the lowest
-- percent of forestation.

/* Highest percent of forestation */
SELECT region, region_forest_percent
FROM region_outlook
WHERE year = 2016 AND region != 'World'
ORDER BY 2 DESC
LIMIT 1;

/* Lowest percent of forestation */
SELECT region, region_forest_percent
FROM region_outlook
WHERE year = 2016 AND region != 'World'
ORDER BY 2
LIMIT 1;

-- b)
-- Forest land as a percentage of the entire world in 1990.
SELECT region_forest_percent
FROM region_outlook
WHERE year = 1990 AND region = 'World';

-- Region with the highest percent of forestation in 2016, and with the lowest
-- percent of forestation.

/* Highest percent of forestation */
SELECT region, region_forest_percent
FROM region_outlook
WHERE year = 1990 AND region != 'World'
ORDER BY 2 DESC
LIMIT 1;

/* Lowest percent of forestation */
SELECT region, region_forest_percent
FROM region_outlook
WHERE year = 1990 AND region != 'World'
ORDER BY 2
LIMIT 1;

-- c) Comparing forest area for all regions in 2016 and 1990.
SELECT x.region, x.region_forest_percent forestation_1990,
  y.region_forest_percent forestation_2016
FROM region_outlook x
JOIN region_outlook y
ON x.region = y.region
WHERE  x.year = 1990 AND x.region != 'World'
  AND y.year = 2016 AND y.region != 'World'
ORDER BY 2 DESC;

-- Part 3 Country-Level Detail
-- A. Success Stories
-- a) Top 5 countries that saw the largest amount increase in forest area from 1990 to 2016.
SELECT now.country, now.region,
  now.forest_area - prev.forest_area difference
FROM forestation now
JOIN forestation prev
ON now.year = 2016 AND prev.year = 1990 AND now.country = prev.country
WHERE (now.forest_area - prev.forest_area) IS NOT NULL
ORDER BY 3 DESC
LIMIT 5;

-- b) Top 5 countries that saw the largest percentage increase in forest area from 1990 to 2016.
SELECT now.country, now.region,
  ROUND(CAST(((now.forest_area - prev.forest_area) / prev.forest_area * 100)
  AS NUMERIC), 2) percentage_difference
FROM forestation now
JOIN forestation prev
ON now.year = 2016 AND prev.year = 1990 AND now.country = prev.country
WHERE (now.forest_area - prev.forest_area) IS NOT NULL
ORDER BY 3 DESC
LIMIT 5;

-- c) Top 5 countries that saw the largest amount decrease in forest area from 1990 to 2016.
SELECT now.country, now.region,
  now.forest_area - prev.forest_area difference
FROM forestation now
JOIN forestation prev
ON now.year = 2016 AND prev.year = 1990 AND now.country = prev.country
WHERE (now.forest_area - prev.forest_area) IS NOT NULL
  AND now.country != 'World'
ORDER BY 3
LIMIT 5;

-- d) Top 5 countries that saw the largest percentage decrease in forest area from 1990 to 2016.
SELECT now.country, now.region,
  ROUND(CAST(((now.forest_area - prev.forest_area) / prev.forest_area * 100)
  AS NUMERIC), 2) percentage_difference
FROM forestation now
JOIN forestation prev
ON now.year = 2016 AND prev.year = 1990 AND now.country = prev.country
WHERE (now.forest_area - prev.forest_area) IS NOT NULL
  AND now.country != 'World'
ORDER BY 3
LIMIT 5;

-- e) Countries grouped by percent forestation in quartiles.
SELECT distinct(quartiles), COUNT(country) OVER (PARTITION BY quartiles)
FROM (SELECT country,
    CASE WHEN foreset_land_percent <= 25 THEN '0-25'
    WHEN foreset_land_percent <= 50 AND foreset_land_percent > 25 THEN '25-50'
    WHEN foreset_land_percent <= 75 AND foreset_land_percent > 50 THEN '51-75'
    ELSE '75-100' END AS quartiles
  FROM forestation
  WHERE foreset_land_percent IS NOT NULL
  AND year = 2016 AND country != 'World') sub
ORDER BY quartiles;

-- f) Top Quartile (75-100%) Countries in 2016
SELECT country, region, ROUND(CAST(foreset_land_percent AS NUMERIC),2)
FROM forestation
WHERE foreset_land_percent > 75 AND year = 2016
ORDER BY 3 DESC;
