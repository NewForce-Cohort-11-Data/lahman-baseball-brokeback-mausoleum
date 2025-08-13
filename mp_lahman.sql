-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? -146-
SELECT MAX(yearid) AS max_year,
	MIN(yearid) AS min_year,
	MAX(yearid) - MIN(yearid) AS range_of_years
FROM teams;


-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played? gaedeed01
SELECT DISTINCT(namegiven),
	height,
	g_all,
	name
FROM people
INNER JOIN appearances 
USING(playerid)
INNER JOIN teams
USING(teamid)
WHERE height = (SELECT 
				MIN(height) 
				FROM people);

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT DISTINCT playerid,
	namefirst,
	namelast,
	SUM(salary::NUMERIC::MONEY) AS total_salary
FROM people
JOIN salaries
USING(playerid)
WHERE playerid IN
  (SELECT playerid
    FROM collegeplaying
    WHERE schoolid ILIKE '%vandy%')
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT *
FROM fielding;

                                --PART 1--
 
SELECT playerid,
	yearid,
	teamid,
	pos,
	CASE WHEN pos IN ('OF') THEN 'OF' 
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	WHEN pos IN ('P', 'C') THEN 'Battery'
	ELSE 'other' END AS position_category,
	PO
FROM fielding
WHERE yearid = 2016;

                              --Solution 1--

WITH po_table AS (
	SELECT playerid,
		yearid,
		teamid,
		pos,
		CASE WHEN pos IN ('OF') THEN 'OF' 
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		ELSE 'other' END AS position_category,
	PO
	FROM fielding
	WHERE yearid = 2016)
SELECT position_category,
	SUM(PO) AS total_putouts
FROM po_table
GROUP BY position_category;

                                  --Solution 2 (Combined table)--
								  
WITH po_table AS (
	SELECT playerid,
		yearid,
		teamid,
		pos,
		CASE WHEN pos IN ('OF') THEN 'OF' 
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		ELSE 'other' END AS position_category,
		PO
	FROM fielding
	WHERE yearid = 2016)
SELECT playerid,
	yearid,
	teamid,
	pos,
	position_category,
	SUM(PO) OVER(PARTITION BY position_category) AS total_putouts
FROM po_table
ORDER BY playerid;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
WITH strikeout_table AS(
	SELECT yearid,
		FLOOR(yearid / 10) * 10 AS decade,
		so,
		soa,
		so + soa AS total_strikeouts, 
		g,
		((so+soa) / g) AS strikeouts_per_game,
		ROUND(AVG(((so+soa) / g)) OVER(PARTITION BY yearid), 2) AS avg_strikeouts_game
	FROM teams
	WHERE yearid >= 1920)
SELECT decade,
	ROUND(AVG(avg_strikeouts_game), 2) AS strikeouts_per_decade
FROM strikeout_table
GROUP BY decade
ORDER BY decade;

									--Part 2--

WITH homerun_table AS(
	SELECT yearid,
		FLOOR(yearid / 10) * 10 AS decade,
		hr,
		hra,
		hr + hra AS total_homeruns, 
		g,
		((hr+hra) / g) AS homeruns_per_game,
		ROUND(AVG(((hr+hra) / g)) OVER(PARTITION BY yearid), 2) AS avg_hrs_game
	FROM teams
	WHERE yearid >= 1920)
SELECT decade,
	ROUND(AVG(avg_hrs_game), 2) AS hrs_per_decade
FROM homerun_table
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
SELECT playerid,
	yearid,
	sb,
	sb + cs AS sb_attempts,
	sb::NUMERIC / (sb::NUMERIC + cs::NUMERIC) * 100 AS success_rate
FROM batting
WHERE yearid = 2016
	AND (sb + cs) >=20
ORDER BY success_rate DESC;

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

										--Part 1--
SELECT yearid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
ORDER BY w DESC
LIMIT 1;

										--Part 2--
SELECT yearid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
ORDER BY w
LIMIT 1;

										--Part 3--
SELECT yearid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
ORDER BY w
OFFSET 1 ROW
LIMIT 1;

										--Part 4--
WITH wsw_table AS(
	SELECT yearid, 
		name, 
		w, 
		wswin, 
		MAX(w) OVER(PARTITION BY yearid) AS max_wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016)
