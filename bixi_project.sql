/*

Bixi Project - Part 1 - Data Analysis in SQL
April 26, 2022
author: William Huang
email: wchuang379@gmail.com

*/


/* QUESTION 1 */

-- 1.total number of trips in the year 2016
-- last month of trips in November, so we can count all trips with  start date in 2016
-- 3,917,401 total trips
SELECT 
    COUNT(id) AS total_trips
FROM
    trips
WHERE
    YEAR(start_date) = 2016;
    
-- 2. total number of trips in the year 2017
-- 4,666,765 total trips
SELECT 
    COUNT(id) AS total_trips
FROM
    trips
WHERE
    YEAR(start_date) = 2017;

-- 3. total number of trips for the year of 2016 broken down by month
SELECT 
    MONTH(start_date) AS month, COUNT(id) AS total_trips
FROM
    trips
WHERE
    YEAR(start_date) = 2016
GROUP BY MONTH(start_date);

-- 4. total number of trips for the year of 2017 broken down by month
SELECT 
    MONTH(start_date) AS month, COUNT(id) AS total_trips
FROM
    trips
WHERE
    YEAR(start_date) = 2017
GROUP BY MONTH(start_date);

-- 5. average number of trips a day for each year-month combination in the dataset
SELECT 
    year, month, AVG(sum_daily_trips) AS avg_daily_trips
FROM
    (SELECT 
        YEAR(start_date) AS year,
            MONTH(start_date) AS month,
            DAY(start_date) AS day,
            COUNT(id) AS sum_daily_trips
    FROM
        trips
    GROUP BY year , month , day) AS daily_trips
GROUP BY year , month;

-- 6. create a table with the results from previous question
DROP TABLE IF EXISTS trips_overview;
CREATE TABLE trips_overview (year INT, month INT, avg_daily_trips FLOAT (10,2));
INSERT INTO trips_overview (year, month, avg_daily_trips)
VALUES
(2016, 4, 11870.19),
(2016, 5, 18099.26),
(2016, 6, 21050.10),
(2016, 7, 22556.39),
(2016, 8, 21702.52),
(2016, 9, 20675.43),
(2016, 10, 12660.65),
(2016, 11, 10008.60),
(2017, 4, 12228.88),
(2017, 5, 18949.90),
(2017, 6, 24727.83),
(2017, 7, 27765.55),
(2017, 8, 27094.77),
(2017, 9, 24395.03),
(2017, 10, 18048.58),
(2017, 11, 9986.27);

-- describe table
DESC trips_overview;

-- check table
SELECT * FROM trips_overview;



/* QUESTION 2 */

-- 1. total number of trips in the year 2017 broken down by membership status (member/non-member)
-- members:3,784,682 trips
-- non-members: 882,083 trips
SELECT 
    is_member, COUNT(id) AS total_trips
FROM
    trips
WHERE
    YEAR(start_date) = 2017
GROUP BY is_member;

-- 2. percentage of total trips by members for the year 2017 broken down by month
SELECT 
    MONTH(start_date) AS month,
    COUNT(DISTINCT id) * 100.0 / (SELECT 
            COUNT(DISTINCT id)
        FROM
            trips
        WHERE
            YEAR(start_date) = 2017
                AND is_member = 1) AS percentage_trips_members
FROM
    trips
WHERE
    YEAR(start_date) = 2017
        AND is_member = 1
GROUP BY MONTH(start_date);



/* QUESTION 3 */

-- please refer to the report



/* QUESTION 4 */

-- 1. names of the 5 most popular starting station (without using a subquery)
-- Run time: 11.853 sec
SELECT DISTINCT
    (trips.start_station_code) AS station_code,
    stations.name AS start_station
FROM
    stations
        INNER JOIN
    trips ON stations.code = trips.start_station_code
GROUP BY trips.start_station_code , start_station
ORDER BY COUNT(trips.start_station_code) DESC
LIMIT 5;
    
    
-- 2. answer the same question as 4.1 using a subquery
-- Run time: 3.906 sec
-- Joining tables take time and resources. Because we filtered and aggregated before joining the tables here, the run time was shorter by about 8 secs.
SELECT 
    station_code, stations.name AS start_station
