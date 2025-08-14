-- What range of years for baseball games played does the provided database cover?

SELECT
  MIN(year) AS start_year,
  MAX(year) AS end_year
FROM
  homegames;

-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT DISTINCT
  CONCAT(namefirst, ' ', namelast) AS player_name,
  height,
  g_all AS games_played,
  name
FROM
  people
  INNER JOIN appearances USING (playerid)
  INNER JOIN teams USING (teamid)
WHERE
  height = (
    SELECT
      MIN(height)
    FROM
      people
  );

-- Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT
  CONCAT(namefirst, ' ', namelast) AS player_name,
  SUM(salary)::INT::MONEY AS total_salary
FROM 
  people
LEFT JOIN 
  salaries
USING 
  (playerid)
WHERE playerid IN
  (SELECT playerid
    FROM collegeplaying
    INNER JOIN schools 
    USING (schoolid)
    WHERE schoolname ILIKE '%Vanderbilt%')
GROUP BY 
  namefirst, 
  namelast
ORDER BY 
  total_salary DESC NULLS LAST;

-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
  SUM(po) AS putouts,
  CASE
    WHEN pos = 'OF' THEN 'Outfield'
    WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
    WHEN pos IN ('P', 'C') THEN 'Battery'
  END AS position
FROM
  fielding
WHERE
  yearid = '2016'
GROUP BY
  position;


-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT
  FLOOR(yearid / 10) * 10 AS decade,
  ROUND(SUM(so) / SUM(g)::NUMERIC, 2) AS avg_so_per_game
FROM
  teams
WHERE
  FLOOR(yearid / 10) * 10 >= 1920
GROUP BY
  decade
ORDER BY
  decade;

SELECT
  FLOOR(yearid / 10) * 10 AS decade,
  ROUND(SUM(hr) / SUM(g)::NUMERIC, 2) AS avg_hr_per_game
FROM
  teams
WHERE
  FLOOR(yearid / 10) * 10 >= 1920
GROUP BY
  decade
ORDER BY
  decade;

-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT 
  CONCAT(namefirst, ' ', namelast) AS player_name,
  ROUND(sb:: NUMERIC /(sb+cs)*100, 2) AS stealing_success
FROM 
  batting
JOIN
  people
USING
  (playerid)
WHERE 
  yearid = 2016 
   AND sb >= 20
ORDER BY 
  stealing_success DESC NULLS LAST;

-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


SELECT
  t.yearid,
  t.name,
  t.w
FROM
  teams AS t
  JOIN seriespost AS s ON s.yearid = t.yearid
  AND s.round = 'WS'
  AND s.teamidwinner <> t.teamid
WHERE
  t.yearid BETWEEN 1970 AND 2016
  AND t.yearid <> 1981
ORDER BY
  t.w DESC
LIMIT
  1;

SELECT
  t.yearid,
  t.name,
  t.w
FROM
  teams AS t
  JOIN seriespost AS s ON s.yearid = t.yearid
  AND s.round = 'WS'
  AND s.teamidwinner = t.teamid
WHERE
  t.yearid BETWEEN 1970 AND 2016
  AND t.yearid <> 1981
ORDER BY
  t.w
LIMIT
  1;

SELECT
  COUNT(
    DISTINCT CASE
      WHEN t.teamid = sp.teamidwinner THEN sp.yearid
    END
  ) AS most_wins_and_ws,
  ROUND(
    COUNT(
      DISTINCT CASE
        WHEN t.teamid = sp.teamidwinner THEN sp.yearid
      END
    ) * 100 / COUNT(DISTINCT sp.yearid),
    2
  ) AS percentage
FROM
  seriespost AS sp
  JOIN teams AS t USING (yearid)
WHERE
  sp.round = 'WS'
  AND sp.yearid BETWEEN 1970 AND 2016 AND sp.yearid <> 1981
  AND t.w = (
    SELECT
      MAX(t2.w)
    FROM
      teams AS t2
    WHERE
      t2.yearid = t.yearid
  );





-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT DISTINCT year,
  t.name AS team,
  t.park,
  h.games,
  h.attendance,
  (h.attendance / h.games) AS avg_attendance
FROM
  homegames AS h
  JOIN teams AS t ON h.team = t.teamid AND yearid = year
WHERE
  year = 2016
  AND games >= 10
ORDER BY
  avg_attendance DESC
LIMIT
  5;

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


-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award?

SELECT DISTINCT
    CONCAT(p.namefirst, ' ', p.namelast) AS manager_name,
    STRING_AGG(
    a.lgid || ' ' || a.yearid::text || ' (' || t.name || ')',
    ', ' ORDER BY a.yearid
  ) AS award_seasons
FROM
    awardsmanagers AS a
JOIN people AS p ON a.playerid = p.playerid
JOIN managers AS m ON a.playerid = m.playerid AND a.yearid = m.yearid AND a.lgid = m.lgid
JOIN teams AS t ON m.teamid = t.teamid AND m.yearid = t.yearid AND m.lgid = t.lgid
WHERE
    a.awardid = 'TSN Manager of the Year'
    AND a.lgid IN ('AL', 'NL') 
    AND a.playerid IN (
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
          AND lgid IN ('AL', 'NL')
        GROUP BY playerid
		HAVING COUNT(DISTINCT lgid) = 2
    )
GROUP BY 
	p.namefirst, p.namelast
ORDER BY
    manager_name, award_seasons;



-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT
  CONCAT(p.nameFirst, ' ', p.nameLast) AS player_name,
  b.hr AS hr_2016
FROM
  batting AS b
JOIN people AS p ON b.playerid = p.playerid
WHERE
  b.yearid = 2016
  AND b.hr >= 1
  AND b.hr = (
    SELECT MAX(hr)
    FROM batting
    WHERE playerid = b.playerid
  )
  AND (
    SELECT COUNT(DISTINCT yearid)
    FROM batting
    WHERE playerid = b.playerid
  ) >= 10
ORDER BY
  b.hr DESC;