SELECT 
	COUNT(CASE WHEN wswin = 'Y' AND w = max_wins THEN name END) AS wsww_count,
	COUNT (DISTINCT yearid)-1 AS total_years,
	ROUND((COUNT(CASE WHEN wswin = 'Y' AND w = max_wins THEN name END)::NUMERIC /
		(COUNT(DISTINCT(yearid))-1)*100), 2) AS percent
FROM wsw_table;

							--Megan's Equation--

SELECT
  COUNT(DISTINCT sp.yearid) AS total_years,
  COUNT(DISTINCT CASE WHEN t.teamid = sp.teamidwinner THEN sp.yearid END) AS wins_and_ws,
  ROUND(COUNT(DISTINCT CASE WHEN t.teamid = sp.teamidwinner THEN sp.yearid END) * 100
    / COUNT(DISTINCT sp.yearid), 2) AS percentage
FROM seriespost AS sp
JOIN teams AS t USING (yearid)
WHERE sp.round = 'WS'
  AND sp.yearID BETWEEN 1970 AND 2016
  AND t.w = (
    SELECT MAX(t2.w)
    FROM teams AS t2
    WHERE t2.yearid = t.yearid);

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
									--Part 1--
SELECT DISTINCT year,
	name AS team,
	t.park,
	h.games,
	h.attendance,
	h.attendance / h.games AS avg_attendance
FROM homegames AS h
JOIN teams AS t
ON team = teamid AND yearid = year
WHERE h.year = 2016
	AND h.games >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

									--Part 2--
SELECT DISTINCT year,
	name,
	t.park,
	h.games,
	h.attendance,
	h.attendance / h.games AS avg_attendance
FROM homegames AS h
JOIN teams AS t
ON team = teamid AND yearid = year
WHERE
	h.year = 2016
	AND h.games >= 10
ORDER BY avg_attendance ASC
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
WITH awards AS (
SELECT p.namefirst,
	p.namelast,
	am1.playerid AS id, 
	am1.lgid AS lgid1, 
	am2.lgid AS lgid2,
	CASE WHEN am1.lgid = 'AL' AND am2.lgid = 'NL' THEN 'both'
		 WHEN am1.lgid = 'NL' AND am2.lgid = 'AL' THEN 'both'
		 END AS both_awards
FROM awardsmanagers AS am1
JOIN awardsmanagers AS am2
USING(playerid)
INNER JOIN people AS p
USING(playerid)
WHERE am1.awardid = 'TSN Manager of the Year'
ORDER BY both_awards NULLS LAST)
SELECT DISTINCT * FROM awards
WHERE both_awards IS NOT NULL;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
SELECT b.yearid, 
	p.namefirst,
	p.namelast,
	hr
FROM people AS p
JOIN batting AS b
USING(playerid)
WHERE b.yearid = 2016
	AND b.hr >=1
	AND (SELECT MAX(hr) FROM batting WHERE playerid = p.playerid) = b.hr
	AND (SELECT MAX(yearid) - MIN(yearid) FROM Batting WHERE playerid = p.playerid) >= 9;
	
-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
WITH wintable AS (
	SELECT s.yearid,
	name,
	w,
	SUM(salary) AS team_salary,
	RANK() OVER(PARTITION BY s.yearid ORDER BY w DESC) AS win_rank,
	RANK() OVER(PARTITION BY s.yearid ORDER BY SUM(salary)DESC) AS salary_rank
FROM salaries AS s
JOIN teams AS t
ON s.teamid = t.teamid 
	AND s.yearid = t.yearid
WHERE t.yearid >= 2000
GROUP BY name, s.yearid, w
ORDER BY s.yearid,w DESC)
SELECT *,
	ABS((salary_rank - win_rank)) AS win_diff,
	AVG(ABS((salary_rank - win_rank))) OVER(PARTITION BY yearid)
FROM wintable
WHERE win_rank = 1 ;

-- 12. In this question, you will explore the connection between number of wins and attendance.

--       i. Does there appear to be any correlation between attendance at home games and number of wins?
SELECT year,
	name,
	h.attendance AS max_attendance,
	RANK() OVER(PARTITION BY h.year ORDER BY h.attendance DESC) AS attendance_rank,
	rank AS season_rank
FROM homegames AS h
JOIN teams AS t
ON h.year = t.yearid AND h.team = t.teamid
WHERE year >= 1970
	AND games > 1
	AND h.attendance = (SELECT MAX(attendance) FROM homegames WHERE h.year = year);

--       ii. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
									--Part 1--
