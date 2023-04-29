#include <sourcemod>
#pragma semicolon 1

new Handle:Speed_Enable;
new Handle:Speed_Random;
new Handle:Speed_Survivor;
new Handle:Speed_Smoker;
new Handle:Speed_Boomer;
new Handle:Speed_Hunter;
new Handle:Speed_Witch;
new Handle:Speed_Tank;

public Plugin:myinfo =
{
	name = "Speed Controller",
	author = "Figa",
	description = "Change forward speed",
	version = "1.2",
	url = "http://fiksiki.3dn.ru"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("witch_spawn", Event_WitchSpawn);
	
	Speed_Enable = CreateConVar("l4d_speed_enable", "1", "Enable Speed Controller Plugin. 0:disable, 1:enable", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Random = CreateConVar("l4d_speed_random", "2", "Enable Random Speed. 0:disable, 1:enable for All, 2:enable custom setting", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	Speed_Survivor = CreateConVar("l4d_speed_survivor", "1.0", "Speed Survivor. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Smoker = CreateConVar("l4d_speed_smoker", "1.0", "Speed Smoker. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Boomer = CreateConVar("l4d_speed_boomer", "1.0", "Speed Boomer. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Hunter = CreateConVar("l4d_speed_hunter", "1.0", "Speed Hunter. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Witch = CreateConVar("l4d_speed_witch", "1.0", "Speed Witch. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Speed_Tank = CreateConVar("l4d_speed_tank", "1.0", "Speed Tank. 0:stop, 1.0:default speed, 1.5: x1.5 speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(Speed_Survivor, ConVarSpeedChange);
	HookConVarChange(Speed_Smoker, ConVarSpeedChange);
	HookConVarChange(Speed_Boomer, ConVarSpeedChange);
	HookConVarChange(Speed_Hunter, ConVarSpeedChange);
	HookConVarChange(Speed_Witch, ConVarSpeedChange);
	HookConVarChange(Speed_Tank, ConVarSpeedChange);
	
	HookConVarChange(Speed_Enable, ConVarSpeedChange);
	HookConVarChange(Speed_Random, ConVarSpeedChange);
	
	AutoExecConfig(true, "l4d_speed_controller");
}
public Event_PlayerSpawn(Handle:event, const String:name[] , bool: dontBroadcast)
{
	if (GetConVarBool(Speed_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		SetSpeedTeam(client, false);
	}
}
public Event_WitchSpawn(Handle:event, const String:name[] , bool: dontBroadcast)
{
	if (GetConVarBool(Speed_Enable))
	{
		new witchid = GetEventInt(event,"witchid");
		SetSpeedTeam(witchid, true);
	}
}
SetSpeedTeam(client, bool isWitch = false)
{
	if (GetConVarInt(Speed_Random) == 1) 
	{
		if (isWitch) SetWitchSpeed(client, GetRandomFloat(0.8, 1.2));
		else SetClientSpeed(client, GetRandomFloat(0.8, 1.2));
	}
	else if (GetConVarInt(Speed_Random) == 0)
	{
		if (isWitch) SetWitchSpeed(client, GetConVarFloat(Speed_Witch));
		else
		{
			new team = GetClientTeam(client);
			if (team == 2) SetClientSpeed(client, GetConVarFloat(Speed_Survivor));
			else if (team == 3)
			{
				new class = GetEntProp(client, Prop_Send, "m_zombieClass");
				switch (class)
				{
					case 1: SetClientSpeed(client, GetConVarFloat(Speed_Smoker));
					case 2:	SetClientSpeed(client, GetConVarFloat(Speed_Boomer));
					case 3:	SetClientSpeed(client, GetConVarFloat(Speed_Hunter));
					//case 4: SetClientSpeed(client, GetConVarFloat(Speed_Witch));
					case 5:	SetClientSpeed(client, GetConVarFloat(Speed_Tank));
				}
			}
		}
	}
	else if (GetConVarInt(Speed_Random) == 2)
	{
		//Custom setting random speed
		if (isWitch) SetWitchSpeed(client, GetRandomFloat(0.8, 1.2));
		else
		{
			new team = GetClientTeam(client);
			if (team == 2) SetClientSpeed(client, GetRandomFloat(0.8, 1.2));	//Survivors
			else if (team == 3)
			{
				new class = GetEntProp(client, Prop_Send, "m_zombieClass");
				switch (class)
				{
					case 1: SetClientSpeed(client, GetRandomFloat(0.8, 1.2));	//Smoker
					case 2:	SetClientSpeed(client, GetRandomFloat(0.8, 1.2));	//Boomer
					case 3:	SetClientSpeed(client, GetRandomFloat(0.8, 1.0));	//Hunter
					//case 4: SetClientSpeed(client, GetRandomFloat(0.8, 1.2));	//Witch
					case 5:	SetClientSpeed(client, GetRandomFloat(0.8, 1.2));	//Tank
				}
			}
		}
	}
}
SetClientSpeed(client, Float:speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
	return;
}
SetWitchSpeed(witch, Float:speed)
{
	SetEntPropFloat(witch, Prop_Send, "m_flSpeed", speed);
	return;
}
public ConVarSpeedChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetConVarBool(Speed_Enable))
			{
				SetSpeedTeam(i);
			}
			else 
			{
				SetClientSpeed(i, 1.0);
			}
		}
	}
}