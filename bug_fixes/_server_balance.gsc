#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\bots\_bots;

#define DISABLE_BOT_KILLSTREAKS 1 // True = bot killstreaks on while false = bot killstreaks off

init()
{
    if ( maps\mp\_utility::invirtuallobby() )
        return;
    
    replacefunc(maps\mp\perks\_perks::validateperk, ::validateperkHook); // Removes last stand + final stand
    replaceFunc(maps\mp\perks\_perks::cac_modified_damage, ::cac_modified_damageHook); // Nerfs stopping power, danger close, and concussion + flashes (does not REMOVE the perks/equipment, just nerfs the effects so challenges can be completed)
    replacefunc(maps\mp\gametypes\_hardpoints::givehardpointitemforstreak, ::givehardpointitemforstreakHook); // Patches chopper gunner streak and replace with AC130
    replacefunc(maps\mp\gametypes\_weapons::onweapondamage, ::onweapondamageHook); // Nerf concussions/flashes fx
    replaceFunc(maps\mp\gametypes\_teams::balanceTeams, ::return_false); // Remove Team Balancing (potential cause of bug)

    // Removes the dialog in-game and helps for a (quieter experience)
    replacefunc(maps\mp\gametypes\_music_and_dialog::init, ::return_false);
    replacefunc(maps\mp\_utility::leaderdialogonplayer_internal, ::return_false);
    replacefunc(maps\mp\gametypes\_battlechatter_mp::init, ::return_false);

    setDvarForce("dmg_debug", false); // Debugging dvar for damage call prints
    setDvarForce("gl_nerf", false); // If true, it nerfs the "Grenade Launchers" damage
    setDvarForce("launcher_nerf", false); // If true, it nerfs the "Launchers" damage
    setDvarForce("ksg_nerf", false); // If true, it nerfs the ksg damage

    level thread onPlayerConnectHook();
}

onPlayerConnectHook()
{
    while(true)
    {
        level waittill("connected", player);

        if(!isDefined(player.pers["auto_assigned"])) // Force Auto Assign Players On Connection (Only does it once per game) - potentially fixes ghost player bug (invalid client)
        {
            player [[level.autoassign]]();
            player.pers["auto_assigned"] = true;
        }

        player.stunscaler = 0.1; // Mini Nerf for FX
    }
}

/* Utils */

return_true(var1, var2, var3, var4, var5)
{
    return true;
}

return_false(var1, var2, var3, var4, var5)
{
    return false;
}

setDvarForce(dvar, value) // Safe dvar setter
{
    setDvar(dvar, value);
    setdynamicdvar(dvar, value);
}

/* Hooks */