SELECT t1.yearid AS ws_year,
	t1.name AS winner_name,
	t1.attendance AS winner_attendance,
	t2.attendance AS nextyear_attendance,
	t2.attendance - t1.attendance AS difference
FROM teams AS t1
JOIN teams AS t2
	ON t1.teamid = t2.teamid
	AND t1.yearid + 1 = t2.yearid
WHERE t1.wswin = 'Y'
	AND t1.yearid >= 1970;

									--Part 2--

SELECT t1.yearid AS po_year,
	t1.name AS po_name,
	t1.attendance AS po_attendance,
	t2.attendance AS nextyear_attendance,
	t2.attendance - t1.attendance AS difference
FROM teams AS t1
JOIN teams AS t2
	ON t1.teamid = t2.teamid
	AND t1.yearid + 1 = t2.yearid
WHERE t1.divwin = 'Y' OR t1.wcwin = 'Y';
	
-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
								--Part 1--
WITH pitch AS (
SELECT 
	COUNT(DISTINCT CASE WHEN throws = 'L' THEN playerid END) AS lefties,
	COUNT(DISTINCT pit.playerid) AS total
FROM pitching AS pit
JOIN people AS peo
USING(playerid))
SELECT lefties,
	total,
	CAST(ROUND((CAST(lefties AS DECIMAL(10, 2)) / CAST(total AS DECIMAL(10, 2))) * 100, 2) 	AS VARCHAR(10)) || '%' AS left_percentage
FROM pitch;

SELECT playerid
FROM people
WHERE throws = 'R'
INTERSECT
SELECT playerid
FROM pitching;
								--Part 2--
WITH cyyoung AS (
SELECT
	COUNT(CASE WHEN throws = 'L' THEN playerid END) AS lefty_winners,
	COUNT(CASE WHEN throws = 'R' THEN playerid END) AS righty_winners,
	COUNT(playerid) AS total
FROM awardsplayers
JOIN people
USING(playerid)
WHERE awardid ILIKE '%CY Young%')
SELECT lefty_winners,
	righty_winners,
	total,
	CAST(ROUND((CAST(lefty_winners AS DECIMAL(10, 2)) / CAST(total AS DECIMAL(10, 2))) * 	100, 2) AS VARCHAR(10)) || '%' AS win_percentage
FROM cyyoung;

									--Part 3--

WITH hofleft AS (
	SELECT playerid
	FROM pitching AS pit
	WHERE pit.playerid = (SELECT playerid FROM people WHERE throws = 'L' AND pit.playerid 		= playerid)
	INTERSECT
	SELECT playerid
	FROM halloffame),
hofright AS (
	SELECT playerid
	FROM pitching AS pit
	WHERE pit.playerid = (SELECT playerid FROM people WHERE throws = 'R' AND pit.playerid 		= playerid)
	INTERSECT
	SELECT playerid
	FROM halloffame)
SELECT COUNT(hofleft.playerid) AS lefty_count,
	COUNT(hofright.playerid) AS righty_count,
	(SELECT COUNT(playerid) FROM halloffame) AS hof_count
FROM hofleft
FULL JOIN hofright
ON hofleft.playerid = hofright.playerid;


WITH hofleft AS (
	SELECT playerid
	FROM pitching AS pit
	WHERE pit.playerid = (SELECT playerid FROM people WHERE throws = 'L' AND pit.playerid 		= playerid)
	INTERSECT
	SELECT playerid
	FROM halloffame),
hofright AS (
	SELECT playerid
	FROM pitching AS pit
	WHERE pit.playerid = (SELECT playerid FROM people WHERE throws = 'R' AND pit.playerid 		= playerid)
	INTERSECT
	SELECT playerid
	FROM halloffame)
SELECT COUNT(hofleft.playerid) AS lefty_count,
	COUNT(hofright.playerid) AS righty_count,
	(SELECT COUNT(playerid) FROM halloffame) AS hof_count,
	CAST(ROUND((CAST(COUNT(hofleft.playerid) AS DECIMAL(10, 2)) / CAST((2477) AS 			DECIMAL(10, 2))) * 	100, 2) AS VARCHAR(10)) || '%' AS lefty_percentage,
	CAST(ROUND((CAST(COUNT(hofright.playerid) AS DECIMAL(10, 2)) / CAST((6605) AS DECIMAL(10, 2))) * 	100, 2) AS VARCHAR(10)) || 		'%' AS righty_percentage
