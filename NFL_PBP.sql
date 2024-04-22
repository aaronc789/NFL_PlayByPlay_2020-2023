-- Create a dataset nfl_pbp to merge the tables and corresponding columns from the past 4 seasons (2020-2023)

drop table if exists nfl_pbp
    select * into nfl_pbp
    from (
        select play_id, [desc], game_id, game_date, week, posteam, posteam_type, defteam, game_seconds_remaining, yards_gained,
               play_type, away_score, home_score, result, 
               passer_player_name, receiver_player_name, rusher_player_name, score_differential, wpa, epa, down
          from play_by_play_2020

    UNION

        select play_id, [desc], game_id, game_date, week, posteam, posteam_type, defteam, game_seconds_remaining, yards_gained,
               play_type, away_score, home_score, result, 
               passer_player_name, receiver_player_name, rusher_player_name, score_differential, wpa, epa, down 
        from play_by_play_2021

    UNION

        select play_id, [desc], game_id, game_date, week, posteam, posteam_type, defteam, game_seconds_remaining, yards_gained,
               play_type, away_score, home_score, result, 
               passer_player_name, receiver_player_name, rusher_player_name, score_differential, wpa, epa, down
        from play_by_play_2022

    UNION

        select play_id, [desc], game_id, game_date, week, posteam, posteam_type, defteam, game_seconds_remaining, yards_gained,
               play_type, away_score, home_score, result, 
               passer_player_name, receiver_player_name, rusher_player_name, score_differential, wpa, epa, down
        from play_by_play_2023) as x



-- Update result column since certain data did not transfer properly
update nfl_pbp
set result = home_score - away_score


-- Add columns for season and winner
alter table nfl_pbp
add season int NULL

alter table nfl_pbp
add winner NVARCHAR(5) NULL


-- NFL season starts in September and ends in February
update nfl_pbp
set season = 
    (case when month(game_date) <= 2 then year(game_date) - 1 else year(game_date) end)


-- Whether the team on offense ends up winning the game
update nfl_pbp
set winner = 
    (case when posteam_type = 'away' 
        then 
            (case when result < 0 then 'Yes'			-- away team on offense won
                  when result > 0 then 'No' 
				  else 'Tied' 
            end) 
        else 
            (case when result > 0 then 'Yes'			-- home team on offense won
                  when result < 0 then 'No' 
				  else 'Tied' 
            end) 
    end)



-- How many pass plays and run plays were recorded?
select count(*) from nfl_pbp
where play_type in ('pass','run')


-- WPA stands for Win Probability Added
-- Find top 20 plays by most WPA in regular season
select top 20 game_id, posteam, season, [desc], wpa
from nfl_pbp
where play_type not in ('field_goal', 'punt', 'no_play', 'extra_point') and week <= 18
order by wpa desc

-- Find top 20 plays by most WPA in playoffs
select top 20 game_id, posteam, season, [desc], wpa
from nfl_pbp
where play_type not in ('field_goal', 'punt', 'no_play', 'extra_point') and week > 18
order by wpa desc


-- EPA stands for Expected Points Added
-- Determine top 20 best QBs, RBs and WRs are by EPA per play within a regular season
select top 20 passer_player_name, season, avg(epa) as 'EPA per play' from nfl_pbp
where passer_player_name is not null and play_type = 'pass' and week <= 18 
group by passer_player_name, season
-- Quarterbacks with more than 200 plays
having count(*) > 200
order by sum(epa) / count(*) desc

select top 20 receiver_player_name, season, avg(epa) as 'EPA per play' from nfl_pbp
where receiver_player_name is not null and week <= 18
group by receiver_player_name, season
-- Wide Receivers with more than 75 plays
having count(*) > 75
order by sum(epa) / count(*) desc

select top 20 rusher_player_name, season, avg(epa) as 'EPA per play' from nfl_pbp
where rusher_player_name is not null and week <= 18
group by rusher_player_name, season
-- Running Backs with more than 200 plays
having count(*) > 200
order by avg(epa) desc



-- DEFENSE: Multiple factors help determine the rankings of teams and how good their defense is
-- 1. Which defenses forced the most turnovers?
-- 2. Which defenses forced the most negative plays or plays with no yards gained?
-- 3. Which defenses allowed the fewest points per game?
-- 4. Which defenses allowed the fewest yards per play?
-- 5. Determine the best defenses based on all four factors
select defteam, season, 
rank() over (order by sum(case when [desc] LIKE '%INTERCEPTED%' or [desc] LIKE '%FUMBLE%' then 1.0 else 0.0 end) / count(*) desc) as 'Turnover Rank',
rank() over (order by sum(case when [desc] like '%incomplete%' or yards_gained <= 0 and defteam is not null and play_type in ('pass','run')  then 1.0 else 0.0 end) / count(*) desc) as 'Dead Play Rank',
rank() over (order by sum(case when posteam_type = 'home' then home_score else away_score end)*1.0 / count(*)) as 'Scoring Rank',
rank() over (order by sum(yards_gained) * 1.0 / count(*)) as 'Yards Allowed Rank',
rank() over(order by (sum(case when [desc] LIKE '%INTERCEPTED%' or [desc] LIKE '%FUMBLE%' then 1.0 else 0.0 end) / count(*) ) +
                     (sum(case when [desc] like '%incomplete%' or yards_gained <= 0 and defteam is not null and play_type in ('pass','run')  then 1.0 else 0.0 end) / count(*) ) +
                      sum(case when posteam_type = 'home' then home_score else away_score end)*1.0 / count(*) +
                      sum(yards_gained) * 1.0 / count(*))  as '(Averaged) Total Defense Rank'
from nfl_pbp
where play_type in ('run','pass') and week <= 18
group by defteam, season
order by [(Averaged) Total Defense Rank] 