applyloadoutHook()
{
    var_0 = self.loadout;

    if ( !isdefined( self.loadout ) )
        return;

    self.loadout = undefined;
    self.spectatorviewloadout = var_0;
    self takeallweapons();
    maps\mp\_utility::_clearperks();
    maps\mp\gametypes\_class::_detachall();
    self.changingweapon = undefined;

    if ( var_0.copycatloadout )
        self.curclass = "copycat";

    self.class_num = var_0.class_num;
    self.loadoutprimary = var_0.primary;
    self.loadoutprimarycamo = int( tablelookup( "mp/camoTable.csv", 1, var_0.primarycamo, 0 ) );
    self.loadoutsecondary = var_0.secondary;
    self.loadoutsecondarycamo = int( tablelookup( "mp/camoTable.csv", 1, var_0.secondarycamo, 0 ) );

    if ( !issubstr( var_0.primary, "iw5" ) && !issubstr( var_0.primary, "h1_" ) && !issubstr( var_0.primary, "h2_" ))
        self.loadoutprimarycamo = 0;

    if ( !issubstr( var_0.secondary, "iw5" ) && !issubstr( var_0.secondary, "h1_" ) && !issubstr( var_0.secondary, "h2_" ))
        self.loadoutsecondarycamo = 0;

    self.loadoutprimaryreticle = int( tablelookup( "mp/reticleTable.csv", 1, var_0.primaryreticle, 0 ) );
    self.loadoutsecondaryreticle = int( tablelookup( "mp/reticleTable.csv", 1, var_0.secondaryreticle, 0 ) );

    if ( !issubstr( var_0.primary, "iw5" ) && !issubstr( var_0.primary, "h1_" ) && !issubstr( var_0.primary, "h2_" ))
        self.loadoutprimaryreticle = 0;

    if ( !issubstr( var_0.secondary, "iw5" ) && !issubstr( var_0.secondary, "h1_" ) && !issubstr( var_0.secondary, "h2_" ))
        self.loadoutsecondaryreticle = 0;

    self.loadoutmelee = var_0.meleeweapon;

    if ( isdefined( var_0.juggernaut ) && var_0.juggernaut )
    {
        self.health = self.maxhealth;
        thread maps\mp\_utility::recipeclassapplyjuggernaut( maps\mp\_utility::isjuggernaut() );
        self.isjuggernaut = 1;
        self.juggmoveSpeedScaler = 0.7;
    }
    else if ( maps\mp\_utility::isjuggernaut() )
    {
        self notify( "lost_juggernaut" );
        self.isjuggernaut = 0;
        self.moveSpeedScaler = level.baseplayermovescale;
    }

    var_2 = var_0.secondaryname;

    if ( var_2 != "none" )
    {
        // Liam - 21/02/2024 onemanarmy implementation
        can_give_secondary = true;

        if (isdefined(var_0.perks) && var_0.perks.size > 0)
        {
            if (var_0.perks[0] == "specialty_onemanarmy" || var_0.perks[0] == "specialty_omaquickchange")
            {
                can_give_secondary = false;

                if( !maps\mp\_utility::invirtuallobby() )
                    maps\mp\_utility::_giveweapon( "onemanarmy_mp" );
            }
        }

        if (can_give_secondary)
            maps\mp\_utility::_giveweapon( var_2 );

        if ( level.oldschool )
            maps\mp\gametypes\_oldschool::givestartammooldschool( var_2 );
    }

    if ( level.diehardmode && !isBot(self) )
        maps\mp\_utility::giveperk( "specialty_pistoldeath", 0 );

    maps\mp\gametypes\_class::loadoutallperks( var_0 );
    maps\mp\perks\_perks::applyperks();

    if (var_0.equipment == "specialty_tacticalinsertion")
    {
        self maps\mp\_utility::giveperk( "specialty_tacticalinsertion", 0 );    
        self setlethalweapon( "flare_mp" );
    }
    else if (var_0.equipment == "specialty_blastshield")
    {
        self maps\mp\_utility::giveperk( "specialty_blastshield", 0 );    
        self setlethalweapon( "none" );
    }
    else
        self setlethalweapon( var_0.equipment );

    if ( isdefined(var_0.equipment) && var_0.equipment != "specialty_null" && 
        ( scripts\mp_patches\custom_weapons::is_perk_actually_weapon(var_0.equipment) && self hasweapon(var_0.equipment)) )
    {
        self setweaponammoclip( var_0.equipment, weaponStartAmmo( var_0.equipment ) );
    }
    else
        scripts\mp_patches\custom_weapons::giveoffhand( var_0.equipment );

    var_5 = var_0.primaryname;
    maps\mp\_utility::_giveweapon( var_5 );

    if ( level.oldschool )
        maps\mp\gametypes\_oldschool::givestartammooldschool( var_5 );

    if ( !isai( self ) && !maps\mp\_utility::ishodgepodgemm() )
        self switchtoweapon( var_5 );

    if ( var_0.setprimaryspawnweapon )
        self setspawnweapon( maps\mp\_utility::get_spawn_weapon_name( var_0 ) );
    self.pers["primaryWeapon"] = maps\mp\_utility::getbaseweaponname( var_5 );
    self.loadoutoffhand = var_0.offhand;
    self settacticalweapon( var_0.offhand );

    if ( !level.oldschool )
        scripts\mp_patches\custom_weapons::giveoffhand( var_0.offhand );

    self setweaponammoclip( var_0.offhand, weaponStartAmmo( var_0.offhand ) );

    if ( level.oldschool )
        self setweaponammoclip( var_0.offhand, 0 );

    var_6 = var_5;
    self.primaryweapon = var_6;
    self.secondaryweapon = var_2;

    if ( var_0.clearammo )
    {
        self setweaponammoclip( self.primaryweapon, 0 );
        self setweaponammostock( self.primaryweapon, 0 );
    }

    self.issniper = weaponclass( self.primaryweapon ) == "sniper";
    maps\mp\_utility::_setactionslot( 1, "nightvision" );
    maps\mp\perks\_perks::giveperkinventory();
    maps\mp\_utility::_setactionslot( 4, "" );

    if ( !level.console )
    {
        maps\mp\_utility::_setactionslot( 5, "" );
        maps\mp\_utility::_setactionslot( 6, "" );
        maps\mp\_utility::_setactionslot( 7, "" );
        maps\mp\_utility::_setactionslot( 8, "" );
    }

    if ( maps\mp\_utility::_hasperk( "specialty_extraammo" ) )
    {
        self givemaxammo( var_5 );

        if ( var_2 != "none" )
            self givemaxammo( var_2 );
    }

    if ( !issubstr( var_0.class, "juggernaut" ) )
    {
        if ( isdefined( self.lastclass ) && self.lastclass != "" && self.lastclass != self.class )
            self notify( "changed_class" );

        self.pers["lastClass"] = self.class;
        self.lastclass = self.class;
    }

    if ( isdefined( self.gamemode_chosenclass ) )
    {
        self.pers["class"] = self.gamemode_chosenclass;
        self.pers["lastClass"] = self.gamemode_chosenclass;
        self.class = self.gamemode_chosenclass;

        if ( !isdefined( self.gamemode_carrierclass ) )
            self.lastclass = self.gamemode_chosenclass;

        self.gamemode_chosenclass = undefined;
    }

    self.gamemode_carrierclass = undefined;

    if ( !isdefined( level.iszombiegame ) || !level.iszombiegame )
    {
        if ( !isdefined( self.costume ) )
        {
            if ( isplayer( self ) )
                self.costume = maps\mp\gametypes\_class::cao_getactivecostume();
            else if ( isagent( self ) && self.agent_type == "player" )
                self.costume = maps\mp\gametypes\_teams::getdefaultcostume();
        }

        if ( maps\mp\_utility::invirtuallobby() && isdefined( level.vl_cac_getfactionteam ) && isdefined( level.vl_cac_getfactionenvironment ) )
        {
            var_7 = [[ level.vl_cac_getfactionteam ]]();
            var_8 = [[ level.vl_cac_getfactionenvironment ]]();
            maps\mp\gametypes\_teams::applycostume( var_6, var_7, var_8 );
        }
        else if ( level.teambased )
            maps\mp\gametypes\_teams::applycostume();
        else
            maps\mp\gametypes\_teams::applycostume( var_6, self.team );

        maps\mp\gametypes\_class::logplayercostume();
        self _meth_857C( var_0._id_A7ED );
    }

    self maps\mp\gametypes\_weapons::updatemovespeedscale( "primary" );

    maps\mp\perks\_perks::cac_selector();

    loadoutDeathStreak = var_0.deathstreak;

    // only give the deathstreak for the initial spawn for this life.
    if ( isdefined(loadoutDeathStreak) && loadoutDeathStreak != "specialty_null" && gettime() == self.spawnTime )
    {
        if( loadoutDeathStreak == "specialty_copycat" )
            deathVal = 3;
        else if( loadoutDeathStreak == "specialty_combathigh" )
            deathVal = 5;
        else
            deathVal = 4;

        if ( self maps\mp\_utility::_hasPerk( "specialty_rollover" ) )
            deathVal -= 1;

        if ( isdefined(self.pers["cur_death_streak"]) && self.pers["cur_death_streak"] >= deathVal )
            self thread maps\mp\_utility::givePerk( loadoutDeathStreak );
    }

    self notify( "changed_kit" );
    self notify( "applyloadout" );
}

