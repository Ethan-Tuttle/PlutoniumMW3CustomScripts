#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\killstreaks\_killstreaks;
#include maps\mp\_events;
#include maps\mp\killstreaks\_teamammorefill;

init()
{
    level thread onPlayerConnect();
	level thread replaceSpecialist();
}
 
onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
		
        player thread onPlayerSpawned();
		player thread KillstreakPlayer();
    }
}
 
onPlayerSpawned()
{	
    self endon("disconnect");
    level endon("game_ended");
    for(;;)
    {	
		self waittill ("spawned_player");
		level.blastShieldMod = 0.3; 	//Blast Shield Hella Buffed

		self initKsIcons();
        self cleanupKsIcons();
		self thread superSoldier();
	}    
}

initKsIcons()
{
    if ( isDefined(self.ksIcons) )
        return;

    self.ksIconsMax = 6;
    self.ksIcons = [];

    for ( i = 0; i < self.ksIconsMax; i++ )
        self.ksIcons[i] = undefined;
}

cleanupKsIcons()
{
    // Kill all icon threads immediately
    self notify("clear_icons");

    for ( i = 0; i < self.ksIconsMax; i++ )
    {
        if ( isDefined(self.ksIcons[i]) )
        {
            self.ksIcons[i] destroyElem();
            self.ksIcons[i] = undefined;
        }
    }
}

showKillstreakAlert( icon_name, message, sound )
{
    self endon("disconnect");
    self endon("clear_icons");

    self iprintlnbold(message);
    self playlocalsound(sound);

    icon = self createIcon(icon_name, 50, 50);
    icon.archived = false; // engine safety

    // Find a free slot
    slot = -1;
    for ( i = 0; i < self.ksIconsMax; i++ )
    {
        if ( !isDefined(self.ksIcons[i]) )
        {
            slot = i;
            self.ksIcons[i] = icon;
            break;
        }
    }

    // If all slots are full, destroy immediately
    if ( slot == -1 )
    {
        icon destroyElem();
        return;
    }

    // Icon setup
    icon.alpha = 0;
    icon.alignX = "CENTER";
    icon.alignY = "CENTER";
    icon.x = 425;
    icon.y = 90; 
    icon.HideWhenInMenu = true;
    icon.foreground = false;

    // Fade in
    icon fadeOverTime(0.3);
    icon.alpha = 1;

    wait 2.25;

    // Fade out
    icon fadeOverTime(0.3);
    icon.alpha = 0;

    // Safe cleanup
    if ( isDefined(self.ksIcons[slot]) )
    {
        self.ksIcons[slot] = undefined;
        icon destroyElem();
    }
}

replaceSpecialist()
{
	replaceFunc( maps\mp\killstreaks\_killstreaks::giveAllPerks, ::giveAllPerks );
}


giveAllPerks()
{
	var_0 = [];
	var_0[var_0.size] = "specialty_longersprint";
	var_0[var_0.size] = "specialty_fastreload";
	var_0[var_0.size] = "specialty_scavenger";
	var_0[var_0.size] = "specialty_blindeye";
	var_0[var_0.size] = "specialty_paint";
	var_0[var_0.size] = "specialty_hardline";
	var_0[var_0.size] = "specialty_coldblooded";
	var_0[var_0.size] = "specialty_quickdraw";
	var_0[var_0.size] = "_specialty_blastshield";
	var_0[var_0.size] = "specialty_detectexplosive";
	var_0[var_0.size] = "specialty_autospot";
	var_0[var_0.size] = "specialty_bulletaccuracy";
	var_0[var_0.size] = "specialty_quieter";
	var_0[var_0.size] = "specialty_stalker";
	var_0[var_0.size] = "specialty_marksman";
	var_0[var_0.size] = "specialty_sharp_focus";
	var_0[var_0.size] = "specialty_longerrange";
	var_0[var_0.size] = "specialty_fastermelee";
	var_0[var_0.size] = "specialty_reducedsway";
	var_0[var_0.size] = "specialty_lightweight";

	foreach ( var_2 in var_0 )
	{
		if ( !maps\mp\_utility::_hasPerk( var_2 ) )
		{
			maps\mp\_utility::givePerk( var_2, 0 );

			if ( maps\mp\gametypes\_class::isPerkUpgraded( var_2 ) )
			{
				var_3 = tablelookup( "mp/perktable.csv", 1, var_2, 8 );
				maps\mp\_utility::givePerk( var_3, 0 );
			}
		}
	}
}

KillstreakPlayer()
{
	self endon ("disconnect");
	level endon("game_ended");	
	self.hudkillstreak = createFontString( "Objective", 1 );
	self.hudkillstreak setPoint( "CENTER", "TOP", "CENTER", 10 );
	self.hudkillstreak.label = &"^5 KILLSTREAK: ^7";
	while(true)
	{
		self.hudkillstreak setValue(self.pers["cur_kill_streak"]);
		wait 0.5;
	}
}

