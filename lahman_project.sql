--1.)
select min(yearid) as start_year, max(yearid) as end_year
from teams;

select *
from teams;
--2.)
select namegiven,height
from people
order by height
limit 1;

select playerid, namegiven,height
from people
order by height
limit 1;

select sum(g_all)
from appearances
where playerid='gaedeed01';

select teamid
from appearances
where playerid='gaedeed01';

select name
from appearances
inner join teams using(teamid)
where teamid='SLA'
limit 1;

SELECT
  p.namegiven,
  p.height,
  (
    SELECT SUM(g_all)
    FROM appearances a
    WHERE a.playerid = p.playerid
  ) AS total_games,
  (
    SELECT STRING_AGG(t.name, ', ')
    FROM appearances a
    JOIN teams t ON a.teamid = t.teamid
    WHERE a.playerid = p.playerid
  ) AS teams
FROM people p
ORDER BY p.height
LIMIT 1;


--3.)

with salary_total as (select playerid, sum(salary) as total_salary
from salaries
group by playerid)

select distinct playerid, namefirst, namelast, total_salary::int::money
from schools
inner join collegeplaying using(schoolid)
inner join people using(playerid)
left join salary_total using(playerid)
where schoolname ilike '%Vanderbilt%'
order by total_salary desc nulls last;

select playerid, namefirst, namelast,sum(salary)::int::money as total_salary
from schools
inner join collegeplaying using(schoolid)
inner join people using(playerid)
left join salaries using(playerid)
where schoolname ilike '%Vanderbilt%'
group by playerid, namefirst, namelast
order by total_salary desc nulls last;
  
--4.)
select playerid, pos,
case
when pos='OF' then 'Outfield'
when pos in ('SS','1B','2B','3B') then 'Infield'
when pos in ('P','C') then 'Battery'
else ' '
end as group_position
from fielding;

select 
case
when pos='OF' then 'Outfield'
when pos in ('SS','1B','2B','3B') then 'Infield'
when pos in ('P','C') then 'Battery'
else ' '
end as group_position, sum(po) as total_po
from fielding
where yearid=2016
group by group_position;

--5.)
select sum(so)/sum(g) fr, floor((yearid/10)*10) as decade
from pitching
where yearid>=1920
group by decade;

SELECT 
    (yearid / 10) * 10 AS decade,
    ROUND(SUM(so)/ SUM(g), 2) AS avg_strikeouts_per_game,
    ROUND(SUM(hr)/ SUM(g), 2) AS avg_home_runs_per_game
FROM 
    teams
WHERE 
    yearid >= 1920
GROUP BY 
    decade
ORDER BY 
    decade;

select sum(so)/sum(hr), floor((yearid/10)*10) as decade
from pitching
where yearid>=1920
group by decade;

--6.)
select playerid,sb,cs,(sb*100/(sb+cs)) as success_percentage, namefirst,namelast
from batting
left join people using(playerid)
where (sb+cs)>0
and yearid=2016
and (sb+cs)>=20
order by success_percentage desc
limit 1;

--7.)
select yearid,teamid,w,name
from teams
where yearid between 1970 and 2016
and wswin !='Y'
order by w desc;

select yearid,teamid,w,name
from teams
where yearid between 1970 and 2016
and wswin !='Y'
order by w;

select yearid,teamid,w
from teams
where yearid between 1970 and 2016
and wswin !='Y'
and yearid<>1981
order by w desc;

--all
select yearid,teamid,w,name
from teams
where yearid between 1970 and 2016
order by w desc;

--12
select t.w,t.yearid,teamid,wswin
from teams t
where t.yearid between 1970 and 2016
and wswin='Y'
and w=(select max(b.w)
from teams b
where b.yearid=t.yearid)
order by t.yearid;

select count(*) as c1
from teams t
where t.yearid between 1970 and 2016
and wswin='Y'
and w=(select max(b.w)
from teams b
where b.yearid=t.yearid);