cac_modified_damageHook( victim, attacker, damage, meansofdeath, weapon, impactPoint, impactDir, hitLoc )
{
    assert( isPlayer( victim ) );
    assert( isDefined( victim.team ) );

    if ( !isDefined( victim ) || !isDefined( attacker ) || !isplayer( attacker ) || !maps\mp\_utility::invirtuallobby() && !isplayer( victim ) )
        return damage;

    if ( attacker.sessionstate != "playing" || !isDefined( damage ) || !isDefined( meansofdeath ) )
        return damage;

    if ( meansofdeath == "" )
        return damage;

    damageAdd = 0;

    if ( meansofdeath == "MOD_FALLING" )
    {
        if ( victim _hasPerk( "specialty_falldamage" ) )
        {	
            damageAdd = 0;
            damage = 0;
        }	
    }

    if(isSubStr(weapon, "ksg") && getDvarInt("ksg_nerf"))
        damage = int(damage/randomInt(4));

    if(isSubStr(weapon, "_gl") && maps\mp\perks\_perks::isExplosiveDamage(meansofdeath) && getDvarInt("gl_nerf"))
        damage = randomInt(25);

    if(maps\mp\_utility::getweaponclass(weapon) == "weapon_launcher" && getDvarInt("launcher_nerf"))
        damage = randomInt(25);

    bad_offhands = strTok("h1_concussiongrenade_mp,h1_flashgrenade_mp");
    foreach(item in bad_offhands)
    {
        if(weapon == item)
            return;
    }

    if ( victim _hasperk( "specialty_combathigh" ) )
    {
        if ( isDefined( self.damageBlockedTotal ) && (!level.teamBased || ( isDefined( attacker ) && isDefined( attacker.team ) && victim.team != attacker.team ) ) )
        {
            damageTotal = damage + damageAdd;
            damageBlocked = ( damageTotal - ( damageTotal / 3 ) );
            self.damageBlockedTotal += damageBlocked;

            if ( self.damageBlockedTotal >= 101 )
            {
                self notify( "combathigh_survived" );
                self.damageBlockedTotal = undefined;
            }
        }

        if ( weapon != "iw9_throwknife_mp" )
        {
            switch ( meansOfDeath )
            {
                case "MOD_FALLING":
                case "MOD_MELEE":
                    break;
                default:
                    damage = damage / 3;
                    damageAdd = damageAdd / 3;
                    break;
            }
        }
    }

    //print( "post damage: " + int( damage + damageAdd ) );	

    if(getDvarInt("dmg_debug"))
        attacker iPrintLn("^1Damage: [" + int(damage) + "] from Weapon: [" + weapon + "]");

    return int( damage + damageAdd );
}

