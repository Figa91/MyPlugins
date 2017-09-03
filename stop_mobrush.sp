#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:stop_mobsrush_enable;
new Handle:stop_mobs;
new Handle:stop_specials;
new Handle:stop_panic_event;

new Handle:stop_ais_enabled;
new bool:tank_spawn_count[MAXPLAYERS + 1];

new flag_stop;
new flag_start;
new flag_mob;
new flag_specials;
new TankSpawnCount;

public Plugin:myinfo =
{
    name = "[L4D] Stop Mobs Rush",
    author = "Figa",
    description = "Stops the rush of zombies and SI when a spawn tank.",
    version = "1.1",
    url = "http://fiksiki.3dn.ru"
}

public OnPluginStart()
{
	AutoExecConfig(true, "l4d_stop_mobs");
	
	HookEvent("tank_spawn", tank_spawn, EventHookMode_Post);
	HookEvent("tank_killed", tank_killed, EventHookMode_Post);
	HookEvent("round_start", round_start, EventHookMode_Post);
	HookEvent("round_end", round_end);
	HookEvent("create_panic_event", PanicEvent, EventHookMode_Post);
	
	stop_mobsrush_enable = CreateConVar("stop_mobsrush_enable", "1", "  0:disable plugin, 1:enable plugin");
	stop_mobs = CreateConVar("stop_mobs", "1", "  0:standart mobs rush, 1:stop mobs rush if spawn tank");
	stop_specials = CreateConVar("stop_specials", "1", "  0:standart specials spawn, 1:stop specials spawn if spawn tank");
	stop_panic_event = CreateConVar("stop_panic_event", "1", "  0:stop panic event, 1:star panic event if start event");
	
	flag_stop = GetCommandFlags("director_stop");
	SetCommandFlags("director_stop", flag_stop & ~FCVAR_CHEAT);
	
	flag_start = GetCommandFlags("director_start");
	SetCommandFlags("director_start", flag_start & ~FCVAR_CHEAT);
	
	flag_mob = GetCommandFlags("director_no_mobs");
	SetCommandFlags("director_no_mobs", flag_mob & ~FCVAR_CHEAT);
	
	flag_specials = GetCommandFlags("director_no_specials");
	SetCommandFlags("director_no_specials", flag_specials & ~FCVAR_CHEAT);
	
	HookConVarChange(stop_mobsrush_enable, ConVarChange);
	HookConVarChange(stop_mobs, ConVarChange);
	HookConVarChange(stop_specials, ConVarChange);
	
	stop_ais_enabled = FindConVar("l4d_ais_enabled");
}
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarBool(stop_mobsrush_enable))
	{
		if (TankSpawnCount > 0)
		{
			if(GetConVarBool(stop_mobs))
			{
				ServerCommand("director_stop");
				ServerCommand("director_no_mobs 1");
				ServerCommand("director_no_specials 0");
			}
			else
			{
				ServerCommand("director_start");
				ServerCommand("director_no_specials 1");
			}
			if(GetConVarBool(stop_specials))
			{
				ServerCommand("director_no_specials 1");
				if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 0);
			}
			else
			{
				ServerCommand("director_no_specials 0");
				if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
			}
		}
		else
		{
			ServerCommand("director_start");
			if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
		}
	}
	else
	{
		ServerCommand("director_start");
		if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
	}
}
public tank_spawn(Handle:event, const String:name[], bool:Broadcast)
{
	TankSpawnCount++;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	tank_spawn_count[client] = false;
	if (TankSpawnCount > 0)
	{
		if(!GetConVarBool(stop_mobsrush_enable))return;
		if(GetConVarBool(stop_mobs))
		{
			ServerCommand("director_stop");
			ServerCommand("director_no_mobs 1");
			ServerCommand("director_no_specials 0");
		}
		if(GetConVarBool(stop_specials))
		{
			ServerCommand("director_no_specials 1");
			if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 0);
		}
	}
}
public round_start(Handle:event, const String:name[], bool:Broadcast)
{
	TankSpawnCount = 0;
	if(!GetConVarBool(stop_mobsrush_enable))return;
	ServerCommand("director_start");
	if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
}
public round_end(Handle:event, const String:name[], bool:Broadcast)
{
	for (new  i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			if (IsFakeClient(i)) KickClient(i, "");
			else ForcePlayerSuicide(i);
		}
	}
}
public tank_killed(Handle:event, const String:name[], bool:Broadcast)
{
	TankSpawnCount--;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	tank_spawn_count[client] = true;
	if (TankSpawnCount < 1)
	{
		if(!GetConVarBool(stop_mobsrush_enable))return;
		ServerCommand("director_start");
		if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
	}
}
public OnClientDisconnect(client)
{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (class != 5) return;
	else if (tank_spawn_count[client] == false)
	{
		TankSpawnCount--;
		if (TankSpawnCount < 1)
		{
			if(!GetConVarBool(stop_mobsrush_enable))return;
			ServerCommand("director_start");
			if (stop_ais_enabled != INVALID_HANDLE) SetConVarInt(FindConVar("l4d_ais_enabled"), 1);
		}
	}
}
public PanicEvent(Handle:event, const String:name[], bool:Broadcast)
{
	if(!GetConVarBool(stop_mobsrush_enable) || !GetConVarBool(stop_panic_event))return;
	if (TankSpawnCount > 0)
	{
		ServerCommand("director_start");
		ServerCommand("director_no_specials 1");
	}
}
public OnMapStart()
{
	TankSpawnCount = 0;
}
