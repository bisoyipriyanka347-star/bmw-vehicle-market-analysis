CREATE DATABASE BMW_DATA;
USE BMW_DATA;
CREATE TABLE bmwdata (
    model VARCHAR(100),
    year INT,
    price INT,
    transmission VARCHAR(50),
    mileage VARCHAR(50),
    fuelType VARCHAR(50),
    tax VARCHAR(50),
    mpg VARCHAR(50),
    engineSize VARCHAR(50)
);
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/bmw.csv"
INTO TABLE bmwdata
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SElect * FROM bmwdata;

ALTER TABLE bmwdata
ADD id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

SELECT model, year, price, mileage, engineSize, COUNT(*)
FROM bmwdata
GROUP BY model, year, price, mileage, engineSize
HAVING COUNT(*) > 1;

ALTER TABLE bmwdata
ADD INDEX idx_clean (model, year, price, mileage, engineSize);

DELETE r1
FROM bmwdata r1
JOIN bmwdata r2 
ON r1.model = r2.model
AND r1.year = r2.year
AND r1.price = r2.price
AND r1.mileage = r2.mileage
AND r1.engineSize = r2.engineSize
AND r1.id > r2.id;

UPDATE bmwdata
SET mileage = REPLACE(mileage, ',', '');

ALTER TABLE bmwdata
MODIFY mileage INT;

UPDATE bmwdata
SET tax = NULLIF(REPLACE(tax, ',', ''), '');

ALTER TABLE bmwdata
MODIFY tax INT;

UPDATE bmwdata
SET mpg = NULLIF(mpg, '');

ALTER TABLE bmwdata
MODIFY mpg FLOAT;

UPDATE bmwdata
SET engineSize = NULLIF(engineSize, '');

SELECT engineSize
FROM bmwdata
WHERE engineSize IS NOT NULL
AND engineSize NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

UPDATE bmwdata
SET engineSize = NULL
WHERE engineSize NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

SELECT DISTINCT engineSize
FROM bmwdata
ORDER BY engineSize;

UPDATE bmwdata
SET engineSize = TRIM(engineSize);

UPDATE bmwdata
SET engineSize = NULL
WHERE engineSize = '';

UPDATE bmwdata
SET engineSize = NULL
WHERE engineSize IN ('NULL', 'null', 'N/A', 'na', 'NA');

UPDATE bmwdata
SET engineSize = NULL
WHERE engineSize IS NOT NULL
AND engineSize NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

SELECT engineSize
FROM bmwdata
WHERE engineSize IS NOT NULL
AND engineSize NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

SET sql_mode = '';

ALTER TABLE bmwdata
MODIFY engineSize FLOAT;

DELETE FROM bmwdata
WHERE price IS NULL
   OR year IS NULL
   OR model IS NULL;
   
UPDATE bmwdata
SET model = TRIM(LOWER(model));

UPDATE bmwdata
SET transmission = TRIM(LOWER(transmission));

UPDATE bmwdata
SET fuelType = TRIM(LOWER(fuelType));

DELETE FROM bmwdata
WHERE price < 500 OR price > 100000;

DELETE FROM bmwdata
WHERE mileage < 0 OR mileage > 300000;

CREATE TABLE bmw_clean AS
SELECT 
    model,
    year,
    price,
    transmission,
    mileage,
    fuelType,
    tax,
    mpg,
    engineSize
FROM bmwdata;

ALTER TABLE bmw_clean ADD mileage_bucket VARCHAR(20);

UPDATE bmw_clean
SET mileage_bucket = CASE
    WHEN mileage < 20000 THEN '0-20k'
    WHEN mileage < 40000 THEN '20k-40k'
    WHEN mileage < 60000 THEN '40k-60k'
    ELSE '60k+'
END;

ALTER TABLE bmw_clean ADD price_category VARCHAR(20);

UPDATE bmw_clean
SET price_category = CASE
    WHEN price < 15000 THEN 'Low'
    WHEN price < 30000 THEN 'Medium'
    ELSE 'High'
END;

-- 1️ Total BMW listings
SELECT COUNT(*) AS total_listings
FROM bmw_clean;

-- 2️ Distinct BMW models
SELECT DISTINCT model
FROM bmw_clean;

SELECT COUNT(DISTINCT model) AS total_models
FROM bmw_clean;

-- 3️ Average price of BMW cars
SELECT ROUND(AVG(price),2) AS avg_price
FROM bmw_clean;

-- 4️ Transmission type distribution
SELECT transmission, COUNT(*) AS count
FROM bmw_clean
GROUP BY transmission
ORDER BY count DESC;

-- 5️ Fuel type distribution
SELECT fuelType, COUNT(*) AS count
FROM bmw_clean
GROUP BY fuelType
ORDER BY count DESC;

-- 6️ Average price by BMW model
SELECT model, ROUND(AVG(price),0) AS avg_price
FROM bmw_clean
GROUP BY model
ORDER BY avg_price desc;

-- 7 Average mileage by BMW model
SELECT model, ROUND(AVG(mileage),0) AS avg_mileage
FROM bmw_clean
GROUP BY model
ORDER BY avg_mileage desc;

-- 8️ Price trend by year
SELECT year, ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY year
ORDER BY year;

-- 9️ Engine size vs average price
SELECT engineSize, ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY engineSize
ORDER BY engineSize;

-- 10 Mileage bucket vs price
SELECT
    CASE
        WHEN mileage < 20000 THEN '0-20k'
        WHEN mileage < 40000 THEN '20k-40k'
        WHEN mileage < 60000 THEN '40k-60k'
        ELSE '60k+'
    END AS mileage_range,
    ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY mileage_range
ORDER BY avg_price DESC;

-- 1️1 Top 5 most expensive BMW models
SELECT model, MAX(price) AS max_price
FROM bmw_clean
GROUP BY model
ORDER BY max_price DESC
LIMIT 5;

-- 1️2 Cheapest BMW model on average
SELECT model, AVG(price) 
FROM bmw_clean
GROUP BY model
ORDER BY AVG(price)
LIMIT 1;

-- 1️3 Price difference by transmission
SELECT transmission, AVG(price)
FROM bmw_clean
GROUP BY transmission;

-- 1️4 New vs old car price comparison
SELECT
    CASE
        WHEN year >= 2018 THEN 'New'
        ELSE 'Old'
    END AS car_category,
    ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY car_category;

-- 1️5 MPG efficiency analysis
SELECT
    CASE
        WHEN mpg < 30 THEN 'Low MPG'
        WHEN mpg BETWEEN 30 AND 50 THEN 'Medium MPG'
        ELSE 'High MPG'
    END AS mpg_category,
    COUNT(*) AS car_count,
    ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY mpg_category;

CREATE VIEW vw_price_trend AS
SELECT year, ROUND(AVG(price), 0) AS avg_price
FROM bmw_clean
GROUP BY year;

CREATE VIEW vw_model_analysis AS
SELECT
    model,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 0) AS avg_price,
    ROUND(AVG(mileage), 0) AS avg_mileage
FROM bmw_clean
GROUP BY model;


SELECT user, host FROM mysql.user;
ALTER USER 'root'@'localhost'
IDENTIFIED BY 'MyStrongPassword123';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password
BY 'MyStrongPassword123';
FLUSH PRIVILEGES;

SELECT COUNT(*) 
FROM bmw_clean
WHERE engineSize = 6
AND price IS NOT NULL;

SELECT engineSize, price
FROM bmw_clean
WHERE engineSize = 6;

SELECT
    MIN(mileage) AS min_mileage,
    MAX(mileage) AS max_mileage
FROM bmw_clean;