FROM
    (SELECT 
        trips.start_station_code AS station_code
    FROM
        trips
    GROUP BY station_code
    ORDER BY COUNT(station_code) DESC
    LIMIT 5) AS station_agg
        INNER JOIN
    stations ON station_agg.station_code = stations.code;
    


/* QUESTION 5 */

/*
If we break up the hours of the day as follows:

BETWEEN 7 AND 11 = morning
BETWEEN 12 AND 16 = afternoon
BETWEEN 17 AND 21 = evening
EVERYTHING ELSE = night

*/
       
-- 1. how is the number of starts and ends distributed for Mackay/de Maisonneuve station throughout the day

-- starting station
SELECT
    start_station_code AS 'Mackay / de Maisonneuve',
    CASE
        WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
        WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
        WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
        ELSE 'night'
    END AS 'time_of_day',
    COUNT('time_of_day') AS total_num_start
FROM trips
    WHERE
        start_station_code = 6100
GROUP BY CASE
    WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
    WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
    WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
    ELSE 'night'
END;

-- end station
SELECT
    end_station_code AS 'Mackay / de Maisonneuve',
    CASE
        WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN 'morning'
        WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN 'afternoon'
        WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN 'evening'
        ELSE 'night'
    END AS 'time of day',
    COUNT('time of day') AS total_num_end
FROM trips
    WHERE
        end_station_code = 6100
GROUP BY CASE
    WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN 'morning'
    WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN 'afternoon'
    WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN 'evening'
    ELSE 'night'
END;

-- 2. please refer to the report



/* QUESTION 6 */

-- we want to see all stations with at least 10% of trips being round trips
-- a round trip is defined by those that start and end in the same station
-- we will only consider stations with at least 500 starting trips

-- 1. count the number of starting trips per station
SELECT 
    stations.code, stations.name, number_start_trips
FROM
    (SELECT 
        trips.start_station_code AS station_code,
            COUNT(trips.start_station_code) AS number_start_trips
    FROM
        trips
    GROUP BY station_code) AS trips_agg
        INNER JOIN
    stations ON station_code = stations.code;

-- 2. count, for each station, the number of round trips
SELECT 
    stations.code, stations.name, number_round_trips
FROM
    (SELECT 
        trips.start_station_code AS station_start,
        trips.end_station_code AS station_end,
            COUNT(*) AS number_round_trips
    FROM
        trips
    WHERE
        trips.start_station_code = trips.end_station_code
    GROUP BY station_start) AS round_trips_agg
        INNER JOIN
    stations ON station_start = stations.code;

-- 3. combine the above queries and calculate the fraction of round trips to the total number of strating trips for each station

SELECT stations.code, stations.name AS station_name, (number_round_trips / number_start_trips) AS round_over_start
FROM
(SELECT 
        trips.start_station_code AS station_code,
            COUNT(trips.start_station_code) AS number_start_trips
    FROM
        trips
    GROUP BY station_code) AS trips_agg
INNER JOIN
    (SELECT 
        trips.start_station_code AS station_start,
        trips.end_station_code AS station_end,
            COUNT(*) AS number_round_trips
    FROM
        trips
    WHERE
        trips.start_station_code = trips.end_station_code
    GROUP BY station_start) AS round_trips_agg
ON station_code = station_start
INNER JOIN stations
ON station_code = stations.code;

-- 4. filter she stations with at least 500 trips orginating from them and having at least 10% of their trips as round trips

SELECT 
    stations.code,
    stations.name AS station_name,
    number_start_trips,
    (number_round_trips / number_start_trips) * 100.0 AS percentage_round_trip
FROM
    (SELECT 
        trips.start_station_code AS station_code,
            COUNT(trips.start_station_code) AS number_start_trips
    FROM
        trips
    GROUP BY station_code) AS trips_agg
        INNER JOIN
    (SELECT 
        trips.start_station_code AS station_start,
            trips.end_station_code AS station_end,
            COUNT(*) AS number_round_trips
    FROM
        trips
    WHERE
        trips.start_station_code = trips.end_station_code
    GROUP BY station_start) AS round_trips_agg ON station_code = station_start
        INNER JOIN
    stations ON station_code = stations.code
WHERE
    (number_start_trips >= 500)
        AND ((number_round_trips / number_start_trips) * 100.0 >= 10.0);

-- 5. please refer to report





