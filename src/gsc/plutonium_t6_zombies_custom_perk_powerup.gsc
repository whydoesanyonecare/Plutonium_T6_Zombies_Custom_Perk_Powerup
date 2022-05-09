//issues: hint for custom perks cannot be disabled in afterlife perks restore or player wont get any perks back

#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/_demo;
#include maps/mp/zombies/_zm_audio;
#include maps/mp/zombies/_zm_pers_upgrades_functions;
#include maps/mp/zombies/_zm_power;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include maps\mp\zombies\_zm_stats;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_chugabud;
#include maps/mp/zombies/_zm_afterlife;
#include maps/mp/zombies/_zm_tombstone;
#include maps/mp/zombies/_zm_equipment;
#include maps/mp/zombies/_zm_perk_vulture;
init()
{
	level.background_shader = getdvarintdefault("enable_background", 1);

    level thread onPlayerConnect();
    level thread TrackPerkPowerup();
    isTown(); //tombstone fix 

    include_zombie_powerup("random_perk");
    add_zombie_powerup("random_perk", "t6_wpn_zmb_perk_bottle_sleight_world", &"ZOMBIE_POWERUP_RANDOM_PERK", ::func_should_drop_limited, 0, 0, 0); 
    powerup_set_can_pick_up_in_last_stand("random_perk", 1);
    precacheshaders = array("hud_grenadeicon","killiconheadshot","menu_mp_weapons_1911","hud_icon_sticky_grenade","faction_cdc","specialty_chugabud_zombies","specialty_electric_cherry_zombie","specialty_additionalprimaryweapon_zombies","menu_mp_lobby_icon_customgamemode","specialty_divetonuke_zombies","zombies_rank_1","zombies_rank_3","zombies_rank_2","zombies_rank_4","zombies_rank_5","menu_lobby_icon_facebook","menu_mp_weapons_1911","hud_icon_colt","waypoint_revive","hud_grenadeicon","damage_feedback","menu_lobby_icon_twitter","specialty_doubletap_zombies");
    foreach(shader in precacheshaders)
    {
        precacheshader(shader);
    }
	level.perk_purchase_limit = 50;
	level.zombie_last_stand = ::LastStand;
    level.effect_WebFX = loadfx("misc/fx_zombie_powerup_solo_grab");

    level.get_player_weapon_limit = ::custom_get_player_weapon_limit;
	
    set_zombie_var( "riotshield_hit_points", 1500 );
    if(isDefined(level.player_damage_callbacks[0]))
    {
        level.first_player_damage_callback = level.player_damage_callbacks[0];
        level.player_damage_callbacks[0] = ::damage_callback;
    } 
    else 
    {
        maps/mp/zombies/_zm::register_player_damage_callback( ::damage_callback );
    }
    if(isDefined(level._zombiemode_powerup_grab))
    {
        level.original_zombiemode_powerup_grab = level._zombiemode_powerup_grab;
    }
    level._zombiemode_powerup_grab = ::custom_powerup_grab;
    flag_wait( "initial_blackscreen_passed" );
    replacefunc(::give_perk, ::Custom_give_perk); //find alternative for replace func

    replacefunc(::chugabud_give_loadout, ::custom_chugabud_give_loadout);//find alternative for replace func
    replacefunc(::chugabud_save_loadout, ::custom_chugabud_save_loadout);//find alternative for replace func

	//level.chugabud_laststand_func = ::chugabud_laststand; //alternative for replacefunc ^ ( need alot more functions to work )

    level.tombstone_spawn_func = ::tombstone_spawn;
	level.tombstone_laststand_func = ::custom_tombstone_laststand;
    
    level.afterlife_save_loadout = ::custom_afterlife_save_loadout;
    level.afterlife_give_loadout = ::custom_afterlife_give_loadout;

}

wait_end_game()
{
	level waittill( "end_game" );
	players = getplayers();
	for(i=0;i<players.size;i++)
	{
		if(isDefined(players[i].perk_hud))
		{
			foreach(hud in players[i].perk_hud)
			{
				hud destroy();
			}
		}
		if(isDefined(players[i].background_perk))
		{
			foreach(hud2 in players[i].background_perk)
			{
				hud2 destroy();
			}
		}
	}
}

onPlayerConnect()
{
	level endon("end_game");
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("end_game");
	self waittill("spawned_player");
	self.dying_wish_on_cooldown = 0;
	self.perk_hud = [];
	self.perkarray = [];
	self.background_perk = [];
	self.saved_perks = [];

	self thread PlayerDownedWatcher();
}

PlayerDownedWatcher()
{
	level endon("end_game");
	self endon("disconnect");
	while(1)
	{
		self waittill_any_return( "fake_death", "player_downed", "player_revived", "spawned_player", "disconnect", "death", "end_game" );
		foreach(hud in self.perk_hud)
    	{
            hud destroy();
    	}
        foreach(hud2 in self.background_perk)
    	{
            hud2 destroy();
    	}
        self.background_perk = [];
        self.perkarray = [];
        self.perk_hud = [];
        self notify("stopcustomperk");
        self.bleedout_time = 30;
	    self.ignore_lava_damage = 0;
	}
}

custom_save_perks()
{
	self.saved_perks = [];
    for(i = 0; i < self.perkarray.size; i++)
    {
        if(self.perkarray[i] != "specialty_finalstand" && self.perkarray[i] != "specialty_scavenger")
        {
		    self.saved_perks[self.saved_perks.size] = self.perkarray[i];
	    }
    }
	perk_array = maps/mp/zombies/_zm_perks::get_perk_array( 0 );
	for (i = 0; i < perk_array.size; i++)
    {
		perk = perk_array[i];
		self unsetperk( perk );
	}
}

TrackPerkPowerup()
{
    level endon("end_game");
    level.roundsplayed = 0;
    for(;;)
    {
        level waittill("start_of_round");
        level.roundsplayed += 1;
        wait .5;
    }
}

func_should_drop_limited()
{
    if (level.round_number > 10 && isDefined( level.roundsplayed ) && level.roundsplayed < 1 )
    {
        return 0;
    }
    if (level.round_number < 10 && isDefined( level.roundsplayed ) && level.roundsplayed < 2 )
    {
        return 0;
    }
    return 1;
}

custom_powerup_grab(s_powerup, e_player)
{
	if (s_powerup.powerup_name == "random_perk")
	{
	    foreach(player in level.players)
	    {
		    player thread give_random_perk();
            level.roundsplayed = 0;
	    }
	}
	else if (isDefined(level.original_zombiemode_powerup_grab))
		level thread [[level.original_zombiemode_powerup_grab]](s_powerup, e_player);
}

custom_give_perk( perk, bought, custom, saved_perk )
{
    if(!custom)
    {
        self SetPerk( perk );
        self.num_perks++;
        if ( is_true( bought ) )
        {
            self maps\mp\zombies\_zm_audio::playerExert( "burp" );
            self delay_thread (1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );
            self setblur( 4, 0.1 );
            wait .1;
            self setblur(0, 0.1);
            self notify( "perk_bought", perk );
        }
        if(perk == "specialty_armorvest")
        {
            self.preMaxHealth = self.maxhealth;
            self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health"] );
        }
        else if(perk == "specialty_armorvest_upgrade")
        {
            self.preMaxHealth = self.maxhealth;
            self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health_upgrade"] );
        }
        if ( isDefined( level.disable_deadshot_clientfield ) && !level.disable_deadshot_clientfield )
        {
            if ( perk == "specialty_deadshot" || perk == "specialty_deadshot_upgrade")
            {
                self setclientfieldtoplayer( "deadshot_perk", 1 );
            }
        }
        if ( perk == "specialty_scavenger" )
        {
            self.hasperkspecialtytombstone = 1;
        }
        players = get_players();
        if ( use_solo_revive() && perk == "specialty_quickrevive" )
        {
            self.lives = 1;
            if ( !isDefined( level.solo_lives_given ) )
            {
                level.solo_lives_given = 0;
            }
            if ( isDefined( level.solo_game_free_player_quickrevive ) )
            {
                level.solo_game_free_player_quickrevive = undefined;
            }
            else
            {
                level.solo_lives_given++;
            }
            if ( level.solo_lives_given >= 3 )
            {
                flag_set( "solo_revive" );
            }
            self thread solo_revive_buy_trigger_move( perk );
        }
        if ( perk == "specialty_finalstand" )
        {
            self.lives = 1;
            self.hasperkspecialtychugabud = 1;
            self notify( "perk_chugabud_activated" );
        }

		if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) ) //for vulture aid and electric cherry
        	self thread [[ level._custom_perks[perk].player_thread_give ]]();

        maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
        if(!isDefined(self.perk_history))
        {
            self.perk_history = [];
        }
        self.perk_history = add_to_array(self.perk_history,perk,false);
        if ( !isDefined( self.perks_active ) )
        {
            self.perks_active = [];
        }
        self.perks_active[ self.perks_active.size ] = perk;
        self notify("perk_acquired");	
        self perk_hud_create( perk, 0, 0 );
        self thread perk_think( perk );
    }
    else
    {
        if(saved_perk)
        {
            self perk_hud_create( perk, 1, 0 );
            self.num_perks++;
        }
        else
        {
            self perk_hud_create( perk, 1, 1 );
            self.num_perks++;
        }
    }
}