--46
select count(*) as c2
from teams
where yearid between 1970 and 2016
and wswin='Y';

with a as (select count(*) as c1
from teams t
where t.yearid between 1970 and 2016
and wswin='Y'
and w=(select max(b.w)
from teams b
where b.yearid=t.yearid)),

b as (select count(*) as c2
from teams
where yearid between 1970 and 2016
and wswin='Y')

select *, round(((a.c1::float*100) / b.c2::float)::numeric,2) AS percentage
from a
cross join b ;

--8.)
select team, (h.attendance/games) as avg_attendance, park_name, teams.name
from homegames as h
inner join parks using(park)
inner join teams on teams.teamid=h.team and teams.yearid=h.year
where year=2016
and games>=10
order by avg_attendance desc
limit 5;

select team, (h.attendance/games) as avg_attendance, park_name, teams.name
from homegames as h
inner join parks using(park)
inner join teams on teams.teamid=h.team and teams.yearid=h.year
where year=2016
and games>=10
order by avg_attendance
limit 5;

--9.)
select p.playerid,namefirst,namelast,name as team_name,m.yearid,m.lgid
from managershalf as m
inner join people as p using(playerid)
inner join teams as t using(teamid,yearid)
where m.playerid in
(select playerid
from awardsmanagers
where awardid='TSN Manager of the Year' and lgid='AL'
intersect
select playerid
from awardsmanagers
where awardid='TSN Manager of the Year' and lgid='NL');

select a.playerid, namefirst, namelast, name,t.teamid
from awardsmanagers as a
inner join people using(playerid)
inner join managers as m on a.playerid = m.playerid
    and a.yearid = m.yearid
    and a.lgid = m.lgid
inner join teams as t using(teamid)
where awardid='TSN Manager of the Year' and a.lgid='AL'
intersect
select a.playerid, namefirst, namelast,name,t.teamid
from awardsmanagers as a
inner join people using(playerid)
inner join managers as m on a.playerid = m.playerid
    and a.yearid = m.yearid
    and a.lgid = m.lgid
inner join teams as t using(teamid)
where awardid='TSN Manager of the Year' and a.lgid='NL';


SELECT 
    p.nameFirst,
    p.nameLast,
    am.lgID,
    am.yearID,
    m.teamID,
	name
FROM 
    awardsmanagers am
JOIN 
    people p USING (playerID)
JOIN 
    managers m 
    ON am.playerID = m.playerID 
    AND am.yearID = m.yearID 
    AND am.lgID = m.lgID
inner join teams using(teamid)
WHERE 
    am.awardID = 'TSN Manager of the Year'
    AND am.playerID IN (
        SELECT playerID
        FROM awardsmanagers
        WHERE awardID = 'TSN Manager of the Year' AND lgID = 'AL'
        INTERSECT
        SELECT playerID
        FROM awardsmanagers
        WHERE awardID = 'TSN Manager of the Year' AND lgID = 'NL'
    )
ORDER BY 
    p.nameLast, am.yearID;

--10.)
select p.namefirst,p.namelast,b.hr
from batting as b
inner join people as p using (playerid)
where b.yearid=2016
and b.hr>=1
and (select count(distinct yearid) as years_played
from batting
where playerid = b.playerid)>=10
and b.hr=(select max(hr)
from batting
where playerid = b.playerid);


select a.hr,a.playerid,namefirst,namelast
from batting as a
inner join people using(playerid)
where a.yearid=2016
and a.hr>=1
and playerid in (select b.playerid
from batting as b
group by b.playerid
having count(distinct b.yearid)>=10)
and a.hr=(select max(c.hr) as max_hr
from batting as c
where c.playerid=a.playerid) ;

select playerid
from batting
group by playerid
having count(distinct yearid)>=10;

select playerid, hr as hr_2016
from batting
where yearid=2016;

select playerid
from batting
where hr>=1 and yearid=2016;

select *
from batting;

