#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    replaceFunc(maps\mp\gametypes\_teams::balanceTeams, ::return_false); // Remove Team Balancing (potential cause of bug)

    level thread onPlayerConnectHook();
}

onPlayerConnectHook()
{
    level endon("game_ended");
    
    while(true)
    {
        level waittill("connected", player);
        
        if(!isDefined(player.pers["auto_assigned"])) // Force Auto Assign Players On Connection (Only does it once per game)
        {
            player [[level.autoassign]]();
            player.pers["auto_assigned"] = true;
        }
    }
}

return_true( var1, var2, var3, var4, var5 )
{
	return true;
}

return_false( var1, var2, var3, var4, var5 )
{
	return false;
}