perk_hud_create( perk, custom, print )
{
    if ( !IsDefined( self.perk_hud ) )
    {
        self.perk_hud = [];
    }
    shader = "";
    switch( perk )
    {
        //CUSTOM PERKS
        case "MULE":
            if(getdvar( "mapname" ) == "zm_prison")
            {
                shader = "specialty_additionalprimaryweapon_zombies";
            }
            else
            {
                color = (0, 0, 0);
                color1 = (0, 1, 0);
                background_shader = "specialty_doubletap_zombies";
                shader = "menu_mp_weapons_1911";
            }
            if(print)
			{
				self iprintln("^9Mule Kick");
				wait 0.2;
				self iprintln("This Perk enables additional primary weapon slot for player. ");
			}
            break;
        case "PHD_FLOPPER":
            if(getdvar( "mapname" ) == "zm_prison")
            {
                shader = "specialty_divetonuke_zombies";
            }
            else
            {
                color = (0, 0, 0);
                color1 = (1, 0, 1);
                background_shader = "specialty_doubletap_zombies";
                shader = "hud_grenadeicon";
            }
            if(print)
			{
				self iprintln("^9PhD Flopper");
				wait 0.2;
				self iprintln("This Perk removes explosion and fall damage also player creates explosion when dive to prone.");
			}
            break;
        case "Ethereal_Razor":
            color = (1, 0, 0);
            color1 = (1,1,1);
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_4";
            self thread start_er();
            if(print)
			{
				self iprintln("^9Ethereal Razor");
				wait 0.2;
				self iprintln("This Perk deals extra damage when player using melee attacks and restores a small amount of health.");
        	}
            break;
        case "Ammo_Regen":
            color = (0, 0, 0);
            color1 = (1,1,1);
            background_shader = "specialty_doubletap_zombies";
            shader = "menu_mp_lobby_icon_customgamemode";
            self thread ammoregen();
            self thread grenadesregen();
            if(print)
			{
				self iprintln("^9Ammo Regen");
				wait 0.2;
				self iprintln("This Perk will slowly regenerades players ammonation and grenades.");
			}
            break;
        case "Dying_Wish":
            color = (1, 0, 0);
            color1 = (1,1,1);
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_5";
            self thread dying_wish_checker();
            if(print)
			{
				self iprintln("^9Dying Wish");
				wait 0.2;
				self iprintln("This Perk allow player to go berserker mode for 9 seconds instead of laststand.");
				wait 0.1;
				self iprintln(" (cooldown 5mins and it's increased 30sec every time perk is used. - max 10mins) ");
			}
            break;
        case "Downers_Delight":
            background_shader = "specialty_doubletap_zombies";
            shader = "waypoint_revive";
            color = (0,0,0);
            color1 = (0,1,1);
            self thread DDown();
            if(print)
			{
				self iprintln("^9Downer's Delight");
				wait 0.2;
				self iprintln("This Perk will increase players bleedout time by 10 seconds and current weapons is used in laststand.");
			}
            break;
        case "Victorious_Tortoise":
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_2";
            color = (0,1,0);
            color1 = (1,1,1);
            if(print)
			{
				self iprintln("^9Victorious Tortoise");
				wait 0.2;
				self iprintln("This Perk allows shield block damage from all directions when in use.");
        	}
            break;
        case "ELECTRIC_CHERRY":
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_5";
            color = (0 ,0, 1);
            color1 = (1,1,1);
            self thread start_ec();
            if(print)
			{
				self iprintln("^9Electric Cherry");
				wait 0.2;
				self iprintln("This Perk creates an electric shockwave around the player whenever they reload.");
        	}
            break;
        case "WIDOWS_WINE":
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_3";
            self thread ww_nades();
            color = (0,0,0);
            color1 = (1,1,1);
            if(print)
			{
				self iprintln("^9Widow's Wine");
				wait 0.2;
				self iprintln("This Perk damages zombies around the player when player is hit and grenades are upgraded.");
        	}
            break;
        case "Burn_Heart":
            background_shader = "specialty_doubletap_zombies";
            shader = "zombies_rank_1";
            color = (1,0,0);
            color1 = (1,1,1);
            self.ignore_lava_damage = 1;
            if(print)
			{
				self iprintln("^9Burn Heart");
				wait 0.2;
				self iprintln("This Perk removes lava damage. (add more abilitys)");
			}
            break;
        case "deadshot":
            background_shader = "specialty_doubletap_zombies";
            shader = "killiconheadshot";
            color = (0,0,0);
            color1 = (1,1,1);
            self thread AimAssist();
            if(print)
			{
				self iprintln("^9Deadshot");
				wait 0.2;
				self iprintln("This Perk aims automatically enemys head instead of body.");
        	}
            break;

        //ORIGINAL PERKS
        case "specialty_armorvest_upgrade":
            shader = "specialty_juggernaut_zombies_pro";
            break;
        case "specialty_armorvest":
            shader = "specialty_juggernaut_zombies";
            break;
        case "specialty_quickrevive_upgrade":
            shader = "specialty_quickrevive_zombies_pro";
            break;
        case "specialty_quickrevive":
            shader = "specialty_quickrevive_zombies";
            break;
        case "specialty_fastreload_upgrade":
            shader = "specialty_fastreload_zombies_pro";
            break;
        case "specialty_fastreload":
            shader = "specialty_fastreload_zombies";
            break;
        case "specialty_rof_upgrade":
        case "specialty_rof":
            shader = "specialty_doubletap_zombies";
            break;
        case "specialty_longersprint_upgrade":
        case "specialty_longersprint":
            shader = "specialty_marathon_zombies";
            break;
        case "specialty_flakjacket_upgrade":
        case "specialty_flakjacket":
            shader = "specialty_divetonuke_zombies";
            break;
        case "specialty_deadshot_upgrade":
        case "specialty_deadshot":
            shader = "specialty_ads_zombies";
            break;
        case "specialty_additionalprimaryweapon_upgrade":
        case "specialty_additionalprimaryweapon":
            shader = "specialty_additionalprimaryweapon_zombies";
            break;
        case "specialty_scavenger_upgrade":
        case "specialty_scavenger": 
            shader = "specialty_tombstone_zombies";
            break;
        case "specialty_finalstand":
        case "specialty_finalstand_upgrade": 
            shader = "specialty_chugabud_zombies";
            break;
        case "specialty_nomotionsensor":
            shader = "specialty_vulture_zombies";
            break;
        case "specialty_grenadepulldeath":
            shader = "specialty_electric_cherry_zombie";
            break;
        default:
            shader = "";
            break;
    }

    if(custom && level.background_shader)
    {
        hud2 = create_simple_hud( self );
        hud2.foreground = 0;
        hud2.sort = 1;
        hud2.alpha = 1;
        hud2.horzAlign = "user_left"; 
        hud2.vertAlign = "user_center";
        hud2.hidewheninmenu = 1;
        hud2.x = 5.5 + (self.perkarray.size * 30);
        hud2.y = 146.5;
        hud2 SetShader( background_shader, 24, 24 );
        self.background_perk[ perk ] = hud2;
        hud2.color = color;
    }
	
    hud = create_simple_hud( self );
    hud.foreground = 1;
    hud.sort = 1;
    hud.alpha = 1;
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_center";
	hud.hidewheninmenu = 1;
	hud.x = 5.5 + (self.perkarray.size * 30);
    hud.y = 146.5;
    if(custom && perk != "PHD_FLOPPER" && perk != "MULE" && getdvar( "mapname" ) != "zm_prison" )
    {
        hud SetShader( shader, 24, 23 );
    }
    else
    {
        hud SetShader( shader, 24, 24 );
    }
    hud.color = color1;
    self.perkarray[self.perkarray.size] = perk;
    self.perk_hud[ perk ] = hud;
}

hascustomperk(perk)
{
	for(i = 0; i < self.perkarray.size; i++)
	{
		if(self.perkarray[i] == perk)
		{
			return 1;
		}
	}
	return 0;
}

