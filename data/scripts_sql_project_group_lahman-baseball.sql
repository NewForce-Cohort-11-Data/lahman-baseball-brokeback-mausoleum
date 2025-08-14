-- Lahman Baseball Database Exercise

--     this data has been made available online by Sean Lahman
--     A data dictionary is included with the files for this project.

-- Use SQL queries to find answers to the Initial Questions. If time permits, choose one (or more) of the Open-Ended Questions. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the Open-Ended Questions.

-- Initial Questions

-- My comments: 
-- Cybersecurity: I have had cybersecurity issues since before I started the Generation WV NewForce Cohort 11. It seems that the cybersecurity issues have not been resolved. 
-- Lahman Baseball Exercise: I mostly answered questions 1-7 (there may have been a few questions that were mostly solved but needed a little more work). Then pgAdmin started having issues. Code that ran well on the first try, would give me error messages on a second try, even though I had made no changes to the code. There were some questions where I needed to learn more to complete the question. However, when I used Datacamp, the videos would play fine, but when I did the exercises, the code would show errors. When I used the AI Assistant to help, it would tell me to make a change to correct the code, so I did. Then, when I ran the code, I'd get another error message saying that I needed to change my code back to what it was the first time I ran it. So, I've had challenges completing Datacamp and pgAdmin4/SQL due to these issues. Some of the answers in this exercise are my code, and some are from team members. 
-- My team members on this project include the following: Marc Pontius, Nidhi Mukkamala, and Megan Howard. 

-- 1. What range of years for baseball games played does the provided database cover?
-- Answer: 1871-05-04 to 2016-10-02

-- My solution:
SELECT MIN(span_first) AS first_year, MAX(span_last) AS last_year
FROM homegames;


-- 2a.  Find the name and height of the shortest player in the database. 
-- Answer: Eddie Gaedel at 43 inches

-- My solution.
SELECT namefirst, namelast, MIN(height) AS height_in, playerid
FROM people
GROUP BY namefirst, namelast, height, playerid
ORDER BY height ASC
LIMIT 1; 


-- 2b. How many games did he play in? 1

-- My comments: I either solved this, or came close to it. I believe I looked at a team member solution for the subquery in the WHERE, because my solution from above (using height ASC) didn't work consistently. 

SELECT namefirst, namelast, height, g_all, playerid
FROM people 
INNER JOIN appearances 
USING (playerid)
WHERE height = (SELECT MIN(height) 
				FROM people)
GROUP BY namefirst, namelast, height, g_all, playerid
ORDER BY height ASC;


			
-- 2c. What is the name of the team for which he played? 
-- Answer: St. Louis Browns

-- My comments are the same as in 2b.
SELECT DISTINCT(namelast), height, g_all, name
FROM people
INNER JOIN appearances 
USING(playerid)
INNER JOIN teams
USING(teamid)
WHERE height = (SELECT MIN(height) 
				FROM people);


--  3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors? David Price, $81,851,296.00

-- My comments: I provided an answer from a team member. 

-- From a team member (I believe it was Megan Howard).
SELECT namefirst, namelast, SUM(salary)::INT::MONEY AS total_salary
FROM people
INNER JOIN salaries
USING (playerid)
WHERE playerid IN
  (SELECT playerid
    FROM collegeplaying
    INNER JOIN schools 
    USING (schoolid)
    WHERE schoolname ILIKE '%Vanderbilt%')
GROUP BY namefirst, namelast
ORDER BY total_salary DESC NULLS LAST;

-- WRONG ANSWER (from a team member; I think this was from Nidhi): 15 rows, David Price, 245553888; use a LEFT JOIN; SUM the salary
select playerid, namefirst, namelast,sum(salary)::int::money as total_salary
from schools
inner join collegeplaying using(schoolid)
inner join people using(playerid)
left join salaries using(playerid)
where schoolname='Vanderbilt University'
group by playerid, namefirst, namelast
order by total_salary desc nulls last;

--  4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

-- My comments: same as 2b

