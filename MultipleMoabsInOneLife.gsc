#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\killstreaks\_killstreaks;

init()
{
    level thread onPlayerConnect();
}   
 
onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
		player thread onPlayerSpawned();

    }
}
 
onPlayerSpawned()
{	
    self endon("disconnect");
    level endon("game_ended");
    for(;;)
	
    {	
		self waittill ("spawned_player");
		self thread moabRollover();
	}    
}

//Moab Rollover lets the player continue to get moabs until they die
moabRollover()
{
	self endon ("disconnect");
	level endon ("game_ended");
	self endon( "death" );

	canGiveMoab = 1;
	lapCount = 1;
	killsForMoabWithHardline = 24;
	killsForMoabWithoutHardline = 25;
	resetStreakNum = 0;
	
	while (true)
	{
		//if the player has hardline
		if ( isdefined( self.perks["specialty_hardline"] ) )
        {
			//if the player has a streak greater than totalRequiredKills * the amount of moabs we have ( ie. 24 , 48, 72 )
			if (self.pers["cur_kill_streak"] >= killsForMoabWithHardline * lapCount)
			{
				//Check if they are eligible for another moab
				if (canGiveMoab && lapCount > 1) 
				{
					//give them a moab
					giveMoab(killsForMoabWithHardline * lapCount);
					//No longer can give player a Moab
					canGiveMoab = 0;
				}
				//Move to the next lap
				lapCount++;
				
			}
		}
		else	//else the player does not have hardline
		{
			//if the player has a streak greater than totalRequiredKills * the amount of moabs we have ( ie. 25 , 50, 75 )
			if (self.pers["cur_kill_streak"] >= killsForMoabWithoutHardline * lapCount)
			{
				//Check if they are eligible for another moab
				if (canGiveMoab && lapCount > 1) 
				{
					//give them a moab
					giveMoab(killsForMoabWithoutHardline * lapCount);
					//No longer can give player a Moab
					canGiveMoab = 0;
				}
				//Move to the next lap
				lapCount++;
				
			}
		}

		//if the player has hardline
		if ( isdefined( self.perks["specialty_hardline"] ) )
        {
			resetStreakNum = killsForMoabWithHardline * (lapCount - 1);
			//if the player has a streak greater than totalRequiredKills * the amount of moabs we have ( ie. 25 , 49, 73 )
			if (self.pers["cur_kill_streak"] >= resetStreakNum + 1)
			{	
				//Reset MOAB flag
				canGiveMoab = 1;
			}
		}
		else
		{
			resetStreakNum = killsForMoabWithoutHardline * (lapCount - 1);
			//if the player has a streak greater than totalRequiredKills * the current lap ( ie. 26 , 51, 76 )
			if (self.pers["cur_kill_streak"] >= resetStreakNum + 1)
			{	
				//Reset MOAB flag
				canGiveMoab = 1;
			}
		}
		
		wait .1;
	}		
	
}

giveMoab(currentKillstreak)
{
	thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "nuke", currentKillstreak );
    self setplayerdata( "killstreaksState", "hasStreak", 0, 1 );
	giveKillstreak("nuke", self.pers["killstreaks"][0].earned, 0, self, 1 );
	return;
}