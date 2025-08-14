--1.) a. 

select distinct t.lgid,t.teamid,t.name,t.w
from teams as t
where t.w=(select max(w)
			from teams
			where lgid=t.lgid
			and yearid=2016)
and yearid=2016;

--b.
select distinct t.lgid,t.teamid,t.name,t.w
from teams as t
where t.w=(select max(w)
			from teams
			where lgid=t.lgid
			and yearid=2016)
and yearid=2016;

--c.
select distinct on(lgid) lgid,teamid,name,w
from teams
where yearid=2016
order by lgid,w desc;

--d