SELECT SUM(po) AS putouts,
		CASE 
			WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
			ELSE 'missing'
		END AS position
FROM fielding
WHERE yearid = 2016
GROUP BY position;


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- My comments: similar to 2b. This code is from a team member. 

SELECT *
FROM batting;

SELECT *
FROM teams;

SELECT 
	FLOOR(yearid / 10) * 10 AS decade,
	ROUND(AVG(so + soa), 2) AS avg_strikeouts, 
	ROUND(AVG(hr), 2) AS avg_homeruns
FROM teams
WHERE 
	FLOOR(yearid / 10) * 10 >=1920
GROUP BY decade
ORDER BY decade ASC;


-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT *
FROM people;

SELECT *
FROM batting;

-- My comments: this one is mine. I had to look at Marc's code to figure some of it out. 
SELECT namefirst, namelast, sb, (sb + cs) AS sb_attempts, 
	sb::NUMERIC / (sb::NUMERIC + cs::NUMERIC) * 100 AS success_rate
FROM people
INNER JOIN batting
USING (playerid)
WHERE yearid = 2016
AND (sb + cs) > 20
GROUP BY namefirst, namelast, sb, sb_attempts
ORDER BY success_rate ASC;


-- This is from Marc
SELECT playerid, 
	CONCAT(namefirst, ' ', namelast) AS player_name,
	yearid,
	sb,
	sb + cs AS sb_attempts,
	sb::NUMERIC / (sb::NUMERIC + cs::NUMERIC) * 100 AS success_rate
FROM people
INNER JOIN batting
USING (playerid)
WHERE yearid = 2016
	AND (sb + cs) >=20
ORDER BY success_rate DESC;

-- 7a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 116

SELECT *
FROM teams;

SELECT name, w AS wins_wsloss
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND WSWin = 'N'
GROUP BY name, wins_wsloss
ORDER BY wins_wsloss DESC; 

-- 7b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 63; problem year 1981, due to a strike;

SELECT name, w AS wins_wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND WSWin = 'Y'
GROUP BY name, wins_wswin
ORDER BY wins_wswin ASC;

-- Determine the problem year:  
SELECT name, w AS wins_wswin, yearid
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND WSWin = 'Y'
GROUP BY name, wins_wswin, yearid
ORDER BY wins_wswin ASC
LIMIT 1;

-- 7c. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time? 

-- NEED: get better at SQL, then come back and do this one

SELECT name, MAX(w), w AS wins_wswin
FROM teams
WHERE yearid <> 1981
AND yearid BETWEEN 1970 AND 2016
AND WSWin = 'Y'
GROUP BY name, wins_wswin
ORDER BY wins_wswin ASC;


-- From Marc
WITH wsw_table AS(
	SELECT yearid, 
		name, 
		w, 
		wswin, 
		MAX(w) OVER(PARTITION BY yearid) AS max_wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016)
SELECT 
	COUNT(name)
	FROM wsw_table
	WHERE wswin = 'Y'
	AND w = max_wins

-- From Megan
SELECT
  COUNT(DISTINCT sp.yearid) AS total_years,
  COUNT(DISTINCT CASE WHEN t.teamid = sp.teamidwinner THEN sp.yearid END) AS wins_and_ws,
  ROUND(
    COUNT(DISTINCT CASE WHEN t.teamid = sp.teamidwinner THEN sp.yearid END) * 100
    / COUNT(DISTINCT sp.yearid),
    2
  ) AS percentage
FROM seriespost AS sp
JOIN teams AS t USING (yearid)
WHERE sp.round = 'WS'
  AND sp.yearID BETWEEN 1970 AND 2016
  AND t.w = (
    SELECT MAX(t2.w)
    FROM teams AS t2
    WHERE t2.yearid = t.yearid
  );

-- Final thing from Megan
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
	COUNT (DISTINCT yearid) -1,
	ROUND((COUNT(CASE WHEN wswin = 'Y' AND w = max_wins THEN name END)::NUMERIC /
	COUNT (DISTINCT yearid::NUMERIC)), 2) AS percent
	FROM wsw_table;
	

