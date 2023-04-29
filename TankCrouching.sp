#pragma semicolon 1
#pragma newdecls required
#include <sdkhooks>

public Plugin myinfo = {
	name = "[L4D]Tank Crouch Speed",
	author = "Figa",
	description = "The tank will quickly get out if it gets stuck.",
	version = "1.0",
	url = "http://www.sourcemod.net"
};

bool IsTankCrouch[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("mission_lost", Event_MissionLost);
	HookEvent("map_transition", Event_MissionLost);
	HookEvent("finale_win", Event_MissionLost);
	HookEvent("round_freeze_end", Event_MissionLost);
}
public Action Event_TankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_PostThink, ThinkTank);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageTank);
}
public Action ThinkTank(int client)
{
	/*int flag = GetEntityFlags(client);   
	if(flag & FL_DUCKING)
	{
		PrintToChatAll("Crouch!");
	}
	if (GetEntProp(client, Prop_Send, "m_bDucking", 1))
	{
		PrintToChatAll("Crouch2! m_bDucking");
	}*/
	
	if (!IsTankCrouch[client])
	{
		if (IsDucked(client))
		{
			//PrintToChatAll("Crouch! m_bDucked");
			IsTankCrouch[client] = true;
			//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")) + 0.5);
		}
	}
	else
	{
		if (!IsDucked(client))
		{
			//PrintToChatAll("Step! OFF");
			IsTankCrouch[client] = false;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")) - 0.5);
		}
	}
}
public Action OnTakeDamageTank(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (damagetype == 8 || damagetype == 64 || damagetype == 2056 || damagetype == 268435464) return Plugin_Continue;
	if (IsDucked(client)) return Plugin_Handled;
	return Plugin_Continue;
}
public Action Event_TankKilled(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsClientInGame(client) && IsTankCrouch[client])
	{
		IsTankCrouch[client] = false;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}
public Action Event_MissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsTankCrouch[i])
		{
			IsTankCrouch[i] = false;
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}
public void OnClientDisconnect(int client)
{
	if(IsTankCrouch[client])
	{
		IsTankCrouch[client] = false;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}
stock bool IsDucked(int client)
{
	return bool:GetEntProp(client, Prop_Send, "m_bDucked", 1);
}