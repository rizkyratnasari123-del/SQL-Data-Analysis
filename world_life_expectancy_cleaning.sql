/* =========================================================
   PROJECT: World Life Expectancy – Data Cleaning
   AUTHOR : Rizky Ratna Sari
   PURPOSE: Perform full data cleaning workflow including:
            - Duplicate removal
            - Missing categorical handling
            - Missing numeric interpolation
   ========================================================= */


/* =========================================================
   1. CHECK ORIGINAL DATA
   ========================================================= */
SELECT *
FROM world_life_expectancy.world_life_expectancy;


/* =========================================================
   2. FIND DUPLICATES (Country + Year)
   ========================================================= */
SELECT 
    Country,
    Year,
    CONCAT(Country, Year) AS country_year,
    COUNT(CONCAT(Country, Year)) AS duplicate_count
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;


/* =========================================================
   3. IDENTIFY DUPLICATE ROWS USING ROW_NUMBER
   ========================================================= */
SELECT *
FROM (
    SELECT 
        Row_ID,
        CONCAT(Country, Year) AS country_year,
        ROW_NUMBER() OVER(
            PARTITION BY CONCAT(Country, Year)
            ORDER BY CONCAT(Country, Year)
        ) AS row_num
    FROM world_life_expectancy
) AS row_table
WHERE row_num > 1;


/* =========================================================
   4. DELETE DUPLICATES
   ========================================================= */
DELETE FROM world_life_expectancy
WHERE Row_ID IN (
    SELECT Row_ID
    FROM (
        SELECT 
            Row_ID,
            ROW_NUMBER() OVER(
                PARTITION BY CONCAT(Country, Year)
                ORDER BY CONCAT(Country, Year)
            ) AS row_num
        FROM world_life_expectancy
    ) AS row_table
    WHERE row_num > 1
);


/* =========================================================
   5. CHECK MISSING STATUS VALUES
   ========================================================= */
SELECT *
FROM world_life_expectancy
WHERE Status = '';


/* =========================================================
   6. FILL MISSING STATUS USING SAME COUNTRY DATA
   ========================================================= */

-- Fill as Developed
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
  AND t2.Status = 'Developed';

-- Fill as Developing
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
  AND t2.Status = 'Developing';


/* =========================================================
   7. CHECK MISSING LIFE EXPECTANCY VALUES
   ========================================================= */
SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
WHERE `Life expectancy` = '';


/* =========================================================
   8. INTERPOLATE MISSING LIFE EXPECTANCY
   Using average of previous and next year
   ========================================================= */
SELECT 
    t1.Country,
    t1.Year,
    t1.`Life expectancy`,
    t2.`Life expectancy` AS prev_year,
    t3.`Life expectancy` AS next_year,
    (t2.`Life expectancy` + t3.`Life expectancy`) / 2 AS avg_life_expectancy
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
   AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
   AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = '';


/* =========================================================
   9. UPDATE LIFE EXPECTANCY WITH INTERPOLATED VALUE
   ========================================================= */
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
   AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
   AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` =
    ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)
WHERE t1.`Life expectancy` = '';