-- first thing from Megan
SELECT yearid,
	   name, 
       MAX(CASE WHEN wswin = 'Y' THEN l END) AS most_loss_ws_win
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
      AND wswin = 'Y'
GROUP BY yearid, name
ORDER BY most_loss_ws_win DESC
LIMIT 1;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 

SELECT *
FROM homegames;

SELECT *
FROM parks;

SELECT *
FROM teams;

-- xNEEDSx
SELECT t.name, park_name, ROUND(AVG(h.attendance/games), 2) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p
USING (park)
INNER JOIN teams AS t
ON h.team = t.teamid
WHERE yearid = 2016
AND h.games > 10
AND t.name <> 'St. Louis Perfectos'
GROUP BY t.name, park_name
ORDER BY avg_attendance DESC
LIMIT 5;


-- From Marc Pontius
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

-- 8b. Repeat for the lowest 5 average attendance.

SELECT t.name, park_name, ROUND(AVG(h.attendance/games), 2) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p
USING (park)
INNER JOIN teams AS t
ON h.team = t.teamid
WHERE yearid = 2016
AND h.games > 10
AND t.name <> 'Tampa Bay Devil Rays'
AND t.name <> 'Cleveland Bronchos'
AND t.name <> 'Cleveland Naps'
GROUP BY t.name, park_name
ORDER BY avg_attendance ASC
LIMIT 5;


-- From Marc Pontius
--Part 2 

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

SELECT *
FROM managers;

SELECT *
FROM awardsmanagers;

SELECT *
FROM people;

SELECT *
FROM teams;

SELECT *
FROM 



--Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- Comment: this one is above my abilities. I'll need to use one of the solutions from my team members. See their solutions below.

-- Mine. 
SELECT p.namelast AS last_name, p.namefirst AS first_name
FROM people AS p
INNER JOIN awardsmanagers AS am
USING (playerid)
WHERE awardid = 'TSN Manager of the Year';
AND lgid = 'NL'
AND lgid = 'AL';
INNER JOIN teams AS t
USING playerid;


--From Marc Pontius
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
SELECT * FROM awards
WHERE both_awards IS NOT NULL;

-- From Megan:
WITH am AS (
  SELECT playerid, lgid, yearid
  FROM awardsmanagers
  WHERE awardid = 'TSN Manager of the Year'
),
am_clean AS (
  SELECT DISTINCT playerid, lgid, yearid
  FROM am
)
SELECT
  CONCAT(p.namefirst, ' ', p.namelast) AS manager_name,
  STRING_AGG(lgid || ' ' || yearid::text, ', ' ORDER BY yearid) AS award_seasons
FROM am_clean
JOIN people AS p USING (playerid)
GROUP BY p.playerid, manager_name
HAVING COUNT(DISTINCT lgid) = 2
ORDER BY manager_name;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT *
FROM people;

SELECT *
FROM batting;

SELECT DISTINCT (p.namelast), p.namefirst, b.yearid, hr
FROM people AS p
INNER JOIN batting AS b
USING (playerid)
WHERE b.yearid = 2016
AND b.hr >= 1;
AND 
SELECT MAX(hr) AS max_homerun 
	FROM batting
	WHERE playerid = p.playerid) = b.hr
AND (SELECT MAX(yearid) - MIN(yearid) 
	FROM batting 
	WHERE playerid = p.playerid) >= 10;



ORDER BY b.hr DESC;


SELECT CAST('2015-08-23' AS INT) AS finalgame
FROM people;



SELECT TO_NUMBER(TO_CHAR(your_date_column, 'YYYYMMDD'));

SELECT CAST('2023-10-26' AS DATE);

SELECT CAST('1234' AS INT) AS Result;

-- From Marc
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

-- Open-ended questions

--     Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

--     In this question, you will explore the connection between number of wins and attendance.


--         Does there appear to be any correlation between attendance at home games and number of wins?


--         Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

--     It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
