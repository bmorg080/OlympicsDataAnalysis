-- The olympics_history table conatains data from Athens in 1896 to Rio in 2016.
-- Each row corresponds to an individual athlete competing in an individual Olympic event (athlete-events).
-- Data condensed to fit GitHub's file size limitations
-- From https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results. Data scraped  
-- from http://www.sports-reference.com/ in May 2018.

SELECT * FROM olympics_history;
-- How many Olympic games have been held?
SELECT COUNT(DISTINCT games) AS total_olympic_games
    FROM olympics_history;
	
-- List down all Olympics games held so far.
SELECT DISTINCT year, season, city
    FROM olympics_history 
    ORDER BY YEAR;
	
-- Total number of nations who participated in each olympic game
WITH all_countries AS
        (SELECT games, nr.region
        FROM olympics_history oh
        JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
        GROUP BY games, nr.region)
    SELECT games, COUNT(1) AS total_countries
    FROM all_countries
    GROUP BY games
    ORDER BY games;
	
-- Identify sports which were played in all summer olympics
WITH t1 AS
	(SELECT COUNT(DISTINCT games) AS total_summer_games
	 FROM olympics_history
	WHERE season = 'Summer'),
t2 AS
	(SELECT DISTINCT sport, games
	FROM olympics_history
	WHERE season = 'Summer' ORDER BY games),
t3 AS
	(SELECT sport, COUNT(games) as no_of_games
	FROM t2
	GROUP BY sport)
SELECT * FROM t3
JOIN t1 ON t1.total_summer_games = t3.no_of_games;

-- Which year saw the highest and lowest number of countries participating in the olympics
WITH all_countries as (
		SELECT games, nr.region
		FROM olympics_history oh
		JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
		GROUP BY games, nr.region),
	total_countries as (
		SELECT games, count(1) as total_countries
		FROM all_countries
		GROUP BY games)
	SELECT DISTINCT 
	concat(FIRST_VALUE(games) OVER(ORDER BY total_countries)
	, ' - '
	, FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) as Lowest_Countries,
	concat(FIRST_VALUE(games) OVER(order by total_countries DESC)
	, ' - '
	, FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS Highest_Countries
	FROM total_countries
	ORDER BY 1;
	
-- Which nation has participated in all of the olympic games?
WITH total_games as
		(SELECT  count(DISTINCT games) AS total_games
		 FROM olympics_history),
	countries AS
		(SELECT games, nr.region AS country
		FROM olympics_history oh
		JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
		GROUP BY games, nr.region),
	countries_participated AS
		(SELECT country, COUNT(1) AS total_participated_games
		FROM countries
		GROUP BY country)
SELECT cp.*
FROM countries_participated cp
JOIN total_games tg ON tg.total_games = cp.total_participated_games
ORDER BY 1;

-- Which sport were played only once in the olympics?
WITH t1 AS 
		(SELECT DISTINCT games, sport
		FROM olympics_history),
	t2 AS
		(SELECT sport, COUNT(1) AS number_of_games
		FROM t1
		GROUP BY sport)
	SELECT t2.*, t1.games
	FROM t2
	JOIN t1 ON t1.sport = t2.sport
	WHERE t2.number_of_games = 1
	ORDER BY t1.sport;
	
	
-- Oldest Athletes to win a gold medal
WITH temp AS 
		(SELECT name, sex, cast(CASE WHEN age = 'NA' THEN '0' ELSE age END AS INT) AS age
		, team, games, city, event, medal
		FROM olympics_history),
	ranking AS
		(SELECT *, rank() OVER(ORDER BY age DESC) AS rnk
		FROM temp
		WHERE medal='Gold')
	SELECT *
	FROM ranking
	WHERE rnk = 1;
	
	
-- Find ratio of male and female athletes who participated across all olympic games
WITH t1 AS
		(SELECT sex, count(1) AS cnt
		 FROM olympics_history
		 GROUP BY sex),
	t2 AS 
		(SELECT *, row_number() OVER(ORDER BY cnt) AS RN
		  FROM t1),
	min_cnt AS
		(SELECT cnt FROM t2 WHERE rn = 1),
	max_cnt AS 
		(SELECT cnt FROM t2 WHERE rn = 2)
	SELECT concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) AS ratio
	FROM min_cnt, max_cnt;
		
		
--  Top 5 athletes who have won the most medals
WITH t1 AS 
		(SELECT name, team, count(1) AS total_medals
		FROM olympics_history
		WHERE medal in ('Gold', 'Silver', 'Bronze')
		GROUP BY name, team
		ORDER BY total_medals DESC),
	t2 AS
		(SELECT *, dense_rank() OVER (ORDER BY total_medals DESC) AS rnk
		FROM t1)
	SELECT name, team, total_medals
	from t2
	WHERE rnk <= 5;
	 