superSoldier()
{
	self endon ("disconnect");
	level endon ("game_ended");
	self endon( "death" );
	
	//Flag to show upgraded ads speed
	messageShownADS = 0;
	//Flag to show upgraded movement speed
	messageShownMovement = 0;
	//Flag to show upgraded reload perk
	messageShownAutoReload = 0;
	//Flag to show upgraded steady aim perk
	messageShownSteadyAim = 0;
	//Flag to show health regeneration
	messageShownHealthRegen = 0; 
	//Flag to show Damage acquisition
	messageShownDamage = 0;
	//Flag to show Scavenger Bag equipment notice
	messageShownScavenger = 0;

	currentKills = 0;
	previousKills = currentKills;

	currentKillsB = 0;
	previousKillsB = currentKillsB;
	
	while(true)
	{
		//if the player has blastshield
		if ( isdefined( self.perks["_specialty_blastshield"] ) )
		{
			self.stunScaler = 0.4; 	//How long we stay stunned/flashed gets nerfed HARD
		}

		//if the player is on a 12 killstreak or higher AND we have not shown the message yet
		if ( (self.pers["cur_kill_streak"] >= 12) && (messageShownADS == 0) )
		{	
			//Give player modifiers and show message
			self giveSpecialtyQuickdraw();
			messageShownADS = 1;
		}	

		//if the player is on a 14 killstreak or higher AND we have not shown the message yet
		if ( (self.pers["cur_kill_streak"] >= 14) && (messageShownMovement == 0) )
		{	
			//Give player modifiers and show message
			self giveSpecialtyMovementSpeed();
			messageShownMovement = 1;
		}

		//if the current killstreak is above a 16 killstreak
		if ( (self.pers["cur_kill_streak"] >= 16) )
		{	
			//if the amount of kills this frame is greater than the previous ammount, apply the perk
			currentKills = self getPlayerStat( "kills" );
			if (currentKills > previousKills)
			{
				//apply the perk
				self reloadWeaponOnKill();
				//update kills
				previousKills = currentKills;
			}

			if (messageShownAutoReload == 0)
			{
				showKillstreakAlert( "specialty_fastreload_upgrade", "^3 16 Killstreak: ^2Kills Fill Magazine!" , "mp_vest_deployed_ui" );
				messageShownAutoReload = 1;
			}
		}

		//if the player is on an 18 killstreak or higher AND we have not shown the message yet
		if ( (self.pers["cur_kill_streak"] >= 18) && (messageShownSteadyAim == 0) )
		{	
			//Give player modifiers and show message
			self givesuperSteadyAim();
			messageShownSteadyAim = 1;
		}	

		//if the current killstreak is above or equal to a 20 killstreak
		if ( (self.pers["cur_kill_streak"] >= 20) )
		{	
			//if the amount of kills this frame is greater than the previous ammount, apply the perk
			currentKillsB = self getPlayerStat( "kills" );
			if (currentKillsB > previousKillsB)
			{
				//apply the perk
				self triggerHealthRegen();
				//update kills
				previousKillsB = currentKillsB;
			}

			if (messageShownHealthRegen == 0)
			{
				showKillstreakAlert( "specialty_coldblooded_upgrade", "^3 20 Killstreak: ^2Kills Trigger Health Regeneration!" , "mp_vest_deployed_ui" );
				messageShownHealthRegen = 1;
			}
		}
		
		//if the player is on a 25 killstreak or higher AND we have not shown the message yet
		if ( (self.pers["cur_kill_streak"] >= 25) && (messageShownDamage == 0) )
		{	
			//Give player modifiers and show message
			self giveSpecialtyDamage();
			messageShownDamage = 1;
		}
		wait .1;
	}
}

giveSpecialtyQuickdraw()
{
	self _setPerk ("specialty_quickdraw",1);	
	self setclientdvar ("perk_quickDrawSpeedScale","1.82");
	showKillstreakAlert( "specialty_quickdraw_upgrade", "^3 12 Killstreak: ^2ADS Speed Increased!" , "mp_vest_deployed_ui" );
	return;
}

giveSpecialtyMovementSpeed()
{
	self _setPerk( "specialty_lightweight", 1 );
	self.moveSpeedScaler = 1.35;
	self setmovespeedscale( self.moveSpeedScaler );
	showKillstreakAlert( "specialty_longersprint_upgrade", "^3 14 Killstreak: ^2Movement Speed Increased!" , "mp_vest_deployed_ui" );
	return;
}

reloadWeaponOnKill()
{
	//Get the name of the current weapon in hand
	weaponName = self getcurrentweapon();

	//This gets the ammo of the weapon in the right hand
	rightAmmo = self getWeaponAmmoClip(weaponName , "right");

	//This gets the ammo of the weapon in the left hand
	leftAmmo = self getWeaponAmmoClip(weaponName , "left");

	//Calculate the total shots fired in a given mag
	shotsFiredThisMagRight = weaponclipsize( weaponName , "right") - rightAmmo;
	shotsFiredThisMagLeft = weaponclipsize( weaponName , "left") - leftAmmo;

	//Update the magazine to max ammo
	self setweaponammoclip( weaponName , rightAmmo + shotsFiredThisMagRight , "right");
	self setweaponammoclip( weaponName , leftAmmo + shotsFiredThisMagLeft , "left");

	return;
}

givesuperSteadyAim()
{
	self setaimspreadmovementscale( 0.2 );
	self setspreadoverride( 2 );
	showKillstreakAlert( "specialty_steadyaim_upgrade", "^3 18 Killstreak: ^2Hip-Fire Accuracy Increased!" , "mp_vest_deployed_ui" );

	return;
}

triggerHealthRegen()
{
	self.health = self.maxHealth;
	return;
}

giveSpecialtyDamage()
{
	self _setPerk ("specialty_moredamage");
	showKillstreakAlert( "specialty_perks_all", "^3 25 Killstreak: ^2All Bullet Damage Increased!" , "mp_vest_deployed_ui" );
	return;
}