FROM hofleft
FULL JOIN hofright
ON hofleft.playerid = hofright.playerid;

-- 1. In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

-- a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.
SELECT t.yearID,
    t.lgID,
    t.teamID,
    t.w AS wins
FROM teams AS t
WHERE t.yearid = 2016
	AND t.w = (SELECT MAX(w) FROM teams WHERE t.yearid = yearid AND t.lgid = lgid);

-- c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.
SELECT DISTINCT ON (lgid)
    yearid,
	lgid,
    teamid,
    w AS wins
FROM teams
WHERE yearid = 2016
ORDER BY lgid, w DESC;

-- d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016. 
SELECT
	bestteam.yearid,
    t.lgid,
    bestteam.teamid,
    bestteam.w AS most_wins
FROM
    (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) AS t -- Selects each unique league ID for 2016
CROSS JOIN LATERAL (
    SELECT yearid,
		teamid,
        w
    FROM teams
    WHERE yearid = 2016 AND lgid = t.lgid -- Correlates with the outer query's lgID
    ORDER BY w DESC
    LIMIT 1) AS bestteam;

-- e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.
SELECT
	bestteam.yearid,
    t.lgid,
    bestteam.teamid,
    bestteam.w AS most_wins
FROM
    (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) AS t -- Selects each unique league ID for 2016
CROSS JOIN LATERAL (
    SELECT yearid,
		teamid,
        w
    FROM teams
    WHERE yearid = 2016 AND lgid = t.lgid -- Correlates with the outer query's lgID
    ORDER BY w DESC
    LIMIT 3) AS bestteam;

-- 2. Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. For example,
SELECT 
	teamid,
	w,
	l,
	w + l AS total_games,
	w*100.0 / total_games AS winning_pct
FROM teams
WHERE yearid = 2016
ORDER BY winning_pct DESC;

-- results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

SELECT
	teamid,
	w,
	l,
	total_games,
	w*100.0 / total_games AS winning_pct
FROM teams t,
LATERAL (
	SELECT w + l AS total_games)
WHERE yearid = 2016
ORDER BY winning_pct DESC;

-- a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.
SELECT namefirst,
	namelast,
	TO_DATE(CONCAT(birthyear::TEXT, '-', COALESCE(birthmonth::TEXT, '1'), '-',				COALESCE(birthday::TEXT, '1')), 'YYYY-MM-DD') AS birthday
FROM people;

-- b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).
SELECT 
    p.playerID,
    p.nameFirst,
    p.nameLast,
    ages.debut_age,
    ages.retirement_age
FROM 
    People AS p,
LATERAL (
        SELECT 
            AGE(p.debut::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS debut_age,
            AGE(p.finalGame::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS retirement_age) AS ages
WHERE 
    p.debut IS NOT NULL 
    AND p.finalGame IS NOT NULL 
    AND p.birthYear IS NOT NULL;

-- c. Who is the youngest player to ever play in the major leagues?
SELECT 
    p.playerID,
    p.nameFirst,
    p.nameLast,
    ages.debut_age,
    ages.retirement_age
FROM 
    People AS p,
LATERAL (
        SELECT 
            AGE(p.debut::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS debut_age,
            AGE(p.finalGame::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS retirement_age) AS ages
WHERE 
    p.debut IS NOT NULL 
    AND p.finalGame IS NOT NULL 
    AND p.birthYear IS NOT NULL
ORDER BY debut_age
LIMIT 1;

-- d. Who is the oldest player to play in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.
SELECT 
    p.playerID,
    p.nameFirst,
    p.nameLast,
    ages.debut_age,
    ages.retirement_age
FROM 
    People AS p,
LATERAL (
        SELECT 
            AGE(p.debut::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS debut_age,
            AGE(p.finalGame::DATE, 
                TO_DATE(
                    p.birthYear::TEXT || '-' || COALESCE(p.birthMonth::TEXT, '1') || '-' 					|| COALESCE(p.birthDay::TEXT, '1'),
                    'YYYY-MM-DD')) AS retirement_age) AS ages
WHERE 
    p.debut IS NOT NULL 
    AND p.finalGame IS NOT NULL 
    AND p.birthYear IS NOT NULL
ORDER BY retirement_age DESC
LIMIT 1;


SELECT *
FROM allstarfull AS a
WHERE startingpos IS NOT NULL
AND playerid = 'mayswi01';