give_random_perk()
{
    perks = array();
    //CUSTOM PERKS
    if(getdvar( "mapname" ) != "zm_tomb" )
    {
        if(!self hascustomperk("PHD_FLOPPER"))
        {
            perks[perks.size] = "PHD_FLOPPER";
        }
    }
    if(getdvar( "mapname" ) == "zm_transit" || getdvar( "mapname" ) == "zm_tomb" || getdvar( "mapname" ) == "zm_prison")
    {
        if(!self hascustomperk("Victorious_Tortoise"))
        {
            perks[perks.size] = "Victorious_Tortoise";
        }
    }
    if(getdvar( "mapname" ) == "zm_transit" || getdvar( "mapname" ) == "zm_nuked" || getdvar( "mapname" ) == "zm_prison")
    {
        if(!self hascustomperk("MULE"))
        {
            perks[perks.size] = "MULE";
        }
    }
    if(getdvar( "mapname" ) == "zm_transit" || getdvar( "mapname" ) == "zm_nuked" || getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_highrise" )
    {
        if(!self hascustomperk("ELECTRIC_CHERRY"))
        {
            perks[perks.size] = "ELECTRIC_CHERRY";
        }
    }
    if( getdvar( "mapname" ) != "zm_prison")
    {
        if(!self hascustomperk("WIDOWS_WINE"))
        {
            perks[perks.size] = "WIDOWS_WINE";
        }
        if(!self hascustomperk("Downers_Delight"))
        {
            perks[perks.size] = "Downers_Delight";
        }
    }
    if(!self hascustomperk("Ethereal_Razor"))
	{
        perks[perks.size] = "Ethereal_Razor";
    }
	if(!self hascustomperk("Ammo_Regen"))
	{
        perks[perks.size] = "Ammo_Regen";
    }
    if(getdvar( "mapname" ) == "zm_transit")
    {
        if(!self hascustomperk("Burn_Heart"))
        {
            perks[perks.size] = "Burn_Heart";
        }
    }
	if(!self hascustomperk("Dying_Wish"))
	{
        perks[perks.size] = "Dying_Wish";
    }
    if(getdvar( "mapname" ) == "zm_transit" || getdvar( "mapname" ) == "zm_nuked" || getdvar( "mapname" ) == "zm_highrise" )
    {
        if(!self hascustomperk("deadshot"))
        {
            perks[perks.size] = "deadshot";
        }
    }
    //ORIGINAL PERKS
    if(!self hasPerk("specialty_armorvest"))
	{
        perks[perks.size] = "specialty_armorvest";
    }
    if(!self hasPerk("specialty_rof"))
	{
        perks[perks.size] = "specialty_rof";
    }
    if(!self hasPerk("specialty_fastreload"))
	{
        perks[perks.size] = "specialty_fastreload";
    }
    if(getdvar( "mapname" ) != "zm_prison" )
    {
        if(!self hasPerk("specialty_quickrevive"))
        {
            perks[perks.size] = "specialty_quickrevive";
        }
    }
    if( getdvar( "mapname" ) == "zm_transit")
    {
        if(!self hasPerk("specialty_longersprint"))
        {
            perks[perks.size] = "specialty_longersprint";
        }
        if(!self hasPerk("specialty_scavenger"))
        {
            perks[perks.size] = "specialty_scavenger";
        }
    }
    if( getdvar( "mapname" ) == "zm_buried")
    {
        if(!self hasperk("specialty_nomotionsensor"))
    	{
			perks[perks.size] = "specialty_nomotionsensor";
		}
		if(!self hasperk("specialty_longersprint"))
		{
			perks[perks.size] = "specialty_longersprint";
		}
    }
    if( getdvar( "mapname" ) == "zm_prison" || getdvar( "mapname" ) == "zm_tomb" )
	{
        if(!self hasPerk("specialty_grenadepulldeath"))
        {
            perks[perks.size] = "specialty_grenadepulldeath";
        }
        if(!self hasPerk("specialty_deadshot"))
        {
            perks[perks.size] = "specialty_deadshot";
        }
    }
    if( getdvar( "mapname" ) == "zm_tomb")
	{
        if(!self hasPerk("specialty_flakjacket"))
        {
            perks[perks.size] = "specialty_flakjacket";
        }
    }
    if(getdvar( "mapname" ) == "zm_tomb" || getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_highrise" )
    {
        if(!self hasPerk("specialty_additionalprimaryweapon"))
        {
            perks[perks.size] = "specialty_additionalprimaryweapon";
        }
    }
    if( getdvar( "mapname" ) == "zm_highrise" )
	{
		if(!self hasperk("specialty_finalstand"))
    	{
			perks[perks.size] = "specialty_finalstand";
		}
	}
    if(!perks.size > 0)
	{
        self playSoundToPlayer( level.zmb_laugh_alias, self );
        return 0;
    }
    n = array_randomize(perks);
    perk = n[0];
    if(perk == "specialty_longersprint" || perk == "specialty_armorvest" || perk == "specialty_rof" || perk == "specialty_fastreload" || perk == "specialty_grenadepulldeath" || perk == "specialty_deadshot" || perk == "specialty_nomotionsensor" || perk == "specialty_finalstand" || perk == "specialty_quickrevive" || perk == "specialty_scavenger" || perk == "specialty_additionalprimaryweapon" || perk == "specialty_flakjacket")
	{
        self custom_give_perk(perk, 0, 0, 0);
    } 
    else 
    {
        self custom_give_perk(perk, 0, 1, 0);
    }
}

//--------------------CUSTOM-PERK---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

damage_callback( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex )
{
    if( isDefined( eAttacker.is_zombie ) && eAttacker.is_zombie && self hascustomperk("WIDOWS_WINE") )
	{
		zombies = getaiarray(level.zombie_team);
        foreach(zombie in zombies)
    	{
	   		if(distance(self.origin, zombie.origin) < 150)
        	{
				grenades = self get_player_lethal_grenade();
            	grenade_count = self getweaponammoclip(grenades);
            	if(grenade_count > 0)
				{
					self PlaySound("zmb_elec_jib_zombie");
                	self setweaponammoclip(grenades, (grenade_count - 1));
					zombie thread ww_points( self );
				}
            }
		}
    }
    if(self hascustomperk("PHD_FLOPPER") || self hasperk("specialty_flakjacket"))
	{
		if( smeansofdeath == "MOD_FALLING" )
		{
			if(isDefined( self.divetoprone ) && self.divetoprone == 1 )
			{
				radiusdamage( self.origin, 300, 5000, 1000, self, "MOD_GRENADE_SPLASH" );
                if( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
                {
                    fx = level._effect[ "divetonuke_groundhit"];
                }
                else
                {
                    fx = loadfx( "explosions/fx_default_explosion" );
                }
                self playsound( "zmb_phdflop_explo" );
                playfx( fx, self.origin );
			}
			return 0;
		}
		if(smeansofdeath == "MOD_GRENADE" || smeansofdeath == "MOD_GRENADE_SPLASH" || eattacker == self && !smeansofdeath == "MOD_UNKNOWN")
		{
			return 0;
		}
	}
    if( isDefined( eAttacker.is_zombie ) && eAttacker.is_zombie && self hascustomperk("Victorious_Tortoise") )
    {
        if(self getcurrentweapon() == "riotshield_zm" || self getcurrentweapon() == "alcatraz_shield_zm" || self getcurrentweapon() == "tomb_shield_zm")
        {
            shield_hp = 1500;
            if ( !isDefined( self.shielddamagetaken ) )
            {
                self.shielddamagetaken = 0;
            }
            self.shielddamagetaken += idamage;
            if ( self.shielddamagetaken >= shield_hp )
            {
                if ( isDefined( self.stub ) )
                {
                    thread maps/mp/zombies/_zm_unitrigger::unregister_unitrigger( self.stub );
                }
                playsoundatposition( "wpn_riotshield_zm_destroy", self.origin );
                self notify("destroy_riotshield");
                if(getdvar( "mapname" ) == "zm_prison")
                {
                    self maps/mp/zombies/_zm_equipment::equipment_take( "alcatraz_shield_zm" );
                }
                if(getdvar( "mapname" ) == "zm_tomb")
                {
                    self maps/mp/zombies/_zm_equipment::equipment_take( "tomb_shield_zm" );
                }
                if(getdvar( "mapname" ) == "zm_transit")
                {
                    self maps/mp/zombies/_zm_equipment::equipment_take( "riotshield_zm" );
                }
                maps/mp/zombies/_zm_equipment::equipment_disappear_fx( self.origin, level._riotshield_dissapear_fx );
                self enableInvulnerability();
                wait 1;
                self disableInvulnerability();
            }
            else
            {
                self deployed_set_shield_health( self.shielddamagetaken, damagemax );
            }
            return 0;
        }
    }
    if(idamage > self.health && !self.dying_wish_on_cooldown && self hascustomperk("Dying_Wish") )
	{
        self notify("dying_wish_charge");
        self thread dying_wish_effect();
        return 0;
	}
	if(isDefined(level.first_player_damage_callback))
	{
       	return [[level.first_player_damage_callback]](einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime);
    }
    return idamage;
}

custom_get_player_weapon_limit( player )
{
    weapon_limit = 2;
    if( player hascustomperk("MULE") || player hasperk("specialty_additionalprimaryweapon"))
    {
        weapon_limit = 3;
    }
	else 
	{
		weapons = self getWeaponsListPrimaries();
		if(weapons.size > weapon_limit)
		{
			self takeWeapon(weapons[2]);
		}
	}
    return weapon_limit;
}

start_er() 
{
    level endon("end_game");
    self endon("disconnect");
    self endon("stopcustomperk");
    for(;;)
    {
        if(self hascustomperk("Ethereal_Razor") && self ismeleeing())
        {
            foreach(zombie in getAiArray(level.zombie_team))
			{
                if( distance( self.origin, zombie.origin ) <= 70 )
				{
					if(self maps/mp/zombies/_zm_powerups::is_insta_kill_active())
					{
						zombie doDamage(zombie.health + 666, (0, 0, 0));
					}
                    else
                    {
                        if(level.round_number < 10 && !self maps/mp/zombies/_zm_powerups::is_insta_kill_active())
                        {
                            zombie doDamage(zombie.health + 666, (0, 0, 0));
                        }
                        else
                        {
                            zombie doDamage(zombie.health / 2, (0, 0, 0));
                        }
                    }
					if(zombie.health <= 0)
					{
                        self maps/mp/zombies/_zm_score::add_to_player_score( 100 );
						self.kills++;
					} 
					else 
					{
                        self maps/mp/zombies/_zm_score::add_to_player_score( 10 );
                    }
                } 
            }
            self.health += 10;
            if(self.health > self.maxhealth)
			{
                self.health = self.maxhealth;
            }
            while(self ismeleeing())
			{
                wait .1;
            }
        }
        wait .05;
    }
}

dying_wish_checker()
{
    level endon("end_game");
    self endon("disconnect");
    self endon( "stopcustomperk" );
    self.dying_wish_uses = 0;
    for(;;)
	{
        self.dying_wish_on_cooldown = 0;
        self.background_perk[ "Dying_Wish" ].alpha = 1;
        self.perk_hud[ "Dying_Wish" ].alpha = 1;
        self waittill("dying_wish_charge");
        self.background_perk[ "Dying_Wish" ].alpha = 0.3;
        self.perk_hud[ "Dying_Wish" ].alpha = 0.4;
        self.dying_wish_uses++;
        self.dying_wish_on_cooldown = 1;
        delay = 300 + (self.dying_wish_uses * 30);
        if(delay >= 600)
        delay = 600;
        wait delay;
    }
}

dying_wish_effect()
{
    self iprintln("Dying Wish saved you!");
    self enableInvulnerability();
    self.ignoreme = 1;
    self useServerVisionSet(1);
    self setvisionsetforplayer( "zombie_death", 0 );
    wait 9;
	self.health = 1;
    self disableInvulnerability();
    self.ignoreme = 0;
    self useServerVisionSet(0);
    self setvisionsetforplayer("remote_mortar_enhanced", 0);
}

ammoregen()
{
	self endon( "disconnect" );
	level endon( "end_game" );
	self endon( "stopcustomperk" );
	for(;;)
	{
		if(self GetCurrentWeapon() == "blundergat_zm" || self GetCurrentWeapon() == "blundergat_upgraded_zm" || self GetCurrentWeapon() ==  "blundersplat_zm" || self GetCurrentWeapon() ==  "blundersplat_upgraded_zm" || self GetCurrentWeapon() == "slipgun_zm" || self GetCurrentWeapon() == "slipgun_upgraded_zm" || self GetCurrentWeapon() == "staff_air_zm" || self GetCurrentWeapon() == "staff_fire_zm"|| self GetCurrentWeapon() == "staff_lightning_zm" || self GetCurrentWeapon() == "staff_water_zm" ) 
		{
			stockcount = self getweaponammostock( self GetCurrentWeapon() );
			self setWeaponAmmostock( self GetCurrentWeapon(), stockcount + 1 );
			wait 6;
		}
		if(!self GetCurrentWeapon() == "claymore_zm" || !self GetCurrentWeapon() == "blundergat_zm" || !self GetCurrentWeapon() == "blundergat_upgraded_zm" || !self GetCurrentWeapon() == "blundersplat_zm" || !self GetCurrentWeapon() == "blundersplat_upgraded_zm" || !self GetCurrentWeapon() == "slipgun_zm" || !self GetCurrentWeapon() == "slipgun_upgraded_zm" || !self GetCurrentWeapon() == "staff_air_zm" || !self GetCurrentWeapon() == "staff_fire_zm"|| !self GetCurrentWeapon() == "staff_lightning_zm" || !self GetCurrentWeapon() == "staff_water_zm" ) 
		{
			stockcount = self getweaponammostock( self GetCurrentWeapon() );
			self setWeaponAmmostock( self GetCurrentWeapon(), stockcount + 1 );
			wait 2;
		}
		wait .1;
	}
}

grenadesregen()
{
	self endon( "disconnect" );
	level endon( "end_game" );
	self endon( "stopcustomperk" );
	for(;;)
	{
		grenades = self get_player_lethal_grenade();
        grenade_count = self getweaponammoclip(grenades);
        if(grenade_count < 4)
		{
        	self setweaponammoclip(grenades, (grenade_count + 1));
		}
		tactical_grenades = self get_player_tactical_grenade();
        tactical_grenade_count = self getweaponammoclip(tactical_grenades);
        if(tactical_grenade_count < 3 )
		{
        	self setweaponammoclip(tactical_grenades, (tactical_grenade_count + 1));
		}
		wait 300;
	}
}

DDown() 
{
	self endon( "disconnect" );
	level endon( "end_game" );
	self endon( "stopcustomperk" );
	for(;;)
	{
		self waittill("player_downed");
		self playsound( "zmb_phdflop_explo" );
		playfx(loadfx("explosions/fx_default_explosion"), self.origin, anglestoforward( ( 0, 45, 55  ) ) ); 
		RadiusDamage(self.origin, 150, 600, 400, self);
		wait .1;
	}
}

LastStand()
{
    if(self hascustomperk("Downers_Delight"))
	{
        self.customlaststandweapon = self getcurrentweapon();
		self switchtoweapon( self.customlaststandweapon );
		self setweaponammoclip( self.customlaststandweapon, 150 );
		self.bleedout_time = 40;
    } 
	else 
	{
        self maps/mp/zombies/_zm::last_stand_pistol_swap();
    }
}

start_ec()
{
	level endon("end_game");
	self endon("disconnect");
	self endon("stopcustomperk");
	for(;;)
	{
		self waittill( "reload_start" );
    	playfxontag( level._effect[ "poltergeist"], self, "J_SpineUpper" );
		self EnableInvulnerability();
		RadiusDamage(self.origin, 150, 200, 100, self);
		self DisableInvulnerability();
		self playsound( "zmb_turbine_explo" );
		wait 1;
	}
}

ww_points( player )
{
    for(i = 0; i < 3; i++)
    {
		self maps/mp/zombies/_zm_utility::set_zombie_run_cycle("walk");
        player maps/mp/zombies/_zm_score::add_to_player_score( 10 );
        PlayFXOnTag(level.effect_WebFX,self,"j_spineupper");
        self doDamage(150, (0, 0, 0));
        if(getdvar( "mapname" ) == "zm_tomb" )
        {
            self set_anim_rate(0.1);
        }
        wait 1;
    }
    if(getdvar( "mapname" ) == "zm_tomb" )
    {
        self set_anim_rate( 1 );
        if(!isalive(self))
        {
            self delete();
        }
    }
}

ww_nade_explosion()
{
    wait 2;
    if(getdvar( "mapname" ) == "zm_transit")
    {
        if( self object_touching_lava())
        {
            self delete();
            return 0;
        }
    }
	foreach(zombie in getAiArray(level.zombie_team))
	{
        if( distance( zombie.origin, self.origin ) < 210 )
		{
            zombie thread ww_points( self );
        }
    }
    self delete();
}

ww_nades()
{
    level endon("end_game");
    self endon("disconnect");
    self endon("stopcustomperk");
    for(;;)
	{
        self waittill( "grenade_fire", grenade, weapname );
        if( weapname == "sticky_grenade_zm" )
		{
            ww_nade = spawnsm( grenade.origin, "zombie_bomb" );
            ww_nade hide();
            ww_nade linkto( grenade );
            ww_nade thread ww_nade_explosion();
        }
    }
}

spawnsm( origin, model, angles )
{
    ent = spawn( "script_model", origin );
    ent setmodel( model );
    if( IsDefined( angles ) )
    {
        ent.angles = angles;
    }
    return ent;
}

object_touching_lava()
{
	if ( !isDefined( level.lava ) )
	{
		level.lava = getentarray( "lava_damage", "targetname" );
	}
	if ( !isDefined( level.lava ) || level.lava.size < 1 )
	{
		return 0;
	}
	if ( isDefined( self.lasttouching ) && self istouching( self.lasttouching ) )
	{
		return 1;
	}
	i = 0;
	while ( i < level.lava.size )
	{
		if ( distancesquared( self.origin, level.lava[ i ].origin ) < 2250000 )
		{
			if ( isDefined( level.lava[ i ].target ) )
			{
				if ( self istouching( level.lava[ i ].volume ) )
				{
					if ( isDefined( level.lava[ i ].script_float ) && level.lava[ i ].script_float <= 0.1 )
					{
						return 0;
					}
					self.lasttouching = level.lava[ i ].volume;
					return 1;
				}
			}
			else
			{
				if ( self istouching( level.lava[ i ] ) )
				{
					self.lasttouching = level.lava[ i ];
					return 1;
				}
			}
		}
		i++;
	}
	self.lasttouching = undefined;
	return 0;
}

deployed_set_shield_health( damage, max_damage )
{
	shieldhealth = int( ( 100 * ( max_damage - damage ) ) / max_damage );
	if ( shieldhealth >= 50 )
	{
		self.shield_damage_level = 0;
	}
	else if ( shieldhealth >= 25 )
	{
		self.shield_damage_level = 2;
	}
	else
	{
		self.shield_damage_level = 3;
	}
	self updatestandaloneriotshieldmodel();
}

updatestandaloneriotshieldmodel()
{
	update = 0;
	if ( !isDefined( self.prev_shield_damage_level ) || self.prev_shield_damage_level != self.shield_damage_level )
	{
		self.prev_shield_damage_level = self.shield_damage_level;
		update = 1;
	}
	if ( update )
	{
		self setmodel( level.deployedshieldmodel[ self.prev_shield_damage_level ] );
	}
}

set_anim_rate( n_speed )
{
	self setclientfield( "anim_rate", n_speed );
	n_rate = self getclientfield( "anim_rate" );
	self setentityanimrate( n_rate );
	if ( n_speed != 1 )
	{
		self.preserve_asd_substates = 1;
	}
	wait_network_frame();
	if ( !is_true( self.is_traversing ) )
	{
		self.needs_run_update = 1;
		self notify( "needs_run_update" );
	}
	wait_network_frame();
	if ( n_speed == 1 )
	{
		self.preserve_asd_substates = 0;
	}
}

custom_chugabud_give_loadout()
{
    self takeallweapons();
    loadout = self.loadout;
    primaries = self getweaponslistprimaries();

    if ( loadout.weapons.size > 1 || primaries.size > 1 )
    {
        foreach ( weapon in primaries )
            self takeweapon( weapon );
    }

    for ( i = 0; i < loadout.weapons.size; i++ )
    {
        if ( !isdefined( loadout.weapons[i] ) )
            continue;

        if ( loadout.weapons[i]["name"] == "none" )
            continue;

        self maps\mp\zombies\_zm_weapons::weapondata_give( loadout.weapons[i] );
    }

    if ( loadout.current_weapon >= 0 && isdefined( loadout.weapons[loadout.current_weapon]["name"] ) )
        self switchtoweapon( loadout.weapons[loadout.current_weapon]["name"] );

    self giveweapon( "knife_zm" );
    self maps\mp\zombies\_zm_equipment::equipment_give( self.loadout.equipment );
    loadout restore_weapons_for_chugabud( self );
    self chugabud_restore_claymore();
    self.score = loadout.score;
    self.pers["score"] = loadout.score;
    perk_array = maps\mp\zombies\_zm_perks::get_perk_array( 1 );

    for ( i = 0; i < perk_array.size; i++ )
    {
        perk = perk_array[i];
        self unsetperk( perk );
        self.num_perks--;
        self set_perk_clientfield( perk, 0 );
    }

    if ( isdefined( self.saved_perks ) && self.saved_perks.size > 0 )
    {
        for(i = 0; i < self.saved_perks.size; i++)
		{
			if( self.saved_perks[ i ] == "specialty_longersprint" || self.saved_perks[ i ] == "specialty_armorvest" || self.saved_perks[ i ] == "specialty_rof" || self.saved_perks[ i ] == "specialty_fastreload" || self.saved_perks[ i ] == "specialty_grenadepulldeath" || self.saved_perks[ i ] == "specialty_deadshot" || self.saved_perks[ i ] == "specialty_nomotionsensor" || self.saved_perks[ i ] == "specialty_quickrevive" || self.saved_perks[ i ] == "specialty_scavenger" || self.saved_perks[ i ] == "specialty_additionalprimaryweapon" || self.saved_perks[ i ] == "specialty_flakjacket")
			{
				self custom_give_perk(self.saved_perks[ i ], 0, 0, 0);
			} 
			else 
			{
				self custom_give_perk(self.saved_perks[ i ], 0, 1, 1);
			}
		}
    }

    self chugabud_restore_grenades();

    if ( maps\mp\zombies\_zm_weap_cymbal_monkey::cymbal_monkey_exists() )
    {
        if ( loadout.zombie_cymbal_monkey_count )
        {
            self maps\mp\zombies\_zm_weap_cymbal_monkey::player_give_cymbal_monkey();
            self setweaponammoclip( "cymbal_monkey_zm", loadout.zombie_cymbal_monkey_count );
        }
    }
}

custom_chugabud_save_loadout()
{
	primaries = self getweaponslistprimaries();
	currentweapon = self getcurrentweapon();
	self.loadout = spawnstruct();
	self.loadout.player = self;
	self.loadout.weapons = [];
	self.loadout.score = self.score;
	self.loadout.current_weapon = -1;
	_a376 = primaries;
	index = getFirstArrayKey( _a376 );
	while ( isDefined( index ) )
	{
		weapon = _a376[ index ];
		self.loadout.weapons[ index ] = maps/mp/zombies/_zm_weapons::get_player_weapondata( self, weapon );
		if ( weapon == currentweapon || self.loadout.weapons[ index ][ "alt_name" ] == currentweapon )
		{
			self.loadout.current_weapon = index;
		}
		index = getNextArrayKey( _a376, index );
	}
	self.loadout.equipment = self get_player_equipment();
	if ( isDefined( self.loadout.equipment ) )
	{
		self maps/mp/zombies/_zm_equipment::equipment_take( self.loadout.equipment );
	}
	self.loadout save_weapons_for_chugabud( self );
	if ( self hasweapon( "claymore_zm" ) )
	{
		self.loadout.hasclaymore = 1;
		self.loadout.claymoreclip = self getweaponammoclip( "claymore_zm" );
	}
	self.loadout.perks = self custom_save_perks();
	self chugabud_save_grenades();
	if ( maps/mp/zombies/_zm_weap_cymbal_monkey::cymbal_monkey_exists() )
	{
		self.loadout.zombie_cymbal_monkey_count = self getweaponammoclip( "cymbal_monkey_zm" );
	}
}

custom_afterlife_give_loadout()
{
	self takeallweapons();
	loadout = self.loadout;
	primaries = self getweaponslistprimaries();
	while ( loadout.weapons.size > 1 || primaries.size > 1 )
	{
		_a1601 = primaries;
		_k1601 = getFirstArrayKey( _a1601 );
		while ( isDefined( _k1601 ) )
		{
			weapon = _a1601[ _k1601 ];
			self takeweapon( weapon );
			_k1601 = getNextArrayKey( _a1601, _k1601 );
		}
	}
	i = 0;
	while ( i < loadout.weapons.size )
	{
		if ( !isDefined( loadout.weapons[ i ] ) )
		{
			i++;
			continue;
		}
		else if ( loadout.weapons[ i ] == "none" )
		{
			i++;
			continue;
		}
		else
		{
			weapon = loadout.weapons[ i ];
			stock_amount = loadout.stockcount[ i ];
			clip_amount = loadout.clipcount[ i ];
			if ( !self hasweapon( weapon ) )
			{
				self giveweapon( weapon, 0, self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( weapon ) );
				self setweaponammostock( weapon, stock_amount );
				self setweaponammoclip( weapon, clip_amount );
				if ( weaponisdualwield( weapon ) )
				{
					weapon_dw = weapondualwieldweaponname( weapon );
					self setweaponammoclip( weapon_dw, loadout.clipcount2[ i ] );
				}
				weapon_alt = weaponaltweaponname( weapon );
				if ( weapon_alt != "none" )
				{
					self setweaponammostock( weapon_alt, loadout.stockcountalt[ i ] );
					self setweaponammoclip( weapon_alt, loadout.clipcountalt[ i ] );
				}
			}
		}
		i++;
	}
	self setspawnweapon( loadout.weapons[ loadout.current_weapon ] );
	self switchtoweaponimmediate( loadout.weapons[ loadout.current_weapon ] );
	if ( isDefined( self get_player_melee_weapon() ) )
	{
		self giveweapon( self get_player_melee_weapon() );
	}
	self maps/mp/zombies/_zm_equipment::equipment_give( self.loadout.equipment );
	if ( isDefined( loadout.hasclaymore ) && loadout.hasclaymore && !self hasweapon( "claymore_zm" ) )
	{
		self giveweapon( "claymore_zm" );
		self set_player_placeable_mine( "claymore_zm" );
		self setactionslot( 4, "weapon", "claymore_zm" );
		self setweaponammoclip( "claymore_zm", loadout.claymoreclip );
	}
	if ( isDefined( loadout.hasemp ) && loadout.hasemp )
	{
		self giveweapon( "emp_grenade_zm" );
		self setweaponammoclip( "emp_grenade_zm", loadout.empclip );
	}
	if ( isDefined( loadout.hastomahawk ) && loadout.hastomahawk )
	{
		self giveweapon( self.current_tomahawk_weapon );
		self set_player_tactical_grenade( self.current_tomahawk_weapon );
		self setclientfieldtoplayer( "tomahawk_in_use", 1 );
	}
	self.score = loadout.score;
	perk_array = maps/mp/zombies/_zm_perks::get_perk_array( 1 );
	i = 0;
	while ( i < perk_array.size )
	{
		perk = perk_array[ i ];
		self unsetperk( perk );
		self.num_perks--;

		self set_perk_clientfield( perk, 0 );
		i++;
	}
    if(isDefined( self.keep_perks ) && self.keep_perks )
    {
        for(i = 0; i < self.saved_perks.size; i++)
        {
            if(self.saved_perks[ i ] == "specialty_finalstand")
            {
            }
            if( self.saved_perks[ i ] == "specialty_longersprint" || self.saved_perks[ i ] == "specialty_armorvest" || self.saved_perks[ i ] == "specialty_rof" || self.saved_perks[ i ] == "specialty_fastreload" || self.saved_perks[ i ] == "specialty_grenadepulldeath" || self.saved_perks[ i ] == "specialty_deadshot" || self.saved_perks[ i ] == "specialty_nomotionsensor" || self.saved_perks[ i ] == "specialty_quickrevive" || self.saved_perks[ i ] == "specialty_scavenger" || self.saved_perks[ i ] == "specialty_additionalprimaryweapon" || self.saved_perks[ i ] == "specialty_flakjacket")
            {
                custom_give_perk(self.saved_perks[ i ], 0, 0, 0);
            } 
            else 
            {
                custom_give_perk(self.saved_perks[ i ], 0, 1, 0); //cannot set "saved_perk" to 1, player wont get any perks back when returning from afterlife
            }
        }
    }
    self.fakedowns = self.downs;
    self.keep_perks = undefined;
	self set_player_lethal_grenade( self.loadout.lethal_grenade );
	if ( loadout.grenade > 0 )
	{
		curgrenadecount = 0;
		if ( self hasweapon( self get_player_lethal_grenade()))
		{
			self getweaponammoclip( self get_player_lethal_grenade() );
		}
		else
		{
			self giveweapon( self get_player_lethal_grenade() );
		}
		self setweaponammoclip( self get_player_lethal_grenade(), loadout.grenade + curgrenadecount );
	}
}

custom_tombstone_give()
{
	dc = level.tombstones[ self.tombstone_index ];
	if ( !flag( "solo_game" ) )
	{
		primaries = self getweaponslistprimaries();
		if ( dc.weapon.size > 1 || primaries.size > 1 )
		{
			foreach ( weapon in primaries )
			{
				self takeweapon( weapon );
			}
		}
		i = 0;
		while ( i < dc.weapon.size )
		{
			if ( !isDefined( dc.weapon[ i ] ) )
			{
				i++;
				continue;
			}
			if ( dc.weapon[ i ] == "none" )
			{
				i++;
				continue;
			}
			weapon = dc.weapon[ i ];
			stock = dc.stockcount[ i ];
			if ( !self hasweapon( weapon ) )
			{
				self giveweapon( weapon, 0, self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( weapon ) );
				self setweaponammoclip( weapon, weaponclipsize( weapon ) );
				self setweaponammostock( weapon, stock );
				if ( i == dc.current_weapon )
				{
					self switchtoweapon( weapon );
				}
			}
			i++;
		}
	}
	if ( isDefined( dc.hasriotshield ) && dc.hasriotshield )
	{
		self maps/mp/zombies/_zm_equipment::equipment_give( "riotshield_zm" );
		if ( isDefined( self.player_shield_reset_health ) )
		{
			self [[ self.player_shield_reset_health ]]();
		}
	}
	dc restore_weapons_for_tombstone( self );
	if ( isDefined( dc.hasclaymore ) && dc.hasclaymore && !self hasweapon( "claymore_zm" ) )
	{
		self giveweapon( "claymore_zm" );
		self set_player_placeable_mine( "claymore_zm" );
		self setactionslot( 4, "weapon", "claymore_zm" );
		self setweaponammoclip( "claymore_zm", dc.claymoreclip );
	}
	if ( isDefined( dc.hasemp ) && dc.hasemp )
	{
		self giveweapon( "emp_grenade_zm" );
		self setweaponammoclip( "emp_grenade_zm", dc.empclip );
	}
    if(isdefined(self.saved_perks) && self.saved_perks.size > 0)
    {
        for(i = 0; i < self.saved_perks.size; i++)
        {
            if( self.saved_perks[ i ] == "specialty_longersprint" || self.saved_perks[ i ] == "specialty_armorvest" || self.saved_perks[ i ] == "specialty_rof" || self.saved_perks[ i ] == "specialty_fastreload" || self.saved_perks[ i ] == "specialty_grenadepulldeath" || self.saved_perks[ i ] == "specialty_deadshot" || self.saved_perks[ i ] == "specialty_nomotionsensor" || self.saved_perks[ i ] == "specialty_quickrevive" || self.saved_perks[ i ] == "specialty_scavenger" || self.saved_perks[ i ] == "specialty_additionalprimaryweapon" || self.saved_perks[ i ] == "specialty_flakjacket")
            {
                self custom_give_perk(self.saved_perks[ i ], 0, 0, 0);
            } 
            else 
            {
                self custom_give_perk(self.saved_perks[ i ], 0, 1, 1);
            }
        }
    }
	if ( dc.grenade > 0 && !flag( "solo_game" ) )
	{
		curgrenadecount = 0;
		if ( self hasweapon( self get_player_lethal_grenade() ) )
		{
			self getweaponammoclip( self get_player_lethal_grenade() );
		}
		else
		{
			self giveweapon( self get_player_lethal_grenade() );
		}
		self setweaponammoclip( self get_player_lethal_grenade(), dc.grenade + curgrenadecount );
	}
	if ( maps/mp/zombies/_zm_weap_cymbal_monkey::cymbal_monkey_exists() && !flag( "solo_game" ) )
	{
		if ( dc.zombie_cymbal_monkey_count )
		{
			self maps/mp/zombies/_zm_weap_cymbal_monkey::player_give_cymbal_monkey();
			self setweaponammoclip( "cymbal_monkey_zm", dc.zombie_cymbal_monkey_count );
		}
	}
}

custom_afterlife_save_loadout()
{
	primaries = self getweaponslistprimaries();
	currentweapon = self getcurrentweapon();
	self.loadout = spawnstruct();
	self.loadout.player = self;
	self.loadout.weapons = [];
	self.loadout.score = self.score;
	self.loadout.current_weapon = 0;
	_a1516 = primaries;
	index = getFirstArrayKey( _a1516 );
	while ( isDefined( index ) )
	{
		weapon = _a1516[ index ];
		self.loadout.weapons[ index ] = weapon;
		self.loadout.stockcount[ index ] = self getweaponammostock( weapon );
		self.loadout.clipcount[ index ] = self getweaponammoclip( weapon );
		if ( weaponisdualwield( weapon ) )
		{
			weapon_dw = weapondualwieldweaponname( weapon );
			self.loadout.clipcount2[ index ] = self getweaponammoclip( weapon_dw );
		}
		weapon_alt = weaponaltweaponname( weapon );
		if ( weapon_alt != "none" )
		{
			self.loadout.stockcountalt[ index ] = self getweaponammostock( weapon_alt );
			self.loadout.clipcountalt[ index ] = self getweaponammoclip( weapon_alt );
		}
		if ( weapon == currentweapon )
		{
			self.loadout.current_weapon = index;
		}
		index = getNextArrayKey( _a1516, index );
	}
	self.loadout.equipment = self get_player_equipment();
	if ( isDefined( self.loadout.equipment ) )
	{
		self maps/mp/zombies/_zm_equipment::equipment_take( self.loadout.equipment );
	}
	if ( self hasweapon( "claymore_zm" ) )
	{
		self.loadout.hasclaymore = 1;
		self.loadout.claymoreclip = self getweaponammoclip( "claymore_zm" );
	}
	if ( self hasweapon( "emp_grenade_zm" ) )
	{
		self.loadout.hasemp = 1;
		self.loadout.empclip = self getweaponammoclip( "emp_grenade_zm" );
	}
	if ( self hasweapon( "bouncing_tomahawk_zm" ) || self hasweapon( "upgraded_tomahawk_zm" ) )
	{
		self.loadout.hastomahawk = 1;
		self setclientfieldtoplayer( "tomahawk_in_use", 0 );
	}
	self.loadout.perks = self custom_save_perks();
	lethal_grenade = self get_player_lethal_grenade();
	if ( self hasweapon( lethal_grenade ) )
	{
		self.loadout.grenade = self getweaponammoclip( lethal_grenade );
	}
	else
	{
		self.loadout.grenade = 0;
	}
	self.loadout.lethal_grenade = lethal_grenade;
	self set_player_lethal_grenade( undefined );
}

custom_tombstone_laststand()
{
	primaries = self getweaponslistprimaries();
	currentweapon = self getcurrentweapon();
	dc = level.tombstones[ self.tombstone_index ];
	dc.player = self;
	dc.weapon = [];
	dc.current_weapon = -1;
	_a134 = primaries;
	index = getFirstArrayKey( _a134 );
	while ( isDefined( index ) )
	{
		weapon = _a134[ index ];
		dc.weapon[ index ] = weapon;
		dc.stockcount[ index ] = self getweaponammostock( weapon );
		if ( weapon == currentweapon )
		{
			dc.current_weapon = index;
		}
		index = getNextArrayKey( _a134, index );
	}
	if ( isDefined( self.hasriotshield ) && self.hasriotshield )
	{
		dc.hasriotshield = 1;
	}
	dc save_weapons_for_tombstone( self );
	if ( self hasweapon( "claymore_zm" ) )
	{
		dc.hasclaymore = 1;
		dc.claymoreclip = self getweaponammoclip( "claymore_zm" );
	}
	if ( self hasweapon( "emp_grenade_zm" ) )
	{
		dc.hasemp = 1;
		dc.empclip = self getweaponammoclip( "emp_grenade_zm" );
	}
	dc.perk = self custom_save_perks();
	lethal_grenade = self get_player_lethal_grenade();
	if ( self hasweapon( lethal_grenade ) )
	{
		dc.grenade = self getweaponammoclip( lethal_grenade );
	}
	else
	{
		dc.grenade = 0;
	}
	if ( maps/mp/zombies/_zm_weap_cymbal_monkey::cymbal_monkey_exists() )
	{
		dc.zombie_cymbal_monkey_count = self getweaponammoclip( "cymbal_monkey_zm" );
	}
}

afterlife_save_loadout()
{
	primaries = self getweaponslistprimaries();
	currentweapon = self getcurrentweapon();
	self.loadout = spawnstruct();
	self.loadout.player = self;
	self.loadout.weapons = [];
	self.loadout.score = self.score;
	self.loadout.current_weapon = 0;
	_a1516 = primaries;
	index = getFirstArrayKey( _a1516 );
	while ( isDefined( index ) )
	{
		weapon = _a1516[ index ];
		self.loadout.weapons[ index ] = weapon;
		self.loadout.stockcount[ index ] = self getweaponammostock( weapon );
		self.loadout.clipcount[ index ] = self getweaponammoclip( weapon );
		if ( weaponisdualwield( weapon ) )
		{
			weapon_dw = weapondualwieldweaponname( weapon );
			self.loadout.clipcount2[ index ] = self getweaponammoclip( weapon_dw );
		}
		weapon_alt = weaponaltweaponname( weapon );
		if ( weapon_alt != "none" )
		{
			self.loadout.stockcountalt[ index ] = self getweaponammostock( weapon_alt );
			self.loadout.clipcountalt[ index ] = self getweaponammoclip( weapon_alt );
		}
		if ( weapon == currentweapon )
		{
			self.loadout.current_weapon = index;
		}
		index = getNextArrayKey( _a1516, index );
	}
	self.loadout.equipment = self get_player_equipment();
	if ( isDefined( self.loadout.equipment ) )
	{
		self maps/mp/zombies/_zm_equipment::equipment_take( self.loadout.equipment );
	}
	if ( self hasweapon( "claymore_zm" ) )
	{
		self.loadout.hasclaymore = 1;
		self.loadout.claymoreclip = self getweaponammoclip( "claymore_zm" );
	}
	if ( self hasweapon( "emp_grenade_zm" ) )
	{
		self.loadout.hasemp = 1;
		self.loadout.empclip = self getweaponammoclip( "emp_grenade_zm" );
	}
	if ( self hasweapon( "bouncing_tomahawk_zm" ) || self hasweapon( "upgraded_tomahawk_zm" ) )
	{
		self.loadout.hastomahawk = 1;
		self setclientfieldtoplayer( "tomahawk_in_use", 0 );
	}
	self.loadout.perks = afterlife_save_perks( self );
	lethal_grenade = self get_player_lethal_grenade();
	if ( self hasweapon( lethal_grenade ) )
	{
		self.loadout.grenade = self getweaponammoclip( lethal_grenade );
	}
	else
	{
		self.loadout.grenade = 0;
	}
	self.loadout.lethal_grenade = lethal_grenade;
	self set_player_lethal_grenade( undefined );
}

afterlife_give_loadout()
{
	self takeallweapons();
	loadout = self.loadout;
	primaries = self getweaponslistprimaries();
	while ( loadout.weapons.size > 1 || primaries.size > 1 )
	{
		_a1601 = primaries;
		_k1601 = getFirstArrayKey( _a1601 );
		while ( isDefined( _k1601 ) )
		{
			weapon = _a1601[ _k1601 ];
			self takeweapon( weapon );
			_k1601 = getNextArrayKey( _a1601, _k1601 );
		}
	}
	i = 0;
	while ( i < loadout.weapons.size )
	{
		if ( !isDefined( loadout.weapons[ i ] ) )
		{
			i++;
			continue;
		}
		else if ( loadout.weapons[ i ] == "none" )
		{
			i++;
			continue;
		}
		else
		{
			weapon = loadout.weapons[ i ];
			stock_amount = loadout.stockcount[ i ];
			clip_amount = loadout.clipcount[ i ];
			if ( !self hasweapon( weapon ) )
			{
				self giveweapon( weapon, 0, self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( weapon ) );
				self setweaponammostock( weapon, stock_amount );
				self setweaponammoclip( weapon, clip_amount );
				if ( weaponisdualwield( weapon ) )
				{
					weapon_dw = weapondualwieldweaponname( weapon );
					self setweaponammoclip( weapon_dw, loadout.clipcount2[ i ] );
				}
				weapon_alt = weaponaltweaponname( weapon );
				if ( weapon_alt != "none" )
				{
					self setweaponammostock( weapon_alt, loadout.stockcountalt[ i ] );
					self setweaponammoclip( weapon_alt, loadout.clipcountalt[ i ] );
				}
			}
		}
		i++;
	}
	self setspawnweapon( loadout.weapons[ loadout.current_weapon ] );
	self switchtoweaponimmediate( loadout.weapons[ loadout.current_weapon ] );
	if ( isDefined( self get_player_melee_weapon() ) )
	{
		self giveweapon( self get_player_melee_weapon() );
	}
	self maps/mp/zombies/_zm_equipment::equipment_give( self.loadout.equipment );
	if ( isDefined( loadout.hasclaymore ) && loadout.hasclaymore && !self hasweapon( "claymore_zm" ) )
	{
		self giveweapon( "claymore_zm" );
		self set_player_placeable_mine( "claymore_zm" );
		self setactionslot( 4, "weapon", "claymore_zm" );
		self setweaponammoclip( "claymore_zm", loadout.claymoreclip );
	}
	if ( isDefined( loadout.hasemp ) && loadout.hasemp )
	{
		self giveweapon( "emp_grenade_zm" );
		self setweaponammoclip( "emp_grenade_zm", loadout.empclip );
	}
	if ( isDefined( loadout.hastomahawk ) && loadout.hastomahawk )
	{
		self giveweapon( self.current_tomahawk_weapon );
		self set_player_tactical_grenade( self.current_tomahawk_weapon );
		self setclientfieldtoplayer( "tomahawk_in_use", 1 );
	}
	self.score = loadout.score;
	perk_array = maps/mp/zombies/_zm_perks::get_perk_array( 1 );
	i = 0;
	while ( i < perk_array.size )
	{
		perk = perk_array[ i ];
		self unsetperk( perk );
		self set_perk_clientfield( perk, 0 );
		i++;
	}
	while ( isDefined( self.keep_perks ) && self.keep_perks && isDefined( loadout.perks ) && loadout.perks.size > 0 )
	{
		i = 0;
		while ( i < loadout.perks.size )
		{
			if ( self hasperk( loadout.perks[ i ] ) )
			{
				i++;
				continue;
			}
			else if ( loadout.perks[ i ] == "specialty_quickrevive" && flag( "solo_game" ) )
			{
				level.solo_game_free_player_quickrevive = 1;
			}
			if ( loadout.perks[ i ] == "specialty_finalstand" )
			{
				i++;
				continue;
			}
			else
			{
				maps/mp/zombies/_zm_perks::give_perk( loadout.perks[ i ] );
			}
			i++;
		}
	}
	self.keep_perks = undefined;
	self set_player_lethal_grenade( self.loadout.lethal_grenade );
	if ( loadout.grenade > 0 )
	{
		curgrenadecount = 0;
		if ( self hasweapon( self get_player_lethal_grenade() ) )
		{
			self getweaponammoclip( self get_player_lethal_grenade() );
		}
		else
		{
			self giveweapon( self get_player_lethal_grenade() );
		}
		self setweaponammoclip( self get_player_lethal_grenade(), loadout.grenade + curgrenadecount );
	}
}

afterlife_save_perks( ent )
{
	perk_array = ent get_perk_array( 1 );
	_a1989 = perk_array;
	_k1989 = getFirstArrayKey( _a1989 );
	while ( isDefined( _k1989 ) )
	{
		perk = _a1989[ _k1989 ];
		ent unsetperk( perk );
		_k1989 = getNextArrayKey( _a1989, _k1989 );
	}
	return perk_array;
}

tombstone_spawn()
{
	dc = spawn( "script_model", self.origin + vectorScale( ( 0, 0, 1 ), 40 ) );
	dc.angles = self.angles;
	dc setmodel( "tag_origin" );
	dc_icon = spawn( "script_model", self.origin + vectorScale( ( 0, 0, 1 ), 40 ) );
	dc_icon.angles = self.angles;
	dc_icon setmodel( "ch_tombstone1" );
	dc_icon linkto( dc );
	dc.icon = dc_icon;
	dc.script_noteworthy = "player_tombstone_model";
	dc.player = self;
	self thread tombstone_clear();
	dc thread tombstone_wobble();
	dc thread tombstone_revived( self );
	result = self waittill_any_return( "player_revived", "spawned_player", "disconnect" );
	if ( result == "player_revived" || result == "disconnect" )
	{
		dc notify( "tombstone_timedout" );
		dc_icon unlink();
		dc_icon delete();
		dc delete();
		return;
	}
	dc thread tombstone_timeout();
	dc thread tombstone_grab();
}

tombstone_grab()
{
	self endon( "tombstone_timedout" );
	wait 1;
	while ( isDefined( self ) )
	{
		players = get_players();
		i = 0;
		while ( i < players.size )
		{
			if ( players[ i ].is_zombie )
			{
				i++;
				continue;
			}
			else
			{
				if ( isDefined( self.player ) && players[ i ] == self.player )
				{
					tombstone_machine_triggers = getentarray( "specialty_scavenger", "script_noteworthy" );
					istombstonepowered = 0;

					foreach ( trigger in tombstone_machine_triggers )
					{
						if ( isdefined( trigger.power_on ) && trigger.power_on || isdefined( trigger.turbine_power_on ) && trigger.turbine_power_on )
							istombstonepowered = 1;
					}

                    istombstonepowered = 1; //manually set to 1
					if ( istombstonepowered )
					{
						dist = distance( players[ i ].origin, self.origin );
						if ( dist < 64 )
						{
							playfx( level._effect[ "powerup_grabbed" ], self.origin );
							playfx( level._effect[ "powerup_grabbed_wave" ], self.origin );
							players[ i ] custom_tombstone_give();
							wait 0.1;
							playsoundatposition( "zmb_tombstone_grab", self.origin );
							self stoploopsound();
							self.icon unlink();
							self.icon delete();
							self delete();
							self notify( "tombstone_grabbed" );
							players[ i ] clientnotify( "dc0" );
							players[ i ] notify( "dance_on_my_grave" );
						}
					}
				}
			}
            wait .1;
			i++;
		}
		wait_network_frame();
	}
}

solo_tombstone_removal()
{
	notify( "tombstone_on" );
}

turn_tombstone_on()
{
	level endon("end_game");
	while ( 1 )
	{
		machine = getentarray( "vending_tombstone", "targetname" );
		machine_triggers = getentarray( "vending_tombstone", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "tombstone" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "tombstone" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "tombstone_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "tombstone" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0,3, 0,4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "tombstone_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_scavenger_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "tombstone" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "tombstone" ].power_on_callback );
		}
		level waittill( "tombstone_off" );
		if ( isDefined( level.machine_assets[ "tombstone" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "tombstone" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
		players = get_players();
		_a1718 = players;
		_k1718 = getFirstArrayKey( _a1718 );
		while ( isDefined( _k1718 ) )
		{
			player = _a1718[ _k1718 ];
			player.hasperkspecialtytombstone = undefined;
			_k1718 = getNextArrayKey( _a1718, _k1718 );
		}
	}
}

perk_machine_spawn_init()
{
	level endon("end_game");
	match_string = "";
	location = level.scr_zm_map_start_location;
	if ( location != "default" && location == "" && isDefined( level.default_start_location ) )
	{
		location = level.default_start_location;
	}
	match_string = ( level.scr_zm_ui_gametype + "_perks_" ) + location;
	pos = [];
	if ( isDefined( level.override_perk_targetname ) )
	{
		structs = getstructarray( level.override_perk_targetname, "targetname" );
	}
	else
	{
		structs = getstructarray( "zm_perk_machine", "targetname" );
	}
	_a3578 = structs;
	_k3578 = getFirstArrayKey( _a3578 );
	while ( isDefined( _k3578 ) )
	{
		struct = _a3578[ _k3578 ];
		if ( isDefined( struct.script_string ) )
		{
			tokens = strtok( struct.script_string, " " );
			_a3583 = tokens;
			_k3583 = getFirstArrayKey( _a3583 );
			while ( isDefined( _k3583 ) )
			{
				token = _a3583[ _k3583 ];
				if ( token == match_string )
				{
					pos[ pos.size ] = struct;
				}
				_k3583 = getNextArrayKey( _a3583, _k3583 );
			}
		}
		else pos[ pos.size ] = struct;
		_k3578 = getNextArrayKey( _a3578, _k3578 );
	}
	if ( !isDefined( pos ) || pos.size == 0 )
	{
		return;
	}
	precachemodel( "zm_collision_perks1" );
	i = 0;
	while ( i < pos.size )
	{
		perk = pos[ i ].script_noteworthy;
		if ( isDefined( perk ) && isDefined( pos[ i ].model ) )
		{
			use_trigger = spawn( "trigger_radius_use", pos[ i ].origin + vectorScale( ( 0, -1, 0 ), 30 ), 0, 40, 70 );
			use_trigger.targetname = "zombie_vending";
			use_trigger.script_noteworthy = perk;
			use_trigger triggerignoreteam();
			perk_machine = spawn( "script_model", pos[ i ].origin );
			perk_machine.angles = pos[ i ].angles;
			perk_machine setmodel( pos[ i ].model );
			if ( isDefined( level._no_vending_machine_bump_trigs ) && level._no_vending_machine_bump_trigs )
			{
				bump_trigger = undefined;
			}
			else
			{
				bump_trigger = spawn( "trigger_radius", pos[ i ].origin, 0, 35, 64 );
				bump_trigger.script_activated = 1;
				bump_trigger.script_sound = "zmb_perks_bump_bottle";
				bump_trigger.targetname = "audio_bump_trigger";
				if ( perk != "specialty_weapupgrade" )
				{
					bump_trigger thread thread_bump_trigger();
				}
			}
			collision = spawn( "script_model", pos[ i ].origin, 1 );
			collision.angles = pos[ i ].angles;
			collision setmodel( "zm_collision_perks1" );
			collision.script_noteworthy = "clip";
			collision disconnectpaths();
			use_trigger.clip = collision;
			use_trigger.machine = perk_machine;
			use_trigger.bump = bump_trigger;
			if ( isDefined( pos[ i ].blocker_model ) )
			{
				use_trigger.blocker_model = pos[ i ].blocker_model;
			}
			if ( isDefined( pos[ i ].script_int ) )
			{
				perk_machine.script_int = pos[ i ].script_int;
			}
			if ( isDefined( pos[ i ].turn_on_notify ) )
			{
				perk_machine.turn_on_notify = pos[ i ].turn_on_notify;
			}
			if ( perk == "specialty_scavenger" || perk == "specialty_scavenger_upgrade" )
			{
				use_trigger.script_sound = "mus_perks_tombstone_jingle";
				use_trigger.script_string = "tombstone_perk";
				use_trigger.script_label = "mus_perks_tombstone_sting";
				use_trigger.target = "vending_tombstone";
				perk_machine.script_string = "tombstone_perk";
				perk_machine.targetname = "vending_tombstone";
				if ( isDefined( bump_trigger ) )
				{
					bump_trigger.script_string = "tombstone_perk";
				}
			}
			if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].perk_machine_set_kvps ) )
			{
				[[ level._custom_perks[ perk ].perk_machine_set_kvps ]]( use_trigger, perk_machine, bump_trigger, collision );
			}
		}
		i++;
	}
}

isTown()
{
	if (isDefined(level.zombiemode_using_tombstone_perk) && level.zombiemode_using_tombstone_perk)
	{
		level thread perk_machine_spawn_init();
		thread solo_tombstone_removal();
		thread turn_tombstone_on();
	}
}

AimAssist()
{
	self endon("disconnect");
	level endon("end_game");
    self endon("stopcustomperk");
	for(;;)
	{
		view_pos = self GetWeaponMuzzlePoint();
		zombies = get_array_of_closest( view_pos, getaiarray( level.zombie_team ), undefined, undefined, undefined );
		range_squared = 300 * 300;
		for ( i = 0; i < zombies.size; i++ )
		{
			if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
			{
				continue;
			}
			enemy_origin = zombies[i].origin;
			test_range_squared = DistanceSquared( view_pos, enemy_origin );
			if ( test_range_squared < range_squared )
			{
				if(zombies[i] player_can_see_me(self))
				{
					if(self adsButtonPressed() && !self IsReloading() && !isads( self ))
					{
						self setPlayerAngles(vectorToAngles((zombies[i] getTagOrigin("j_head")) - (self getEye())));
						while(self adsButtonPressed())
						{
							wait .05;	
						}
						break;
					}
				}
			}
		}
		wait .05;
	}
}

player_can_see_me( player )
{
    playerangles = player getplayerangles();
    playerforwardvec = anglesToForward( playerangles );
    playerunitforwardvec = vectornormalize( playerforwardvec );
    banzaipos = self.origin;
    playerpos = player getorigin();
    playertobanzaivec = banzaipos - playerpos;
    playertobanzaiunitvec = vectornormalize( playertobanzaivec );
    forwarddotbanzai = vectordot( playerunitforwardvec, playertobanzaiunitvec );
    if ( forwarddotbanzai >= 1 )
    {
        anglefromcenter = 0;
    }
    else if ( forwarddotbanzai <= -1 )
    {
        anglefromcenter = 180;
    }
    else
    {
        anglefromcenter = acos( forwarddotbanzai );
    }
    playerfov = getDvarFloat( "cg_fov" );
    banzaivsplayerfovbuffer = getDvarFloat( "g_banzai_player_fov_buffer" );
    if ( banzaivsplayerfovbuffer <= 0 )
    {
        banzaivsplayerfovbuffer = 0.2;
    }
    playercanseeme = anglefromcenter <= ( ( playerfov * 0.5 ) * ( 1 - banzaivsplayerfovbuffer ) );
    return playercanseeme;
}