onweapondamageHook( var_0, var_1, var_2, var_3, var_4 )
{
    self endon( "death" );
    self endon( "disconnect" );
    var_5 = 700;
    var_6 = 25;
    var_7 = var_5 * var_5;
    var_8 = var_6 * var_6;
    var_9 = 60;
    var_10 = 40;
    var_11 = 11;

    if ( issubstr( var_1, "_uts19_" ) )
        thread maps\mp\gametypes\_weapons::uts19shock( var_0 );
    else
    {
        var_12 = maps\mp\_utility::strip_suffix( var_1, "_lefthand" );

        switch ( var_12 )
        {
        case "h1_concussiongrenade_mp":
            if ( !isdefined( var_0 ) )
                return;

            if ( maps\mp\_utility::is_true( self.concussionimmune ) )
                return;

            var_13 = 1;

            if ( isdefined( var_0.owner ) && var_0.owner == var_4 )
                var_13 = 0;

            var_14 = 512;
            var_15 = 1 - distance( self.origin, var_0.origin ) / var_14;

            if ( var_15 < 0 )
                var_15 = 0;

            var_16 = 2 + 4 * var_15;

            if ( isdefined( self.stunscaler ) )
                var_16 *= self.stunscaler;

            wait 0.05;
            self notify( "concussed", var_4 );
            self.concussionendtime = gettime() + var_16 * 1000;

            if ( isdefined( var_4 ) && var_4 != self )
                self.concussionattacker = var_4;
            else
                self.concussionattacker = undefined;

            break;
        case "h1_flashgrenade_mp":
            if ( !isdefined( var_0 ) )
                return;

            if ( maps\mp\_utility::is_true( self.concussionimmune ) )
                return;

            var_13 = 1;

            if ( isdefined( var_0.owner ) && var_0.owner == var_4 )
                var_13 = 0;

            var_14 = 512;
            var_15 = 1 - distance( self.origin, var_0.origin ) / var_14;

            if ( var_15 < 0 )
                var_15 = 0;

            var_16 = 2 + 4 * var_15;

            if ( isdefined( self.stunscaler ) )
                var_16 *= self.stunscaler;

            wait 0.05;
            self notify( "concussed", var_4 );
            self.concussionendtime = gettime() + var_16 * 1000;

            if ( isdefined( var_4 ) && var_4 != self )
                self.concussionattacker = var_4;
            else
                self.concussionattacker = undefined;

            break;
        case "weapon_cobra_mk19_mp":
            break;
        default:
            maps\mp\gametypes\_shellshock::shellshockondamage( var_2, var_3 );
            break;
        }
    }
}

