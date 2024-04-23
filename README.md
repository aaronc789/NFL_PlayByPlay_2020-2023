# <p align="center">NFL_PlayByPlay_2020-2023</p>
# <p align="center">![Pic](Images/justin_herbert.jpg)</p>

## Using NFL play-by-play data of the past 4 seasons, I analyzed offensive strategies and tried to figure out which offenses or players were most successful, along with figuring out the different factors that could potentially determine a defenses' rankings and increase a teams' win probability.

### The following is a description of the data columns I will be using:
**Play_id**: primary key; unique for every instance in the table

**Game_id**: unique identifier for every game; displays in order the away team, home team, year

**Week**: what week the game takes place in

**Desc**: a description of the play

**Posteam/Defteam**: the team on offense/defense

**Game_date**: as a date variable, provides the day, month and year the game took place in

**Game_seconds_remaining**: how many seconds are left in the game

**Passer_player_me**: name of the quarterback involved in the play (if applicable)

**receiver_player_me**: name of the wide receiver involved in the play (if applicable)

**rusher_player_me**: name of the running back involved in the play (if applicable)

**wpa**: win-probability added; shows how much a team’s chance of winning the game changed as a results of the play

**EPA**: expected points added; advanced stat that determines how well the play was relative to the “expected points” of that play. This stat is very important for this project. Better definition here

**Posteam_type**: indicates ‘home’ if the team on offense is the home team, or ‘away’ if the team on offense is the visiting team

**Score_differential**: at the time of the play, how many points the HOME TEAM is ahead by (this value can be negative)

**Yards_gained**: how many yards were gained as a result of this play

**Home_score/away_score**: how many points the home team/away team has at the end of the game

**Result**: (Home_score) – (Away_score)

**Play_type**: play that was ran; main types are ‘pass’, ’run’, ’field_goal’, ’extra_point’, ’punt’

**Down**: is either 1, 2, 3, 4; represents what down the play took place during

### First, I needed to combine the individual datasets of each NFL season and merge them into one table:
```sql
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
```