validateperkHook( var_0, var_1 )
{
    if ( getdvarint( "scr_game_perks" ) == 0 )
        return "specialty_null";

    if ( var_0 == 0 )
    {
        switch ( var_1 )
        {
            case "specialty_longersprint":
            case "specialty_fastmantle":
            case "specialty_fastreload":
            case "specialty_quickdraw":
            case "specialty_scavenger":
            case "specialty_extraammo":
            case "specialty_bling":
            case "specialty_secondarybling":
            case "specialty_onemanarmy":
            case "specialty_omaquickchange":
                return var_1;
            default:
                break;
        }
    }
    else if ( var_0 == 1 )
    {
        switch ( var_1 )
        {
            case "specialty_bulletdamage":
            case "specialty_armorpiercing":
            case "specialty_lightweight":
            case "specialty_fastsprintrecovery":
            case "specialty_hardline":
            case "specialty_rollover":
            case "specialty_radarimmune":
            case "specialty_spygame":
            case "specialty_explosivedamage":
            case "specialty_dangerclose":
                return var_1;
            default:
                break;
        }
    }
    else if ( var_0 == 2 )
    {
        switch ( var_1 )
        {
            case "specialty_extendedmelee":
            case "specialty_falldamage":
            case "specialty_bulletaccuracy":
            case "specialty_holdbreath":
            case "specialty_localjammer":
            case "specialty_delaymine":
            case "specialty_heartbreaker":
            case "specialty_quieter":
            case "specialty_detectexplosive":
            case "specialty_selectivehearing":
                return var_1;
            default:
                break;
        }
    }

    return "specialty_null";
}

givehardpointitemforstreakHook()
{
	if ( isBot(self) && DISABLE_BOT_KILLSTREAKS )
		return;

	array = self.customKillstreaks;
	player_streak = self.pers["cur_kill_streak"];

	foreach ( hardpoint in array )
	{
		if ( getdvarint( "scr_game_forceuav" ) && hardpoint == "radar_mp" )
			continue;

		killstreak_cost = level.hardpointitems[hardpoint];

		if ( self maps\mp\_utility::_hasPerk( "specialty_hardline" ) )
			killstreak_cost--;

		if ( player_streak == killstreak_cost )
		{
            if(hardpoint == "chopper_gunner_mp") // Soft Patch for Chopper Gunner
            {
                thread maps\mp\gametypes\_hardpoints::givehardpoint( "ac130_mp", player_streak );
                break;
            }
            else
            {
                thread maps\mp\gametypes\_hardpoints::givehardpoint( hardpoint, player_streak );
                break;
            }
		}
	}
}